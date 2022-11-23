# Plotting Fractals in WebAssembly

| Previous | | Next
|---|---|---
| [2: Initial Implementation](../../02%20Initial%20Implementation/) | [Top](/chriswhealy/plotting-fractals-in-webassembly) | [4: Optimised WAT Implementation](../../04%20WAT%20Optimised%20Implementation/)
| [3.1: Shared memory](../01/) | [3: Basic WAT Implementation](../) | [3.3: Generate the Colour Palette](../03/)

## 3.2: Create the WebAssembly Module

At the end of [§3.1](../01/) we assumed that our WebAssembly module would be called `mandel_plot.wasm`, so it would probably be a good idea to create this module now.

> The following coding has been written in MS Visual Studio Code using the [WebAssembly Extension](https://marketplace.visualstudio.com/items?itemName=dtsvet.vscode-wasm) supplied by the WebAssembly Foundation.

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

Notice how the `import` statement uses the two-level namespace to access the relevant properties in the `host_fns` JavaScript object.

***IMPORTANT***

The number of memory pages referenced in the `(memory ...)` clause must be hard-coded to match number of memory pages either supplied or expected by the host environment.
This value cannot be picked up dynamically from a variable.

For the sake of simplicity, we used WebAssembly global names that are the same as the JavaScript property names.
So the WebAssembly global value `$image_offset` has the same name as the `host_fns` property `js.image_offset` from which its value has been obtained.

Should you wish to, the global names used within the WebAssembly module can be different from the property names supplied by the host environment.
However, consider whether having different internal and external names will help or hinder the clarity of your code...
