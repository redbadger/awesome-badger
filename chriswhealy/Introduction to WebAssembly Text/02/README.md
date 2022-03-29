# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [Benefits of WebAssembly](../01/) | [Up](/chriswhealy/introduction-to-web-assembly-text) | [Using a Language Runtime as a WebAssembly Host Environment](../03/)


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

Well, that's hardly surprising since this is an empty module!

### Adding a Function

Let's now make the above module slightly less useless by adding a function that does nothing more than return the number `42`

[`02-slightly-less-useless.wat`](/assets/chriswhealy/02-slightly-less-useless.wat)
```wast
(module
  (func               ;; Declare a function
    (export "answer") ;; Expose this function using the name "answer"
    (result i32)      ;; Declare that this function returns a 32-bit integer
    (i32.const 42)    ;; Push 42 onto the stack
  )                   ;; Exit the function
  ;; Any value left on the stack automatically becomes that function's return value.
  ;; It is your responsibility to ensure that this value's data type matches the
  ;; declared return type
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

Unless you say otherwise, `wasmer` attempts to run a function called `_start`.  So at this point we have two options:

1. We could rename the function `answer` to have the default name `_start`, then it would be executed automatically (however, the return value would be suppressed[^1]); or,
1. We can pass `wasmer` the `invoke` argument (`-i`) and then provide the function name we wish to run

```bash
wasmer 02-slightly-less-useless.wat -i answer
42
```

There!  Although this module is still pretty useless, we have just created the smallest functional WebAssembly module possible.

<hr>

[^1]: A basic design concept here is the idea that a WebAssembly module instance should persist for some extended period of time.  By design therefore, the `_start` function exists simply to perform whatever start-up functionality is required to create a persistent module instance, and thereafter, functionality is invoked through the module's API of exported functions.  Consequently, `wasmer` assumes that the default function `_start` will not return any value: in fact `wasmer` suppresses `_start`'s return value.  Even if we did use the default function name `_start`, we would only see its return value if we explicitly specify the function name using the `invoke` (`-i`) argument.
