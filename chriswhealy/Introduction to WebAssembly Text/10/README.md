# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [More About Functions](../09/) | [Up](/chriswhealy/introduction-to-web-assembly-text) |

## 10: WASM and Shared Memory

One of the simplest and most efficient ways to transfer information between a WebAssembly program and its host environment is by means of shared memory.

But before we dive into the details of how this is done, we need to say something about the hype surrounding WebAssembly and memory safety.

### WebAssembly Memory Safety

WebAssembly is often touted as a language that offers complete memory-safety.  Unfortunately, this statement is true only in a naïve sense.

It is true that a WebAssembly program has no access to the memory space outside its own sand-boxed environment; however, to conclude that this then makes a WebAssembly program truly memory-safe is to misunderstand the nature of memory safety.

True memory safety must provide the following three guarantees:

* **Spatial Safety:**

   Out-of-bounds read/write access is prevented.  This prevention must apply not only at the large scale of writing beyond the bounds of the entire memory space, but also at the small scale of writing beyond the bounds of a particular data structure within the memory space.

* **Temporal Safety:**

   Once designated as "free", memory cannot be surreptitiously used for exploitative purposes

* **Pointer Integrity:**

   A memory address cannot be fabricated from a non-address value

These guarantees are all met when looking at WebAssembly from outside the scope of a module, but from within its own execution scope, a WebAssembly program is still vulnerable to the same memory issues as other programs.  Simple corruption or even explicitly malicious behaviour is still possible because a WebAssembly program can:

* Read or write values that are within the bounds of its own linear memory, but outside the bounds of its defined data structures. In other words, by not accurately keeping track of the length of a data structure, you could easily end up trampling on your own data
* Fail to keep an accurate track of which areas of linear memory are or are not in use
* Construct memory addresses from data that is not intended to represent an address

This means that sensitive data stored within WebAssembly linear memory could still be corrupted or even leaked &mdash; hence the naïvety of the above assertion.[^1]

### Basic Principles of Memory Allocation

Given that the WebAssembly specification is currently in a state of development and expansion, the following restrictions are expected to change.  However, at the time of writing (Dec 2021), the following principles and constraints apply:

1. WebAssembly memory is a linear block of undifferentiated bytes[^2]
1. WebAssembly memory can only be allocated in units known as "pages"
1. The WebAssembly page size is fixed at 64Kb[^3]
1. If a WebAssembly program needs to allocate memory, then allocation values range between:
    *  Minimum:  1 page (64Kb)
    *  Maximum:  32767 pages (~2Gb)
1. Over the lifespan of a WebAssembly module, memory growth is monotonic.<br>That is, at runtime, a WebAssembly program can request more memory (up to the maximum defined at instantiation time); but once allocated, those pages cannot be deallocated until the program terminates.
1. Memory allocated by the host environment can be shared with one or more WebAssembly modules.
    * The host environment must allocate some initial block of memory before instantiating the WebAssembly module(s)
    * A reference to the host memory must be supplied at the time the WebAssembly module is instantiated
    * If multiple WebAssembly modules need access the same block of memory, then this is possible, but these modules must be compiled with the compiler option `--enable-threads`
1. Memory allocated by the WebAssembly module can be shared with host environment, but only if it has been explicitly exported
1. You, the developer, are responsible for keeping track of what data lives at which location within linear memory.  How you choose to do this is entirely up to you, but as mentioned in the section above on memory safety, you must take care to ensure that:
    * `store` and `load` instructions always operate within the boundaries of your data structures
    * Unused areas of memory remain truly unused
    * Data not intended to represent a memory address is not used as a memory address

### Sharing Host Environment Memory with WebAssembly

