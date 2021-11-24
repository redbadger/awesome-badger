# Introduction to WebAssembly Text
<table style="table-width: fixed; width: 100%">
<tr><th style="width: 45%">Previous</th>
    <th style="width: 10%"></th>
    <th style="width: 45%">Next</th></tr>
<tr><td style="text-align: center"><a href="./09%20More%20About%20Functions.md">More About Functions</a></td>
    <td style="text-align: center"><a href="./README.md">Top</a></td>
    <td style="text-align: center"></td></tr>
</table>

## 10: WASM and Shared Memory

One of the simplest most efficient ways to transfer information between a WebAssembly program and its host environment is my means of shared memory.

### WebAssembly Memory Safety

WebAssembly is often touted as a memory-safe language.  Unfortunately, this statement is true only in a naïve sense.

It is true that a WebAssembly program has no access to the memory space outside its own sand-boxed environment; however, to conclude that this then makes a WebAssembly program truly memory-safe is to misunderstand the nature of memory safety.  True memory safety must provide the following three guarantees:

* **Spatial Safety:** Out-of-bounds read/write access is prevented
* **Temporal Safety:** Memory designated as "free" cannot be used for exploitative purposes
* **Pointer Integrity:** A memory address cannot be fabricated from a non-address value

Within its own memory space however, a WebAssembly program is still vulnerable to the same types of memory issues as other programs.  Simple corruption or even explicitly malicious behaviour is still possible because a WebAssembly program can still:

* Read or write values that are outside the bounds of its own data structures
* Use areas of linear memory that are otherwise thought to be unused
* Construct memory addresses from from any available data

This means that sensitive data stored within a WebAssembly program's memory space could still be corrupted or even leaked &mdash; hence the naïvety of the above assertion.[^1]

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
    * If multiple WebAssembly modules need access the same block of memory,[^4] this is only possible by means of the compiler option `--enable-threads`
1. Memory allocated by the WebAssembly module can be shared with host environment, but only if it has been explicitly exported

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
> If the `shared` flag is set to `true`, then the `maximum` value must be explicitly specified, even if it is no different from the `initial` value

### Sharing the Host Environment with WebAssembly

Any resources in the host environment that need to be shared with WebAssembly must be made available at the time the WebAssembly module is instantiated.  This amounts to little more than placing these resources into an arbitrary object.

In addition to sharing memory, another common requirement is for the host environment to share its `Math` library with WebAssembly.  This is simply because WebAssembly lacks any instructions to perform numerical operations more advanced than square root.

In this example, we will look at the host environment coding the allocates a single memory and then share both this and its `Math` library with a WebAssembly module called `some_module.wasm`

So, first we allocate one page of WebAssembly memory:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })
```

Next, any host environment resources we wish to make available to WebAssembly are placed an object whose structure must represent a two-layer namespace:

```javascript
const wasmMemory = new WebAssembly.Memory({ initial : 1 })

const hostEnv = {
  "math" : Math,
  "js" : {
    "shared_mem"  : wasmMemory,
    "data_offset" : 0,
  }
}
```

Other than representing a two-layer namespace, you are free to give the object properties any names you like.  Whatever you choose however, always try to ensure that the names are self-documenting.

* `host_env.math` points to JavaScript's entire mathematics library.  So WebAssembly now has access to functions such as `sin`, `cos` or `ln`
* `host_env.js.shared_mem` points to the host environment's block of linear memory.  Both JavaScript and WebAssembly have full read/write access to this memory
* `host_env.js.data_offset` identifies an arbitrary offset within shared memory at which the WebAssembly function `expensive_calc` will start to write is response data

Now all we need to do is pass this object to WebAssembly at the time we instantiate the module `some_module.wasm`.  This coding assumes that:

* The WebAssembly module being instantiated is called `some_module.wasm` and lives in the same directory as the currently executing JavaScript file
* Once the WebAssembly module instantiated, we will call a function called `expensive_calc` that takes two `i32` values are arguments
* Function `expensive_calc` returns an `i32` value that indicates the number of bytes it wrote to shared memory

At this point, it is worth providing two version of the code because there is a slight difference between running this code in NodeJS and running in a browser.

#### Running in NodeJS
NodeJS reads the `.wasm` file synchronously from the filesystem using `readFileSync`

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
const wasmObj = await WebAssembly.instantiate(wasmBytes, hostEnv)

// Call the exported WebAssembly function passing in some meaningless numbers
const bytesWritten = wasmObj.instance.exports.expensive_calc(12,34)
```

