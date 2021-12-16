# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [More About Functions](../09/README.md) | [Top](../README.md) |

## 10: WASM and Shared Memory

One of the simplest and most efficient ways to transfer information between a WebAssembly program and its host environment is by means of shared memory.

But before we dive into the details of how this is done, we need to say something about the hype surrounding WebAssembly and memory safety.

### WebAssembly Memory Safety

WebAssembly is often touted as a language that offers complete memory-safety.  Unfortunately, this statement is true only in a naïve sense.

It is true that a WebAssembly program has no access to the memory space outside its own sand-boxed environment; however, to conclude that this then makes a WebAssembly program truly memory-safe is to misunderstand the nature of memory safety.  True memory safety must provide the following three guarantees:

* **Spatial Safety:** Out-of-bounds read/write access is prevented.  This applies both to the entire memory space in general, and to not writing beyond the bounds of a particular data structure.
* **Temporal Safety:** Once designated as "free", memory cannot be surreptitiously used for exploitative purposes
* **Pointer Integrity:** A memory address cannot be fabricated from a non-address value

These guarantees are all met when looking at WebAssembly from the outside, but from within its own memory space however, a WebAssembly program is still vulnerable to the same types of memory issues as other programs.  Simple corruption or even explicitly malicious behaviour is still possible because a WebAssembly program can still:

* Read or write values that are within the bounds of its own linear memory, but outside the bounds of its own data structures. In other words, it could trample on its own data
* Not keep an accurate track of which areas of linear memory are or are not in use
* Construct memory addresses from data that is not intended to represent an address

This means that sensitive data stored within WebAssembly linear memory could still be corrupted or even leaked &mdash; hence the naïvety of the above assertion.[^1]

### Basic Principles of Memory Allocation

Given that the WebAssembly specification is currently in a state of development and expansion, the following restrictions are expected to change.  However, at the time of writing (Nov 2021), the following principles and constraints apply:

1. WebAssembly memory is a linear block of undifferentiated bytes[^2]
1. WebAssembly memory can only be allocated in units known as "pages"
1. The WebAssembly page size is 64Kb[^3]
1. If a WebAssembly program needs to allocate memory, then allocation values range between:
    *  Minimum:  1 page (64Kb)
    *  Maximum:  32767 pages (~2Gb)
1. Once allocated, a WebAssembly memory page cannot be deallocated until that program terminates.
1. Memory allocated by the host environment can be shared with one or more WebAssembly modules.
    * A reference to the host memory must be supplied at the time the WebAssembly module is instantiated
    * If multiple WebAssembly modules need access the same block of memory, this is  possible, but you must use the compiler option `--enable-threads`
1. Memory allocated by the WebAssembly module can be shared with host environment, but only if it has been explicitly exported
1. You, the developer, are responsible for keeping track of what data lives at which location within linear memory.  How you choose to do this is entirely up to you, but as mentioned in the section above on memory safety, you must take care of ensuring that:
    * `store` and `load` instructions remain within the bounds of your data structures
    * Unused areas of memory remain truly unused
    * Data not intended to represent a memory address is not used as a memory address

### Allocating Memory in the Host Environment