When the host environment allocates memory to be shared with WebAssembly, at the very least, you must specify the initial number of pages to be allocated.  In JavaScript, you would write:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })
```

This simply says "*Allocate me one, 64Kb memory page*"

The object passed to the `WebAssembly.Memory()` function has two further properties: `maximum` and `shared`.  For instance, if we need to allocate up to 20 memory pages that will be shared by multiple WebAssembly instances, then the memory allocation object would look like this:

```javascript
{
  initial : 1,     // Start with one 64Kb page
  maximum : 20,    // Growth is possible up 20 pages
  shared  : true,  // Multiple WebAssembly modules instance will share this linear memory
}
```

***IMPORTANT***

Setting the `shared` flag to `true` has two immediate consequences:

1. `maximum` must be explicitly specified, even if it has the same value as `initial`
1. Any WebAssembly modules sharing this memory must be compiled with the `--enable-threads` option

### Sharing Host Environment Functionality with WebAssembly

By design, WebAssembly has a limited instruction set and no access to "operating system" level functionality.[^4]  Therefore, if a WebAssembly module wants to perform anthing more than CPU-bound computations, access to such resources and functionality must be provided by the host environment at the time the WebAssembly module is instantiated.

In practice, all the host environment needs to do is place references to these resources into an arbitrary object supplied at instantiation time.

In this example, we will write some JavaScript code that makes three resources available to a WebAssembly module called `some_module.wasm`:
1. One page of shared memory (Allocated by JavaScript)
2. The entire JavaScript `Math` library[^5]
3. A variable containing the offset in shared memory at which WebAssembly should start writing its data

So, first we allocate one page of WebAssembly memory:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })
```

Next, we create an object whose structure represents an arbitrary, two-level namespace:

```javascript
const hostEnv = {
  "math" : Math,
  "mem" : {
    "pages" : wasmMemory,
    "data_offset" : 0,
  }
}
```

Other than representing a two-level namespace, you are free to give this object any property names you like.  The only recommendation here is that the names should be as self-documenting as possible.

* `hostEnv.math` points to JavaScript's entire mathematics library.  So WebAssembly now has access to functions such as `sin`, `cos` or `ln`
* `hostEnv.mem.pages` points to the host environment's block of shared, linear memory.  Both JavaScript and WebAssembly have full read/write access to this memory
* `hostEnv.mem.data_offset` identifies the offset within shared memory at which WebAssembly will start writing its response data

<hr>

***IMPORTANT***

Whatever object you create as your `hostEnv` object, it represents a namespace that is limited to a maximum of two levels.  Therefore, since in the above example, we wish to share the entire JavaScript `Math` library, it must be represented at the top level as `hostEnv.math`.  Then within this, WebAssembly will be able to access `hostEnv.math.sin` or `hostEnv.math.cos` etc.

Alternatively, if we only want to expose the basic trigonometric functions, we could have represented them as:

```javascript
const hostEnv = {
  "math" : {
    "sin" : Math.sin,
    "cos" : Math.cos,
    "tan" : Math.tan,
  }
}
```

<hr>

Now all we need to do is pass this object as an argument to `WebAssembly.instantiate()`.  The coding shown below assumes that:

* The WebAssembly module being instantiated is called `some_module.wasm` and lives in the same directory as the currently executing JavaScript file
* Once the WebAssembly module has been instantiated, we will call a function called `expensive_calc` that takes two `i32` values as arguments
* Function `expensive_calc` returns an `i32` value that indicates the number of bytes written to shared memory

At this point, it is worth providing two versions of the code because there is a slight difference between running this code in NodeJS and running it in a browser.

#### Running in NodeJS

NodeJS reads the `.wasm` file synchronously from the filesystem using the imported function `readFileSync`

