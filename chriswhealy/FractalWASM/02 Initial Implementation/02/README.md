| Previous | | Next
|---|---|---
| [1: Plotting Fractals](../../01%20Plotting%20Fractals/) | [Up](../) | [3: WAT Basic Implementation](../../03%20WAT%20Basic%20Implementation/)
| [2.1: Basic Escape-Time Implementation](../01/) | [2: Initial Implementation](../) |

## 2.2: Optimised Escape-Time Implementation

As previously implemented, the `escapeTime` function uses a brute-force approach because the loop only stops when one of our two hard limits is exceeded.  Fortunately however, there are two simple checks we can perform that allow us to avoid running the expensive escape-time loop if the given point lies within either the main cardioid or the period 2 bulb.

![Mandelbrot Regions](Mandelbrot%20Regions.png)

Any point lying within these two regions is a member of the Mandelbrot Set which means that its value will never escape to infinity.  The problem is that using our current approach, for every pixel within these regions, we will have to run the escape-time algorithm until it hits the `max_iters` limit simply to determine something we could discover using a significantly smaller amount of CPU time.

All we need to do now is add a check that takes the (`x`,`y`) coordinates of the pixel location, and checks whether it lies within either of these two regions.

The exact implementation of these functions is not important at the moment; we will simply assume that such function are available and that calling them is much cheaper than running the escape-time algorithm to completion:

```javascript
const isInMainCardioid   = (x, y) => ...
const isInPeriod2Bulb    = (x, y) => ...
const mandelEarlyBailout = (x, y) => isInMainCardioid(x,y) || isInPeriod2Bulb(x,y)
```

One other important point to note is that these functions must be passed the (`x`,`y`) ***coordinate*** value of the pixel, not its pixel ***location*** in the canvas.  This means that for the sake of efficiency, we need to convert the pixel location values stored in the loop counters `ix` and `iy` into coordinates of the complex plane before passing them either to the early bail out check, or the escape time algorithm itself.  

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

As you can see from the rendering time, adding this simple check makes the plot time between 5 and 6 times faster!