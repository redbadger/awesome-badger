# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [5: Plotting a Julia Set](../../05%20MB%20Julia%20Set/) | [6: Zooming In](../) | [7: WebAssembly and Web Workers](../../07%20Web%20Workers/)
| | 6.1: Add Zoom In/Out Functionality | [6.2 Add Slider for Changing `max_iters`](../02/)

### 6.1: Add Zoom In/Out Functionality

Now we will add the functionality that allows you to zoom in and out of the Mandelbrot Set.
This will be implemented simply by left and right mouse clicks.

Any given zoom level is determined simply by deciding how many pixels are needed to plot one unit on the complex plane.
The higher the number of pixels, the greater your level of magnification.
The default (and also minimum) zoom level is `200` pixels per unit.
This value has been derived by dividing the entire canvas width by 4, thus allowing you to see the entire Mandelbrot Set.

We'll start by defining the maximum, minimum and current zoom levels:

```Javascript
const MAX_PPU = 6553600            // Allow for 16 zoom steps (100 * 2^16)
const MIN_PPU = CANVAS_WIDTH / 4   // Start by showing entire Mandelbrot Set
let   PPU     = MIN_PPU
```

When you zoom in, the zoom level is doubled until `MAX_PPU` is reached.
Similarly, when you zoom out, the zoom level is halved until `MIN_PPU` is reached.
When `MIN_PPU` is reached, the image of the Mandelbrot Set is automatically recentred.
In both cases, the location on which you click becomes the centre pixel of the new image.

Since both the zoom level and the coordinates of the image's centre pixel are now variable, every time the zoom level changes, we need to redefine the helper functions that transform a pixel location to complex plane coordinates.

This firstly means that functions `mandel_x_pos_to_ccord` and `mandel_y_pos_to_ccord` can no longer be defined as constants:

```javascript
let mandel_x_pos_to_coord = canvas_pxl_to_coord(CANVAS_WIDTH,  PPU, X_ORIGIN)
let mandel_y_pos_to_coord = canvas_pxl_to_coord(CANVAS_HEIGHT, PPU, Y_ORIGIN)
```

#### Zoom Event Handler

The functionality needed when zooming into the Mandelbrot Set is almost identical to that needed when zooming out.
The only difference is that when we zoom in, `PPU` is multiplied by two until it reaches `MAX_PPU`, and when we zoom out, `PPU` is divided by two until it reaches `MIN_PPU`.

This means we can create a single partial function that when passed the zoom direction, returns an event handler function that changes `PPU` appropriately.

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Partial function for handling image zoom in/out events
const zoom = zoom_in => evt => {
  // Suppress default context menu when zooming out
  if (!zoom_in) evt.preventDefault()

  // Transform the mouse pointer pixel location to coordinates in the complex plane
  X_ORIGIN = mandel_x_pos_to_coord(
    offset_to_clamped_pos(evt.offsetX, evt.target.width, evt.target.offsetWidth)
  )
  Y_ORIGIN = mandel_y_pos_to_coord(
    offset_to_clamped_pos(evt.offsetY, evt.target.height, evt.target.offsetHeight)
  )

  // Change zoom level
  PPU = zoom_in
        ? (new_ppu => new_ppu > MAX_PPU ? MAX_PPU : new_ppu)(PPU * 2)
        : (new_ppu => new_ppu < MIN_PPU ? MIN_PPU : new_ppu)(PPU / 2)
  $id("ppu_txt").innerHTML = PPU

  // If we're back out to the default zoom level, then recentre the Mandelbrot Set image
  if (PPU === MIN_PPU) {
    X_ORIGIN = DEFAULT_X_ORIGIN
    Y_ORIGIN = DEFAULT_Y_ORIGIN
  }

  // Update the mouse position helper functions using the new X/Y origin and zoom level
  mandel_x_pos_to_coord = canvas_pxl_to_coord(CANVAS_WIDTH,  PPU, X_ORIGIN)
  mandel_y_pos_to_coord = canvas_pxl_to_coord(CANVAS_HEIGHT, PPU, Y_ORIGIN)

  // Redraw the Mandelbrot Set
  draw_fractal(0.0, 0.0, true)
}
```

Notice also that the call to the WebAssembly function `mj_plot` has been moved into a function called `draw_fractal`.

Now, the zoom event handler is added to the Mandelbrot `canvas` HTML element for both the left (`click`) and right (`contextmenu`) mouse click events:

```javascript
mCanvas.addEventListener('click',       zoom(true),  false)
mCanvas.addEventListener('contextmenu', zoom(false), false)
```
