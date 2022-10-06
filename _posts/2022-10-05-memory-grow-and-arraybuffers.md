---
layout: post
title:  "WebAssembly Memory Growth and the Detached ArrayBuffer Problem"
date:   2022-10-05 12:00:00 +0000
category: chriswhealy
author: Chris Whealy
excerpt: When JavaScript acts as the host environment for WebAssembly, shared memory is visible to JavaScript as an ArrayBuffer.  WebAssembly memory is allowed to grow, but JavaScript ArrayBuffers are not; so what happens when your Rust program (compiled to WebAssembly) asks for more memory?
---

## Context

* A WebAssembly module and its host environment can share a block of linear memory.
* If JavaScript acts as the host environment, then shared memory appears as a JavaScript [`ArrayBuffer`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer).
* JavaScript cannot directly manipulate the contents of an `ArrayBuffer`.
   Instead, it must use some sort of overlay or mask such as a `Uint8Array` or a `Uint32Array`.
   Then the data in the `ArrayBuffer` can be accessed using the overlaid structure's semantics.

## Problem Summary

A collision between these two facts creates the "Detached ArrayBuffer" problem:

* JavaScript `ArrayBuffer`s are of fixed-length and once allocated, cannot be extended.
* WebAssembly linear memory can be extended by calling [`memory.grow`](https://webassembly.github.io/spec/core/syntax/instructions.html#syntax-instr-memory).

If WebAssembly memory grows,[^1] then the old JavaScript `ArrayBuffer` must be thrown away and a new one created.
Consequently, any JavaScript objects that used to overlay the old `ArrayBuffer` are immediately invalidated because they now point to nothing.
The floor has literally been pulled out from underneath these objects and they must all be redefined over top of the new `ArrayBuffer`.

There is a [proposal](https://www.proposals.es/proposals/Resizable%20and%20growable%20ArrayBuffers) to allow a JavaScript `ArrayBuffer` to grow, and as soon as this functionality appears, this problem will disappear.

Meanwhile, back in Gotham City...
## What Consequences Do These Facts Create When Writing In Rust?

When writing a Rust program that you intend to distribute as a WebAssembly module, `cargo` knows that memory growth might be required; therefore, it builds the necessary functions into the WebAssembly module for calling `memory.grow`.
Should it be necessary, memory growth will now happen automatically (and silently!)

The consequences for JavaScript are that its shared memory `ArrayBuffer` now points to a completely new block of memory and all the overlay objects that gave access to the "pre-growth" shared memory are no longer usable (I.E. they are said to have become "detached").

If you then attempt to access shared memory using one of these "pre-growth" objects, you will see an error such as this:

```
TypeError: Cannot perform %TypedArray%.prototype.slice on a detached ArrayBuffer
```

> ### Aside
>
> Before you can compile a Rust program to WebAssembly, you must first install the `wasm32` compilation target:
>
> ```bash
> rustup target add wasm32-unknown-unknown
> ```

## Local Execution

The following trivial application demonstrates this problem.

A WebAssembly program shares a block of memory with its host for the pourposes of data exchange.
The host writes data to known locations in memory, then the WebAssembly program processes it and writes its response back at another known location.

> ### Source Code
>
> All the source code referenced by this blog can be found in the Github repository [`detached_arraybuffer`](https://github.com/ChrisWhealy/detached_arraybuffer).
>
> If you wish to run these tests locally, first clone this repo:
>
> ```bash
> git clone git@github.com:ChrisWhealy/detached_arraybuffer.git
> ```

### First, Generate the WebAssembly Module

Testing can be performed using different versions of the Wasm module.  One version will work because it does not perform memory growth, and the other will break because it does:

1. Compile a [working version](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/memoryguest.wat) from source code written in WebAssembly Text.

   This version works simply because the WebAssembly Text source code was hand-written, and no such calls to `memory.grow` were implemented.  To use this version, run

   ```
   wat2wasm memoryguest.wat
   ```
1. Compile a [broken version](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/src/lib_growth.rs) from source code written in Rust

   To use this version:

   * Rename `./src/lib_growth.rs` to `./src/lib.rs`
   * Run `cargo build --target=wasm32-unknown-unknown`
1. Compile a [working version](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/src/lib_no_growth.rs) from source code written in Rust that explicitly avoids the need for memory growth

   To use this version:

   * Rename `./src/lib_no_growth.rs` to `./src/lib.rs`
   * Run `cargo build --target=wasm32-unknown-unknown`

### Test The Wasm Module By Calling It From JavaScript

The effects of WebAssembly memory growth on JavaScript's shared memory `ArrayBuffer` can be demonstrated as follows:

1. In both [`server.js`](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/server.js) and [`client.js`](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/client.js), ensure that the variable `wasmFilePath` points to the particular Wasm module you wish to test.
1. To test the Wasm module server side, run

   ```bash
   node server.js
   ```
1. To test the Wasm module in a browser:

   * Start a temporary Web Server

      ```bash
      python3 -m http.server 8080
      ```
   * Point your browser to <http://localhost:8080>
   * Open the developer console

When the test succeeds, the console will display

```
Ahoy there, Testy McTestface!
```

When the test fails, the console will show the Type Error shown above.

## Implementation

The map of shared memory looks like this:

| Offset | Contains | Offset returned by Wasm function
|--:|---|---
| 0 | Salutation | `get_salutation_ptr`
| 16 | Name | `get_name_ptr`
| 32 | Formatted greeting | `get_msg_ptr`

The JavaScript program must first obtain the values of the memory locations shown above.
Once it has these, it writes the appropriate strings to those locations.

Next, it calls the Wasm function `set_name` which does the following:

* Combines the salutation and name into a greeting
* Writes that greeting to another known memory location
* Returns the length of the formatted greeting

Finally, the JavaScript program reads the greeting from shared memory and writes it to the console.

## But What Caused Memory Growth?

Look at the Rust coding in [./src/lib_growth.rs](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/src/lib_growth.rs).
Within function `set_name`, the `format!()` macro is used to assemble the result, which is then stored in an intermediate `String` called `greeting`.

```rust
#[no_mangle]
pub unsafe extern "C" fn set_name(sal_len: i32, name_len: i32) -> i32 {
    let sal: &str = str_from_buffer(SALUT_OFFSET, sal_len as usize);
    let name: &str = str_from_buffer(NAME_OFFSET, name_len as usize);

    let greeting: String = format!("{}, {}!", sal, name);
// snip...
```

Well that looks harmless enough...

However, the declaration of the new `String` requires more memory than is currently available; so, using the extra functions generated by `cargo`, shared memory is automatically and silently extended.

As far as Rust (WebAssembly) is concerned, everything is fine; however, the JavaScript host environment sees that shared memory has changed size, so it throws away the old `ArrayBuffer` and helpfully creates you a new one.

And now all your "pre-growth" JavaScript references into WebAssembly's shared memory are broken...

## Calling The Broken Code From JavaScript

Look at [./server.js](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/server.js) to see the full context of this coding.

```javascript
const salutation = "Ahoy there"
const name = "Testy McTestface"

// Treat shared memory as an array of unsigned bytes
const mem8 = new Uint8Array(wasmExports.memory.buffer)

// Fetch long-lived pointers
const sal_ptr = wasmExports.get_salutation_ptr()
const name_ptr = wasmExports.get_name_ptr()
const msg_ptr = wasmExports.get_msg_ptr()

// Store salutation and name at the expected locations
mem8.set(stringToAsciiArray(salutation), sal_ptr)
mem8.set(stringToAsciiArray(name), name_ptr)

// Tell Wasm to write the formatted greeting to the known memory location then return its length
let msg_len = wasmExports.set_name(salutation.length, name.length)

// Read greeting from shared memory
let msg_text = asciiArrayToString(mem8.slice(msg_ptr, msg_ptr + msg_len))
//                                ^^^^^^^^^^ mem8 will point to nothing if memory growth occurs!

console.log(msg_text)
```

So let's run this.

If you're using the working WebAssembly module, you'll see:

```bash
$ node server.js
Ahoy there, Testy McTestface!
```

and if you're using the WebAssembly module that breaks JavaScript's shared memory references, you'll see:

```bash
$ node server.js
/Users/chris/Developer/WebAssembly/detached_arraybuffer/server.js:60
    let msg_text = asciiArrayToString(mem8.slice(msg_ptr, msg_ptr + msg_len))
                                           ^

TypeError: Cannot perform %TypedArray%.prototype.slice on a detached ArrayBuffer
    at Uint8Array.slice (<anonymous>)
    at /Users/chris/Developer/WebAssembly/detached_arraybuffer/server.js:60:44
```

# Two Solutions

Until JavaScript's `ArrayBuffer` is able to perform in-place growth, we must adopt one of two possible approaches to solving this problem.
Either:

1. We monitor the size of the WebAssembly memory looking for growth; or
1. We adjust the Rust coding so that memory growth does not occur.

## 1. A JavaScript Workaround

If it's going to change, WebAssembly memory will only every increase in size.
So a simple way to workaround this problem is to monitor the size of the WebAssembly's memory.

If it gets bigger, then you know you need to redefine any shared memory overlay objects.

> This is just a workaround; it does not change the underlying problem.
>
> Anyone else calling the same WebAssembly function will need to implement the same workaround.

The code does not require much modification to avoid using a possibly detached `ArrayBuffer`:

```javascript
const salutation = "Ahoy there"
const name = "Testy McTestface"

// Keep track of Wasm's shared memory size
let memLength = wasmExports.memory.buffer.byteLength

// Snip

// Tell Wasm to write the formatted greeting to the known memory location then return its length
let msg_len = wasmExports.set_name(salutation.length, name.length)

// Before allowing shared memory access, check if memory growth has occurred
if (wasmExports.memory.buffer.byteLength > memLength) {
  memLength = wasmExports.memory.buffer.byteLength
  mem8 = new Uint8Array(wasmExports.memory.buffer)
}

// Read greeting from shared memory
let msg_text = asciiArrayToString(mem8.slice(msg_ptr, msg_ptr + msg_len))

console.log(msg_text)
```

Now everything works because we're on the lookout for memory growth and then "reattach" the `mem8` array to the new shared memory `ArrayBuffer`.

## 2. Solve the Problem in Rust

However, to avoid causing inadvertent memory growth, the Rust coding needs to avoid invoking any instructions that might require extra memory.
In this case, it means that instead of using an intermediate `String` object, we write the bytes of the character strings directly to the `[u8]` buffer.

The full solution can be seen in [./src/lib_no_growth.rs](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/src/lib_no_growth.rs), but the important change is shown below:

```rust
pub unsafe extern "C" fn set_name(sal_len: i32, name_len: i32) -> i32 {
    let mut idx: usize;

    // Write salutation directly to the buffer
    copy_bytes(MSG_OFFSET, SALUT_OFFSET, sal_len);
    idx = MSG_OFFSET + sal_len as usize;

    // Write separator ", "
    BUFFER[idx] = COMMA;
    idx += 1;
    BUFFER[idx] = SPACE;
    idx += 1;

    // Write name
    copy_bytes(idx, NAME_OFFSET, name_len);
    idx += name_len as usize;

    // Write bang character
    BUFFER[idx] = BANG;
    idx += 1;

    (idx - MSG_OFFSET) as i32
}
```

[^1]: memory growth could be invoked either from WebAssembly or the host environment
