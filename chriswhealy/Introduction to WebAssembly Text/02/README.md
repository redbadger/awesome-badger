# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [Benefits of WebAssembly](../01/) | [Up](/chriswhealy/introduction-to-web-assembly-text) | [Calling WebAssembly From a Host Environment](../03/)


## 2: Creating a WebAssembly Module

Remember that a WebAssembly program can only be invoked from a host environment.  This will typically be a language runtime such as JavaScript or Rust, or it could be the WebAssembly System Interface (WASI).  Either way, from the perspective of the host environment, the WebAssembly module is the basic unit of instantiation.

Here's a syntactically correct, but completely useless WebAssembly module.

[`02-useless.wat`](/assets/chriswhealy/02-useless.wat)
```wast
(module)
```

Although this module contains zero functionality, we can compile it and attempt to run it using `wasmer`:

```bash
wasmer 02-useless.wat
```

No prizes for guessing however that this produces an error message:

```bash
error: failed to run `02-useless.wat`
╰─> 1: The module has no exported functions to call.
```

Well, that's hardly surprising since the module doesn't contain any functions at all!

### Adding a Function

Let's now make the above module slightly less useless by adding a function that does nothing more than return the number `42`

[`02-slightly-less-useless.wat`](/assets/chriswhealy/02-slightly-less-useless.wat)
```wast
(module
  (func               ;; Declare a function that can be called from
    (export "answer") ;; outside the WASM module using the name "answer"
    (result i32)      ;; that returns a 32-bit integer
    (i32.const 42)    ;; Push 42 onto the stack
  )                   ;; Exit the function. Any value left on the stack becomes the function's return value
)
```

Let's now compile and run this program:

```bash
wasmer 02-slightly-less-useless.wat
```

Hmmm, another error, but fortunately, we are presented with an informative message

```bash
error: failed to run `02-slightly-less-useless.wat`
╰─> 1: No export `_start` found in the module.
       Similar functions found: `answer`.
       Try with: wasmer 02-slightly-less-useless.wat -i answer
```

OK, let's rerun the program with the extra `-i` argument (meaning `invoke`)

```bash
wasmer 02-slightly-less-useless.wat -i answer
42
```

There!  Although this is still pretty useless, this is the smallest functional WebAssembly module we can create.
