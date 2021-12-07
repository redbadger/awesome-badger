## 3.2: Create the WebAssembly Module

At the end of [§3.1](../01/README.md) we assumed that our WebAssembly module would be called `mandel_plot.wasm`, so it would probably be a good idea to create this module now.

> The following coding has been performed in MS Visual Studio Code using the [WebAssembly Extension](https://marketplace.visualstudio.com/items?itemName=dtsvet.vscode-wasm) supplied by the WebAssembly Foundation.

Having created a file called `mandel_plot.wat`, start by defining the module and the resources that need to be imported from the host environment:

```wat
(module
  (import "js" "shared_mem" (memory 24))

  (global $image_offset   (import "js" "image_offset")   i32)
  (global $palette_offset (import "js" "palette_offset") i32)

)
```

Notice how the two-layer namespace is used to identify each property in the JavaScript object we created called `host_fns`.

> We have kept the WebAssembly global names the same as the JavaScript property names, so `$image_offset` has the same name as the `host_fns` property `js.image_offset` from which it has been derived; however, this has only been done for the sake of simplicity.  It is not a requirement.