When allocating WebAssembly memory, at the very least, you must specify the initial number of pages to be allocated.  In JavaScript, you would write:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })
```

This simply says "*Allocate me one, 64Kb memory page*"

The object passed to the `WebAssembly.Memory()` function has two further properties: `maximum` and `shared`.  If we need to allocate up to 20 memory pages that will be shared by multiple WebAssembly instances, then the memory allocation object would look like this:

```javascript
{
  initial : 1,
  maximum : 20,
  shared : true,
}
```

> ***IMPORTANT***
> If the `shared` flag is set to `true`, then the `maximum` value must be explicitly specified, even if it is the same as the `initial` value.
> Also, the WebAssembly module must be compiled with option `--enable-threads`

### Sharing the Host Environment with WebAssembly

Any resources in the host environment that need to be shared with WebAssembly must be made available at the time the WebAssembly module is instantiated.  This amounts to little more than placing these resources into an arbitrary object.

In addition to sharing memory, another common requirement is for the host environment to share "OS level" functionality or language libraries with WebAssembly.

> ***IMPORTANT***
> The term "OS level" has been deliberately placed in quotation marks to indicate the fact that such functionality might not be derived from the machine's actual operating system.
>
> As far as WebAssembly is concerned, it needs access to functionality that lies outside the borders of its own little world.  Therefore such functionality must be supplied by the host environment in response to WebAssembly `import` statements.  Beyond this, it's of little importance to WebAssembly whether that functionality came from the language runtime or from the actual operating system.

In this example, we will write some JavaScript code that makes three resources available to a WebAssembly module called `some_module.wasm`:
1. One page of shared memory
2. The JavaScript `Math` library[^4]
3. A variable containing the offset in shared memory at which WebAssembly should start writing its data

So, first we allocate one page of WebAssembly memory:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })
```

Next, we create an object whose structure represents a two-level namespace:

```javascript
const hostEnv = {
  "math" : Math,
  "js" : {
    "shared_mem"  : wasmMemory,
    "data_offset" : 0,
  }
}
```

Other than representing a two-level namespace, you are free to give this object any property names you like.  Whatever you choose however, try always to ensure that the names are self-documenting.

* `hostEnv.math` points to JavaScript's entire mathematics library.  So WebAssembly now has access to functions such as `sin`, `cos` or `ln`
* `hostEnv.js.shared_mem` points to the host environment's block of linear memory.  Both JavaScript and WebAssembly have full read/write access to this memory
* `hostEnv.js.data_offset` identifies the offset within shared memory at which  WebAssembly will start to write its response data

Now all we need to do is pass this object to WebAssembly at the time we instantiate the module.  This coding assumes that:

* The WebAssembly module being instantiated is called `some_module.wasm` and lives in the same directory as the currently executing JavaScript file
* Once the WebAssembly module has been instantiated, we will call a function called `expensive_calc` that takes two `i32` values as arguments
* Function `expensive_calc` returns an `i32` value that indicates the number of bytes it wrote to shared memory

At this point, it is worth providing two versions of the code because there is a slight difference between running this code in NodeJS and running it in a browser.

#### Running in NodeJS
NodeJS reads the `.wasm` file synchronously from the filesystem using the imported function `readFileSync`

```javascript
import { readFileSync } from 'fs'

const wasmMemory = new WebAssembly.Memory({ initial : 1 })

const hostEnv = {
  "math" : Math,
  "js" : {
    "shared_mem"  : wasmMemory,
    "data_offset" : 0,
  }
}

const wasmBytes = readFileSync('./some_module.wasm')
const wasmObj   = await WebAssembly.instantiate(wasmBytes, hostEnv)

// Call the exported WebAssembly function passing in some meaningless numbers
const bytesWritten = wasmObj.instance.exports.expensive_calc(12,34)
```

#### Running in a Browser

A browser reads the `.wasm` file asynchronously from the Web server using `fetch`

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })

const hostEnv = {
  "math" : Math,
  "js" : {
    "shared_mem"  : wasmMemory,
    "data_offset" : 0,
  }
}

