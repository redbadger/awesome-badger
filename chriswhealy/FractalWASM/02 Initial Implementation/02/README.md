# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [1: Plotting Fractals](/chriswhealy/FractalWASM/01%20Plotting%20Fractals/) | [2: Initial Implementation](/chriswhealy/FractalWASM/02%20Initial%20Implementation/) | [3: WAT Basic Implementation](/chriswhealy/FractalWASM/03%20WAT%20Basic%20Implementation/)
| [2.1: Basic Escape-Time Implementation](/chriswhealy/FractalWASM/02%20Initial%20Implementation/01/) | 2.2: Optimised Escape-Time Implementation |

## 2.2: Optimised Escape-Time Implementation

As previously implemented, the `escapeTime` function uses a brute-force approach because the loop only stops when one of our two hard limits is exceeded.
Fortunately however, there are two simple checks that allow us to avoid running the expensive escape-time loop if the point lies within either the main cardioid or the period 2 bulb.

![Mandelbrot Regions](/assets/chriswhealy/Mandelbrot%20Regions.png)

Any point lying within these two regions is a member of the Mandelbrot Set; which means that its value will ***never*** escape to infinity.
The problem is that using our current approach, for every pixel within these regions, we have to run the escape-time algorithm `max_iters` times when we could discover the same result using a significantly faster computation.

All we need to do is check whether the (`x`,`y`) coordinates of the pixel location lie within either of these two regions.
If either of these checks tell us that the current pixel ***is*** a member of the Mandbrot Set, then we don't even start running the escape-time algorith: we simply "bail out" early.

The exact implementation of these functions is not important at the moment; we will simply assume that such functions are available and that calling them is much cheaper than running the escape-time algorithm to completion:

```javascript
const isInMainCardioid   = (x, y) => ...
const isInPeriod2Bulb    = (x, y) => ...
const mandelEarlyBailout = (x, y) => isInMainCardioid(x,y) || isInPeriod2Bulb(x,y)
```

One other important point to note is that these functions must be passed the (`x`,`y`) ***coordinates*** of the point in the complex plane, not the pixel ***location*** on the canvas.
Therefore, we need to transform the pixel location stored in the loop counters `ix` and `iy`, into coordinates on the complex plane before passing them either to the early bail out check, or the escape time algorithm itself.

Hence the calls to `pixel2XCoord` and `pixel2YCoord` have been moved out of function `escapeTime()`

Now, our more efficient loop looks like this:

```javascript
for (let iy = 0; iy < mCanvas.height; ++iy) {
  let y0 = pixel2YCoord(iy)

  for (let ix = 0; ix < mCanvas.width; ++ix) {
    let x0 = pixel2XCoord(ix)

    // Assume the colour will be black
    let colour = 0xFF000000

    // Do we have to run the escape time algorithm?
    if (!mandelEarlyBailout(x0, y0)) {
      let iter = escapeTime(x0, y0)

      if (iter !== maxIters) {
        // This pixel has some colour other than black
        colour = iter2Colour(iter)
      }
    }

    // Write the 4-byte colour data to the ArrayBuffer using the 32-bit overlay
    buf32[iy * mCanvas.width + ix] = colour
  }
}
```

You can examine and run the coding of this [optimized implementation](optimised-implementation.html)

As you can see from the rendering time, adding this simple check reduces the plot time by a factor of between 5 and 6!
