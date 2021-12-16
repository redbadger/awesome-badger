| Previous | | Next
|---|---|---
| [2: Initial Implementation](../../02%20Initial%20Implementation/) | [Up](../) |
| [3.1: Shared memory](../01/) | [3: Basic WAT Implementation](../) | [3.3: Generate the Colour Palette](../03/)

## 3.2: Create the WebAssembly Module

At the end of [§3.1](../01/) we assumed that our WebAssembly module would be called `mandel_plot.wasm`, so it would probably be a good idea to create this module now.

> The following coding has been performed in MS Visual Studio Code using the [WebAssembly Extension](https://marketplace.visualstudio.com/items?itemName=dtsvet.vscode-wasm) supplied by the WebAssembly Foundation.

Having created a file called `mandel_plot.wat`, start by defining the module and the resources that need to be imported from the host environment:

```wast
(module
  (import "js" "shared_mem" (memory 24))

  (global $image_offset   (import "js" "image_offset")   i32)
  (global $palette_offset (import "js" "palette_offset") i32)

  (global $BAILOUT f64 (f64.const 4.0))
  (global $BLACK   i32 (i32.const 0xFF000000))
)
```

Notice how the two-layer namespace is used to identify each property in the JavaScript object we created called `host_fns`.

> ***IMPORTANT***
>
> Currently, there is a limitation that the number of memory pages referenced in the `(memory ...)` clause must be hard-coded to match number of memory pages supplied by the host environment.  This value cannot be picked up from a variable reference.

For the sake of simplicity, we have kept the WebAssembly global names the same as the JavaScript property names.  So the WebAssembly global value `$image_offset` has the same name as the `host_fns` property `js.image_offset` from which its value has been obtained.

Should you wish to, the global names used within the WebAssembly module can be different from the property names supplied by the host environment.  However, consider whether having different internal and external names will help or hinder the clarity of your code...
