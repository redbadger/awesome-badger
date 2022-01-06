# Plotting Fractals in WebAssembly

| Previous | | Next
|---|---|---
| [6: Zooming In](../../../06%20Zoom%20Image/) | [Top](/2021/12/07/plotting-fractals-in-webassembly.html) |
| [7.2 Schematic Overview](../../02/) | [7: WebAssembly and Web Workers](../../) |
| [7.4.1 Extend the HTML](../01/)  | [7.4: Adapt the Main Thread Coding](../) | [7.4.3 Create Web Workers](../03/)

### 7.4.2 Split WebAssembly Coding

Currently, our WebAssembly module contains the coding both for plotting a fractal image ***and*** for generating the colour palette.

Given that generating a colour palette is a very lightweight task, there is no reason to keep this coding in a module that will be instantiated multiple times.  Therefore, we will extract all the coding related to the colour palette and put it in its own module called `colour_palette.wat`

After collapsing the function bodies, the source code of our new `colour_palette.wat` module looks like this:

![Colour Palette Coding](/assets/chriswhealy/Colour%20Coding.png)

***IMPORTANT***<br>
Notice the highlighted `memory` statement on line 2!

Previously, the `memory` declaration specified only the initial number of memory pages:

```wast
(import "js" "shared_mem" (memory 46))
```

This is fine in situations where you share memory only between WebAssembly and the host environment.  However, we additionally need to share memory between multiple WebAssembly module instances.  This means that our `memory` declaration also include the total number of pages and the fact that this memory is now shared:

```wast
(import "js" "shared_mem" (memory 46 46 shared))
```

OK, let's try compiling this:

```shell
$ wat2wasm colour_palette.wat
colour_palette.wat:2:4: error: memories may not be shared
  (import "js" "shared_mem" (memory 46 46 shared))
   ^^^^^^
```

Oh dear, the compiler is telling us we can't do the very thing we need to do...

To fix this problem, we must tell the compiler that we will be using WebAssembly threads:

```shell
$ wat2wasm --enable-threads colour_palette.wat
$
```

Other changes will be needed in the remaining code in the `mj_plot` module, but we will cover these in a separate section.

### Creating the Colour Palette

Now that we have separated the colour palette functionality into its own WebAssembly module, this is now the only WebAssembly module directly instantiated by the main thread.

So our `start` function now:

1. Initialises the UI using the helper function `init_slider`
1. Creates an instance of the WebAssembly module `colour_palette.wasm`
1. Calls the `gen_palette()` WebAssembly function
1. Calls function `rebuild_workers()` to create the initial number of Web Workers.  (This function is described in the next section).

```javascript
let wasm_colour

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Async function to initialise the UI, create WASM colour palette module, generate colour palette then create the
// required number of Web Workers
const start = async () => {
  // Initialise the UI
  init_slider("max_iters", RANGE_MAX_ITERS, MAX_ITERS, "input", update_max_iters)
  init_slider("workers", RANGE_WORKERS, WORKERS, "input", rebuild_workers)

  $id("ppu_txt").innerHTML = PPU

  // Palette generation does not need to be delegated to a worker thread
  wasm_colour = await WebAssembly.instantiateStreaming(fetch("./colour_palette.wasm"), host_fns)
  wasm_colour.instance.exports.gen_palette(MAX_ITERS)

  rebuild_workers()
}
```
