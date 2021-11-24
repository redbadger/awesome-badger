# Introduction to WebAssembly Text
<table style="table-width: fixed; width: 100%">
<tr><th style="width: 45%">Previous</th>
    <th style="width: 10%"></th>
    <th style="width: 45%">Next</th></tr>
<tr><td style="text-align: center"><a href="./01%20Benefits%20of%20WebAssembly.md">Benefits of WebAssembly</a></td>
    <td style="text-align: center"><a href="./README.md">Top</a></td>
    <td style="text-align: center"><a href="./03%20Calling%20WebAssembly%20from%20a%20Host%20Environment.md">Calling WebAssembly From a Host Environment</a></td></tr>
</table>

## 2: Creating a WebAssembly Module

Remember that a WebAssembly program can only be invoked from a host environment.  This will typically be a language runtime such as JavaScript or Rust, or it could be the WebAssembly System Interface (WASI).  Either way, from the perspective of the host environment, the WebAssembly module is the basic unit of instantiation and execution.

Here's a completely useless WebAssembly module.

[`02-useless.wat`](./src/02-useless.wat)
```wat
(module)
```

Although this module contains zero functionality, we could compile and attempt to run it using `wasmer`:

```bash
wasmer run ./src/01-useless.wat
```

This however, produces the following error message:

```bash
error: failed to run `01_useless.wat`
╰─> 1: The module has no exported functions to call.
```

Well, that's hardly surprising since the module doesn't contain any functions at all!

### Adding a Function

Let's now make the above module slightly less useless by adding a function that does nothing more than return the number `42`

[`02-slightly-less-useless.wat`](./src/02-slightly-less-useless.wat)
```wat
(module
  (func               ;; Declare a function that can be called from
    (export "answer") ;; outside the WASM module using the name "answer"
    (result i32)      ;; that returns a 32-bit integer
    (i32.const 42)    ;; Push 42 onto the stack then exit the function
  )                   ;; Any value left on the stack becomes the return value
)
```

Let's now compile and run this program:

```bash
wasmer run ./src/02-slightly-less-useless.wat
```

Hmmm, another error, but fortunately, we are presented with an informative message

```bash
error: failed to run `./src/02-slightly-less-useless.wat`
╰─> 1: No export `_start` found in the module.
       Similar functions found: `answer`.
       Try with: wasmer ./src/02-slightly-less-useless.wat -i answer
```

OK, so let's rerun the program with the extra `-i` argument (meaning `invoke`)

```bash
wasmer run ./src/02-slightly-less-useless.wat -i answer
42
```

There!  Although this is still pretty useless, this is the smallest functional WebAssembly module we can create.
