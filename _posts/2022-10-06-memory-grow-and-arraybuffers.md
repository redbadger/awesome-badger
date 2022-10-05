---
layout: post
title:  "WebAssembly Memory Growth and the Detached ArrayBuffer Problem"
date:   2022-10-06 12:00:00 +0000
category: chriswhealy
author: Chris Whealy
excerpt: When JavaScript acts as the host environment for WebAssembly, shared memory is visible to JavaScript as an ArrayBuffer.  WebAssembly memory is allowed to grow, but JavaScript ArrayBuffers are not; so what happens when your Rust program (compiled to WebAssembly) asks for more memory?
---

## Source Code

All the source code referenced by this blog can be found in the Github repository [`detached_arraybuffer`](https://github.com/ChrisWhealy/detached_arraybuffer).

If you wish to run these tests locally, first clone this repo:

```bash
git clone git@github.com:ChrisWhealy/detached_arraybuffer.git
```

## Summary

* WebAssembly and its host environment can share a block of linear memory.
* If JavaScript is the host environment, then shared memory is available as an [`ArrayBuffer`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer).
* JavaScript cannot directly access the contents of an `ArrayBuffer`.
   Instead, it must use a structure such as a `Uint8Array` or a `Uint32Array` as an overlay or mask, then access the `ArrayBuffer` via the overlaid structure's semantics.
* JavaScript `ArrayBuffer`s are of fixed-length and once allocated, cannot be extended.
* WebAssembly linear memory can be extended by calling [`memory.grow`](https://webassembly.github.io/spec/core/syntax/instructions.html#syntax-instr-memory).
* If WebAssembly memory grows, then a new JavaScript `ArrayBuffer` is created and the old one thrown away.
   Consequently, any JavaScript objects that overlaid the old `ArrayBuffer` are immediately invalidated and must be redefined against the new `ArrayBuffer`.

This problem will disappear if a JavaScript `ArrayBuffer` is given the ability to grow.
This functionality is currently at the [proposal stage](https://www.proposals.es/proposals/Resizable%20and%20growable%20ArrayBuffers).

## What Consequences Do These Facts Create When Writing In Rust?

Before you can compile a Rust program to WebAssembly, you must first install the `wasm32` compilation target:

```bash
rustup target add wasm32-unknown-unknown
```

When writing a Rust program that you intend to distribute as a WebAssembly module, `cargo` knows that memory growth might be required; therefore, it builds the necessary functions into the WebAssembly module for calling `memory.grow`.
Should it be necessary, memory growth can now happen automatically (and silently!)

If memory growth occurs,[^1] the host environment still has access to the shared memory `ArrayBuffer`, but that `ArrayBuffer` now points to a completely new block of memory.
Now that the old `ArrayBuffer` has disappeared, the floor has literally been pulled out from underneath all the overlay objects that gave access to the "pre-growth" shared memory (I.E. they are said to have become "detached").

If you then attempt to access shared memory using one of these "pre-growth" objects, you will see an error such as this:

```
TypeError: Cannot perform %TypedArray%.prototype.slice on a detached ArrayBuffer
```

## Local Execution

The following trivial application demonstrates this problem.
A WebAssembly program shares a block of memory in which data can be exchanged with the host environment.
The host writes data to known location in memory, and the WebAssembly program processes this data, and writes its response back at another known location.

### Generate the WebAssembly Module

Testing can be performed using different versions of the Wasm module:

1. A [working version](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/memoryguest.wat) from source code written in WebAssembly Text

   To use this version, run `wat2wasm memoryguest.wat`
1. A [broken version](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/src/lib_growth.rs) from source code written in Rust

   To use this version:

   * Rename `./src/lib_growth.rs` to `./src/lib.rs`
   * Run `cargo build --target=wasm32-unknown-unknown`
1. A [working version](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/src/lib_no_growth.rs) from source code written in Rust

   To use this version:

   * Rename `./src/lib_no_growth.rs` to `./src/lib.rs`
   * Run `cargo build --target=wasm32-unknown-unknown`

### Run the JavaScript Tests

The effects of WebAssembly memory growth on the `ArrayBuffer` used by JavaScript can be demonstrated  as follows:

1. In both `server.js` and `client.js`, ensure that the variable `wasmFilePath` points to the particular Wasm module you wish to test.
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

The memory map looks like this:

| Offset | Value | Discovered by calling Wasm function
|--:|---|---
| 0 | Salutation | `get_salutation_ptr`
| 16 | Name | `get_name_ptr`
| 32 | Formatted greeting | `get_msg_ptr`

Irrespective of the source language from which the Wasm module was generated, the JavaScript program must first obtain the values of the memory locations shown above, then it writes strings to those locations.

Next, it calls the Wasm function `set_name` that combines the salutation and name into a greeting, then writes that greeting to another known memory location.
`set_name` then returns the length of the formatted greeting.

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
The JavaScript host environment then sees that this has happened and dutifully throws away the old `ArrayBuffer` and creates a new one.

And now all your existing JavaScript references into WebAssembly's shared memory are broken...

## Calling The Broken Code From JavaScript

Look at [./server.js](https://github.com/ChrisWhealy/detached_arraybuffer/blob/master/server.js) to see the full context of this coding.

```javascript
const salutation = "Ahoy there"
const name = "Testy McTestface"

// Look at shared memory as an array of unsigned bytes
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
//                                ^^^^^^^^^^ mem8 will point to nothing after memory growth!

console.log(msg_text)
```

So let's run this.
Depending on which WebAssembly module you're using, you'll either see:

```bash
$ node server.js
Ahoy there, Testy McTestface!
```

or

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

We can take one of two possible approaches to solving this problem.
Either:

1. We accept the fact that WebAssembly memory growth breaks the corresponding JavaScript `ArrayBuffer` and just code around it, or
1. We adjust the Rust coding so that memory growth does not occur.

## 1. A JavaScript Workaround

A simple way to workaround this problem is to create a new version of the `mem8` array immediately after memory growth has occurred (I.E. after calling `set_name`).

However, this is just a workaround; it does not solve the underlying problem.
Anyone else calling the same WebAssembly function will need to implement the same workaround.

```javascript
// Snip...
let mem8 = new Uint8Array(wasmExports.memory.buffer)

// Snip...
let msg_len = wasmExports.set_name(salutation.length, name.length)
// Add this line in here
mem8 = new Uint8Array(wasmExports.memory.buffer)

let msg_text = asciiArrayToString(mem8.slice(msg_ptr, msg_ptr + msg_len))

console.log(msg_text)
```

Now everything works because the `mem8` array has been "reattached" to the new shared memory `ArrayBuffer`.

## 2. Solve the Problem in Rust

To solve the problem, the Rust coding needs to avoid invoking any instructions that cause memory growth.
In this case, it means that instead of using an intermediate `String` object, we write each byte of the character strings directly to the `[u8]` buffer.

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

[^1]: This functionality could be invoked either from WebAssembly or the host environment