```javascript
import { readFileSync } from 'fs'

const wasmMemory = new WebAssembly.Memory({ initial : 1 })
const wasmMem8   = new Uint8ClampedArray(wasmMemory.buffer)

const hostEnv = {
  "math" : Math,
  "mem" : {
    "pages" : wasmMemory,
    "data_offset" : 0,
  }
}

const wasmBytes = readFileSync('./some_module.wasm')
const wasmObj   = await WebAssembly.instantiate(wasmBytes, hostEnv)

// Call the exported WebAssembly function passing in some meaningless numbers
const bytesWritten = wasmObj.instance.exports.expensive_calc(12,34)

// We can now read shared memory and pull out the data we're interested in
let interestingStuff = wasmMem8.slice(hostEnv.mem.data_offset, hostEnv.mem.data_offset + bytesWritten)
```

#### Running in a Browser

A browser reads the `.wasm` file asynchronously from the Web server using `fetch`; but other than that, the coding is the same:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })
const wasmMem8   = new Uint8ClampedArray(wasmMemory.buffer)

const hostEnv = {
  "math" : Math,
  "mem" : {
    "pages" : wasmMemory,
    "data_offset" : 0,
  }
}

const wasmObj = await WebAssembly.instantiateStreaming(fetch('./some_module.wasm'), hostEnv)

// Call the exported WebAssembly function passing in some meaningless numbers
const bytesWritten = wasmObj.instance.exports.expensive_calc(12,34)
```

### Using Host Environment Resources in WebAssembly

Instantiating our fictitious WebAssembly module and supplying it with a host environment object is only half the story.  Now we must look at how the WebAssembly module declares its use of these resources by means of `import` statements.

Immediately after the `module` definition, we need to add the following declarations:

```wast
(module
  (import "math" "sin" (func $sin (param f64) (result f64)))
  (import "math" "cos" (func $cos (param f64) (result f64)))
  (import "math" "log" (func $log (param f64) (result f64)))

  (import "mem" "pages" (memory 1))

  (global $data_offset (import "mem" "data_offset") i32)
)
```

Three different types of declaration are made here:

1. The JavaScript `Math.sin`, `Math.cos` and `Math.log` functions are identified using the two-level namespace system.  These imported functions are:
   * Given the internal names `$sin`, `$cos` and `$log`
   * Declared to accept one `f64` as input and give back a single `f64`
1. The host environment's block of shared memory is accessed via the object property `mem.pages`.
1. Finally, we declare a global constant called `$data_offset` whose value is picked up by importing the `i32` in `mem.pages`

### Writing to Shared Memory in WebAssembly

A WebAssembly instruction obtains it arguments by popping the required number of values off the stack.  The instruction to write a 4-byte `i32` value to memory is `i32.store` and requires two arguments:
* An `i32` holding the address in linear memory where we are to start writing
* An `i32` holding the value that will be stored at the specified address

Therefore, prior to issuing the `i32.store` instruction, we must ensure that its arguments have already been pushed onto the stack.

In our case, the actual implementation of our fictional `expensive_calc` function is of no importance, other than the fact that at some point in its execution, it will update shared memory, and return an `i32` holding the number of bytes it has written.

So to start with, we refer to the imported value `mem.data_offset` in order to know where in memory we should start writing.  This value has been imported into our WebAssembly module and stored as a module-wide global with the name `$data_offset`

```wast
(global $data_offset (import "mem" "data_offset") i32)
```

Here's a minimal and unoptimized loop that performs some expensive but undescribed task many times.  Each time around the loop we:
* Keep track of the number of loop iterations in a local variable called `$idx`
* Call another WebAssembly function called `$some_expensive_func` that takes arguments `$x` and `$y`
* The result of calling `$some_expensive_func` is stored in the local variable `$next_val`
* The memory offset at which we store `$next_val` is calculated by multiplying `$idx` by 4 (because each `i32` value is 4 bytes long) then adding this to the base address stored in `$data_offset`
* The instruction to multiply `$idx` by 4 could have been written as:

   `(i32.mul (local.get $idx) (i32.const 4))`

   However, because `$idx` is an unsigned integer, we can optimise this operation using the much faster `i32.shl` ("shift left") instruction, and shifting by 2 binary places:

   `(i32.shl (local.get $idx) (i32.const 2))`

```wast
(global $data_offset (import "mem" "data_offset") i32)

