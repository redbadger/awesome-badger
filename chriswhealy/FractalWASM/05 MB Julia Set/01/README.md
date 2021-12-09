| Previous | | Next
|---|---|---
| [4: Optimised WAT Implementation](../../04%20WAT%20Optimised%20Implementation/README.md) | [Up](../../README.md) | 
| | [5: Plotting a Julia Set](../README.md) | [5.2 WebAssembly Changes](../02/README.md)

### 5.1: Web Page Changes

#### Extend the HTML

The following HTML `canvas` and `div` elements have been added
   
```html
<div>Julia Set corresponding to
  (<span id="x_complex_coord"></span>,<span id="y_complex_coord"></span>)
  on the Mandelbrot Set rendered in <span id="julia_runtime"></span>ms
</div>
```

The `div` element contains some `span` elements into which the mouse pointer coordinates and the rendering time will be displayed

#### Increase Shared Memory

The memory requirements for the new Julia Set image are calculated in exactly the same way as for the Mandelbrot Set.  For simplicity, we'll define the Julia Set image to be the same size as the Mandelbrot Image.

```javascript
const jCanvas  = $id('juliaImage')
jCanvas.width  = DEFAULT_CANVAS_WIDTH
jCanvas.height = DEFAULT_CANVAS_HEIGHT
   
const jContext     = jCanvas.getContext('2d')
const jImage       = jContext.createImageData(jCanvas.width, jCanvas.height)
const jImagePages  = Math.ceil(jImage.data.length / WASM_PAGE_SIZE)
const jImageOffset = WASM_PAGE_SIZE * mImagePages
```

Now when we allocate the block of shared memory, we must account for the space needed by the second image.  The easiest way to do this is simply to add up the number of memory pages needed by both images and the colour palette.

```javascript
const wasmMemory = new WebAssembly.Memory({
  initial : mImagePages + jImagePages + palettePages
})
```

Previously, we supplied the memory offset as a static value in the `host_fns` object.  WebAssembly then picks up this object at the time the module is instantiated.  However, since the same WebAssembly function is now going to plot both the Mandelbrot and Julia Sets, we will need to supply two offsets.

Rather than supplying two memory offset values as static fields in the `host_fns` object, it is easier to pass the relevant memory offset as a runtime argument.  So now the `js` namespace of the `host_fns` object contains only two properties:

```javascript
const host_fns = {
  js : {
    shared_mem : wasmMemory,
    palette_offset : WASM_PAGE_SIZE * (mImagePages + jImagePages),
  }
}
```

#### Write a `mousemove` Event Handler

Since a new Julia Set must be calculated every time the mouse moves over the Mandelbrot Set image, we will need an event handler function attached to the `mousemove`  event of the `juliaImage` HTML `canvas` element.

This event handler must do the following things:
1. Transform the mouse pointer's `X` ,`Y` position over the image into the `X`, `Y` coordinates of the complex plane
1. Invoke the WebAssembly function to plot a new Julia Set
1. Update the Julia Set image from the relevant section of shared memory

This event handler function also uses some helper functions to calculate exactly where the mouse is in relation to image embedded within the canvas:

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Partial function to translate the mouse X or Y canvas position to the corresponding X or Y coordinate in the complex
// plane.
const canvas_pxl_to_coord = (cnvsDim, ppu, origin) => mousePos => origin + ((mousePos - (cnvsDim / 2)) / ppu)
const mandel_x_pos_to_coord = canvas_pxl_to_coord(DEFAULT_CANVAS_WIDTH, PPU, DEFAULT_X_ORIGIN)
const mandel_y_pos_to_coord = canvas_pxl_to_coord(DEFAULT_CANVAS_HEIGHT, PPU, DEFAULT_Y_ORIGIN)

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Return a value clamped to the magnitude of the canvas image dimension accounting also for the canvas border width
const offset_to_clamped_pos = (offset, dim, offsetDim) => {
  let pos = offset - ((offsetDim - dim) / 2)
  return pos < 0 ? 0 : pos > dim ? dim : pos
}
```

With these helper functions defined, the event handler is:

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Mouse move event handler
const mouse_track = evt => {
  // Transform the mouse pointer pixel location to coordinates in the complex plane
  let x_coord = mandel_x_pos_to_coord(
    offset_to_clamped_pos(evt.offsetX, evt.target.width, evt.target.offsetWidth)
  )
  // On a canvas, positive Y direction is down, but this needs to be flipped when converting to coordinates
  let y_coord = mandel_y_pos_to_coord(
    offset_to_clamped_pos(evt.offsetY, evt.target.height, evt.target.offsetHeight)
  ) * -1

  // Display the mouse pointer's current position as coordinates in the complex plane
  $id('x_complex_coord').innerHTML = x_coord
  $id('y_complex_coord').innerHTML = y_coord

  // Record the start time and render the Julia Set
  const start_time = performance.now()
  wasmObj.instance.exports.mj_plot(
    DEFAULT_CANVAS_WIDTH, DEFAULT_CANVAS_HEIGHT, // Julia Set canvas dimensions
    0.0, 0.0,                                    // Coordinates of centre pixel
    x_coord, y_coord,                            // Pointer coordinates over Mandelbrot Set
    PPU, DEFAULT_MAX_ITERS,                      // Default zoom level and iteration limit
    false, jImageOffset,                           // isMandelbrot and Julia Set image data offset
  )

  $id("julia_runtime").innerHTML = microPrecision(performance.now() - start_time)

  // Transfer the relevant slice of shared memory to the canvas image, then display it
  jImage.data.set(wasmMem8.slice(jImageOffset, jImageOffset + jImage.data.length))
  jContext.putImageData(jImage, 0, 0)
}
```

Lastly for this section, attach the event handler function to the `canvas` element's `mousemove` event:

```javascript
mCanvas.addEventListener('mousemove', mouse_track, false)
```

#### Reference a Single WebAssembly Module Instance

At this stage of our development, the Mandelbrot Set is plotted once, but every time the mouse pointer moves, a new Julia Set must be calculated.  Therefore, we must adjust the coding to ensure that the WebAssembly module is only instantiated once.

The declaration of `wasmObj` (that previously was just a local constant within the asynchronous `start` function) is moved outside the scope of the function and exists at the window level

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// WASM module instance needs to exist at the window level
let wasmObj

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Async function to create WASM module instance, generate colour palette and plot Mandelbrot Set
const start = async () => {
  wasmObj = await WebAssembly.instantiateStreaming(fetch('./mj_plot.wasm'), host_fns)
  
  // snip...
```