const wasmBytes = await fetch('./some_module.wasm')
const wasmObj   = await WebAssembly.instantiate(wasmBytes, hostEnv)

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

  (import "js" "shared_mem" (memory 1))

  (global $data_offset (import "js" "data_offset") i32)
)
```

Three different types of declaration are made here:

1. The JavaScript `Math.sin`, `Math.cos` and `Math.log` functions are identified using the two-level namespace system.
1. These imported functions are given the names `$sin`, `$cos` and `$log` respectively and declared to be functions that each accept one `f64` as input and give back a single `f64`.
1. The host environment's block of shared memory is imported from the object identified by `js.shared_memory`.
1. Finally, we declare a global constant called `$data_offset` whose value is picked up by importing the `i32` in `js.data_offset`

### Writing to Shared Memory in WebAssembly

A WebAssembly instruction obtains it arguments by popping the required number of values off the stack.  The instruction to write a 4-byte `i32` value to memory is `i32.store` and requires two arguments:
* An `i32` holding the address
* An `i32` holding the value that will be stored at the specified address

Therefore, prior to issuing the `i32.store` instruction, we must ensure that its arguments have already been pushed onto the stack.

In our case, the actual implementation of our fictional `expensive_calc` function is of no importance, other than the fact that at some point in its execution, it will update shared memory, and return an `i32` holding the number of bytes it has written.

So to start with, we refer to the imported value `js.data_offset` in order to know where in memory we should start to write data.  This value has been imported into our WebAssembly module and stored as a module-wide global with the name `$data_offset`

```wast
(global $data_offset (import "js" "data_offset") i32)
```

Here's a minimal and unoptimized loop that performs some expensive but undescribed task many times.  Each time around the loop we:
* Keep a loop counter in local variable `$idx`
* Call another WebAssembly function called `$some_func` that performs an expensive calculation with arguments `$x` and `$y`
* The result of calling `$some_func` is stored in the local variable `$next_val`
* The memory offset at which we store `$next_val` is calculated by multiplying `$idx` by 4 (because each `i32` value is 4 bytes long) then adding this to the base address stored in `$data_offset`
* The multiply by 4 could have been written as:

   `(i32.mul (local.get $idx) (i32.const 4))`

    But because `$idx` is an unsigned integer, multiplying by 4 can be implemented by using the much faster bit-shift left instruction, and shifting by 2 places:

   `(i32.shl (local.get $idx) (i32.const 2))`

```wast
(global $data_offset (import "js" "data_offset") i32)

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
      (call $some_func (local.get $x) (local.get $y))
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

From the JavaScript perspective, the only code we have executed so far is this:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })

const hostEnv = {
  "math" : Math,
  "js" : {
    "shared_mem"  : wasmMemory,
    "data_offset" : 0,
  }
}

const wasmBytes = await fetch('./some_module.wasm')
const wasmObj   = await WebAssembly.instantiate(wasmBytes, hostEnv)

// Call the exported WebAssembly function passing in some meaningless numbers
const bytesWritten = wasmObj.instance.exports.expensive_calc(12,34)
```

After the call to `expensive_calc` has completed, we have an updated `wasmMemory` object, and the number of updated bytes in the constant `bytesWritten`

We now need to get this data out of `wasmMemory`.

The easiest way to do this is to create an array of unsigned, 8-bit bytes and overlay it on top of the WebAssembly linear memory object.

```javascript
const wasmMemBuff = new Uint8ClampedArray(wasmMemory.buffer)
```

We can now read the `wasmMemBuff` array just like any other JavaScript array.  The only thing to bear in mind is that we must start reading from the offset we supplied to WebAssembly in the variable `hostEnv.js.data_offset`, then read for a length of `bytesWritten` bytes:

```javascript
const wasmData = wasmMemBuff.slice(hostEnv.js.data_offset, bytesWritten)
```

Simples!

<hr>

[^1]: See the paper ["*Progressive Memory Safety for WebAssembly*"](https://cseweb.ucsd.edu/~dstefan/pubs/disselkoen:2019:ms-wasm.pdf) for more details
[^2]: In other languages, such a block of memory is known as a "heap"
[^3]: The WebAssembly Community Group has an ongoing proposal to make the page size variable based on the application’s needs.  This would allow WASM modules to run on small, low-power embedded devices that have as little as 32Kb of memory.
[^4]: Sharing the `Math` library is often needed because WebAssembly lacks any instructions to perform numerical operations more advanced than square root.