(func (export "expensive_calc")
      (param $x i32)
      (param $y i32)
      (result i32)

  (local $next_val i32)  ;; The value being written to memory
  (local $idx      i32)  ;; Loop counter

  (loop $do_it_again
    (local.set $next_val
      ;; Call some function that performs an expensive calculation on arguments
      ;; $x and $y, then store the result in $next_val
      (call $some_expensive_func (local.get $x) (local.get $y))
    )

    ;; Write contents of $next_val to memory
    (i32.store
      ;; Offset = $data_offset + ($idx * 4)
      (i32.add
        (global.get $data_offset)
        (i32.shl (local.get $idx) (i32.const 2))
      )
      ;; Value = the contents of $next_val
      (local.get $next_val)
    )

    ;; $idx++
    (local.set $idx (i32.add (local.get $idx) (i32.const 1)))

    ;; Decide if the loop should continue
    (if ;; Some sort of loop continuation test...
      (then
        (br $do_it_again)
      )
    )
  )

  ;; We need to return the number of bytes written to memory, so leave this value
  ;; on the stack then exit the function
  (i32.shl (local.get $idx) (i32.const 2))
)
```

### Reading from Shared Memory in JavaScript

So far, our JavaScript code has:

* Created some shared memory
* Passed the shared memory and some other host environment resources a WebAssembly module instance
* Called the `expensive_calc()` function

Now we need to retrieve the data from shared memory, so the final statement show below is added:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })
const wasmMem8   = new Uint8ClampedArray(wasmMemory.buffer)

const hostEnv = {
  "math" : Math,
  "mem" : {
    "pages" : wasmMemory,
    "data_offset" : 0,
  }
}

const wasmBytes = await fetch('./some_module.wasm')
const wasmObj   = await WebAssembly.instantiate(wasmBytes, hostEnv)

// Call the exported WebAssembly function passing in some meaningless numbers
const bytesWritten = wasmObj.instance.exports.expensive_calc(12,34)

// We can now read shared memory and pull out the data we're interested in
let interestingStuff = wasmMem8.slice(hostEnv.mem.data_offset, hostEnv.mem.data_offset + bytesWritten)
```

Notice that after the `wasmMemory` object is created, there is the declaration of an array of unsigned, 8-bit bytes that acts as an overlay on top of the WebAssembly linear memory object.

```javascript
const wasmMemBuff = new Uint8ClampedArray(wasmMemory.buffer)
```

We can now read the `wasmMemBuff` array just like any other JavaScript array.  The only thing to bear in mind is that we must start reading from the offset we supplied to WebAssembly in the variable `hostEnv.mem.data_offset`, then read for a length of `bytesWritten` bytes:

```javascript
let interestingStuff = wasmMem8.slice(hostEnv.mem.data_offset, hostEnv.mem.data_offset + bytesWritten)
```

Simples!

<hr>

[^1]: See the paper ["*Progressive Memory Safety for WebAssembly*"](https://cseweb.ucsd.edu/~dstefan/pubs/disselkoen:2019:ms-wasm.pdf) for more details
[^2]: In other languages, such a block of memory is known as a "heap"
[^3]: The WebAssembly Community Group has an ongoing proposal to make the page size variable based on the application’s needs.  This would allow WASM modules to run on small, low-power embedded devices that have as little as 32Kb of memory.
[^4]: The term "operating system" has been deliberately placed in quotation marks to indicate that such resources and functionality might not be derived from the machine's actual operating system.  As far as WebAssembly is concerned, it simply needs access to things that lie outside the borders of its own little world, and it looks to the host environment to satisfy all the requirements described in its `import` statements.  Beyond this, it's of little importance to WebAssembly whether that functionality came from the language runtime or from the actual operating system.
[^5]: Sharing the `Math` library is often needed because WebAssembly lacks any instructions to perform numerical operations more advanced than square root.