Although it is not the case with function `expensive_calc`, remember that currently, NodeJS is **not** able to instantiate WebAssembly modules containing exported functions that return multiple values

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
const wasmObj = await WebAssembly.instantiate(wasmBytes, hostEnv)

// Call the exported WebAssembly function passing in some meaningless numbers
const bytesWritten = wasmObj.instance.exports.expensive_calc(12,34)
```

Although it is not the case with function `expensive_calc`, remember that a browser is able to instantiate WebAssembly modules containing exported functions that return multiple values

### Using Host Environment Resources in WebAssembly

Now that we have instantiated our fictitious WebAssembly module and supplied it with a `host_env` object, the WebAssembly module must declare it's use of these resources my means of `import` statements.

Immediately after the `module` definition, we need to add the following declarations:

```wat
(module
  (import "math" "sin" (func $sin (param f64) (result f64)))
  (import "math" "cos" (func $cos (param f64) (result f64)))
  (import "math" "log" (func $log (param f64) (result f64)))

  (import "js" "shared_mem" (memory 1))

  (global $data_offset (import "js" "data_offset") i32)
)
```

Three different declarations are made here:

1. We need access to the JavaScript functions `Math.sin`, `Math.cos` and `Math.log`.
    Within the WebAssembly module, these functions will be known simply as `$sin`, `$cos` and `$log` respectively and each is declared to be a function that accepts one `f64` as input, and gives back a single `f64`
1. Next, we declare that the object identified as `js.shared_memory` is to be treated as a single page of memory (that is, a 64Kb block of linear memory)
1. Finally, we declare a global constant within the module called `$data_offset` whose value is picked up by importing the `i32` in `js.data_offset`

### Writing to Shared Memory in WebAssembly

In WebAssembly Text, the instruction to write a 4-byte `i32` value to memory is `i32.store`.  This instruction requires two arguments, so it obtains these values by popping the top two values off the stack:
* The first value is an `i32` holding the address
* The second is another `i32` holding the value that will be stored

In our case, the actual implementation of our fictional function `expensive_calc` is of no importance, other than the fact that at some point in its execution, this function will update shared memory, and return an `i32` holding the number of bytes it has written.

To start with, we must start writing our data at the memory offset supplied by the imported value `js.data_offset`.  This value has been imported into our WebAssembly module and stored as a module-wide global with the name `$data_offset`

```wat
(global $data_offset (import "js" "data_offset") i32)
```

Here's a minimal and unoptimized loop that performs some expensive but undescribed task many times inside a loop.

Each time around the loop we:
* Keep a loop counter in local variable `$idx`
* Call the function `$some_func` that performs some expensive calculation with arguments `$x` and `$y` and stores the result in local variable `$next_val`
* The memory offset is calculated by multiplying `$idx` by 4 (because each `i32` value is 4 bytes long) then adding this to the base address stored in `$data_offset`
* The multiply by 4 could have been written as:
     `(i32.mul (local.get $idx) (i32.const 4))`
     But because `$idx` is an unsigned integer, it is much cheaper to perform a bit-shift left by 2 places:
     `(i32.shl (local.get $idx) (i32.const 2))`

```wat
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
        (global.get $mem_offset)
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
    
  ;; The number of bytes we've written to memory becomes the function's return
  ;; value, so leave this value on the stack then exit the function
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
const wasmObj = await WebAssembly.instantiate(wasmBytes, hostEnv)

// Call the exported WebAssembly function passing in some meaningless numbers
const bytesWritten = wasmObj.instance.exports.expensive_calc(12,34)
```

This means after the call to `expensive_calc` has completed, we have an updated `wasmMemory` object an the number of updated bytes in `bytesWritten`

We now need to get this data out of `wasmMemory`.

The easiest way to do this is to create an array of unsigned, 8-bit bytes and overlay it on top of the WebAssembly linear memory object.

```javascript
const wasmMemBuff = new Uint8ClampedArray(wasmMemory.buffer)
```

We now read the first `bytesWritten` bytes from this array and we have obtained the data calculated by WebAssembly

Simples!


[^1]: See the paper ["*Progressive Memory Safety for WebAssembly*"](https://cseweb.ucsd.edu/~dstefan/pubs/disselkoen:2019:ms-wasm.pdf) for more details
[^2]: In other languages, such a block of memory is known as a "heap"
[^3]: The WebAssembly Community Group has an ongoing proposal to make the page size variable based on the application’s needs.  This would allow WASM modules to run on small, low-power embedded devices that have as little as 32Kb of memory.
[^4]: Typically, where the host environment creates multiple instances of the same WebAssembly module, and each instance acts on the same block of memory