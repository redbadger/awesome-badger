# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [5: Plotting a Julia Set](../../05%20MB%20Julia%20Set/) | [6: Zooming In](../) | [7: WebAssembly and Web Workers](../../07%20Web%20Workers/)
| [6.1 Add Zoom In/Out Functionality `max_iters`](../01/) | 6.2: Add Slider for Changing `max_iters` | [6.3 Looking at the Problem We've Just Created](../03/)

### 6.2: Add Slider for Changing `max_iters`

Next we will add a slider for changing the value of `max_iters`.

Every time `max_iters` changes, we will need to redraw both the Mandelbrot and current Julia Sets to account for the new level of detail.
In addition, we must also remember that the value of `max_iters` defines the number of colours in the palette; therefore, the colour palette will also need to be rebuilt.

#### Change the HTML

Inside a `table`, add a slider `input` element and a text field to display the current zoom level.

```html
<div>
  <table>
    <tr><th colspan="3">Left-click to zoom in, right-click to zoom out</th></tr>
    <tr><td>Max Iterations</td>
        <td><input class="horizontal" id="max_iters" type="range"></td>
        <td id="max_iters_txt"></td></tr>
    <tr><td>Zoom level</td>
        <td id="ppu_txt"></td></tr>
  </table>
</div>
```

A separate CSS file is referenced here that defines things such as the default typeface for the entire Web page (Raleway) and the width of the slider.

#### Define Slider Parameters

First, the slider parameters are defined in a configuration object:

```javascript
// Max iters slider parameters
const RANGE_MAX_ITERS = { MIN : 100, MAX : 32768, STEP : 100, DEFAULT : 1000 }
let   MAX_ITERS       = RANGE_MAX_ITERS.DEFAULT
```

#### Define Slider Event Handler

Since the slider event handler needs to draw both the Mandelbrot and Julia Sets, the X and Y coordinates of the last Julia set need to be available to this event handler; hence the addition of a document-wide object called `last_julia`:

```javascript
let last_julia = {
  x_coord : null,
  y_coord : null
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Max iters slider event handler
const update_max_iters = evt => {
  MAX_ITERS = evt.target.value
  $id("max_iters_txt").innerHTML = MAX_ITERS

  // Regenerate the colour palette
  wasmObj.instance.exports.gen_palette(MAX_ITERS)

  // Redraw Mandelbrot Set
  draw_fractal(0.0, 0.0, true)

  // Redraw last Julia Set
  if (last_julia.x_coord !== null && last_julia.y_coord !== null)
    draw_fractal(last_julia.x_coord, last_julia.y_coord, false)
}
```

Finally, in the `start` function, the slider properties are applied to the HTML `input` element and the event handler is attached:

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Async function to create WASM module instance, generate colour palette and plot Mandelbrot Set
const start = async () => {
  let max_iters_slider   = $id("max_iters")
  max_iters_slider.max   = RANGE_MAX_ITERS.MAX
  max_iters_slider.min   = RANGE_MAX_ITERS.MIN
  max_iters_slider.step  = RANGE_MAX_ITERS.STEP
  max_iters_slider.value = RANGE_MAX_ITERS.DEFAULT

  max_iters_slider.addEventListener("input", update_max_iters, false)

  $id("max_iters_txt").innerHTML = RANGE_MAX_ITERS.DEFAULT
  $id("ppu_txt").innerHTML = PPU

  // snip...
}

start()
```
