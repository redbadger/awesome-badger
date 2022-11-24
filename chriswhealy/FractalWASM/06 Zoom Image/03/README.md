# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [5: Plotting a Julia Set](/chriswhealy/FractalWASM/05%20MB%20Julia%20Set/) | [6: Zooming In](/chriswhealy/FractalWASM/06%20Zoom%20Image/) | [7: WebAssembly and Web Workers](/chriswhealy/FractalWASM/07%20Web%20Workers/)
| [6.2 Add Slider for Changing `max_iters`](/chriswhealy/FractalWASM/06%20Zoom%20Image/02/) | 6.3: Looking at the Problem We've Just Created |

### 6.3: Looking at the Problem We've Just Created

Take a look the performance of the [current version](../mb-julia-set.html) of this Web page.
As long as the value of `max_iters` stays low, and we don't zoom in very far, everything runs very smoothly.

But start zooming in and raising the iteration limit, and things really start to slow down.
The particular screen shot below shows a typical example of the problem: over 7 seconds to draw the Mandelbrot Set and over 2 seconds to draw the Julia Set.

This problem only becomes worse if we look at regions near or within the Mandelbrot Set (the black areas) because these are the places where our escape-time algorithm must run all the way up to `max_iters` before we know that the pixel will be black.

Oh dear...

![Slow Runtime](/assets/chriswhealy/Slow%20Runtime.png)

There are several techniques for improving the performance here.
Some are based on watching the trajectory of the iterated coordinates each time around the escape-time loop.
If a repeating series is detected, then we know that the orbit is stable and therefore we can bail out early.

However, we're going to take a different approach.
Instead of modifying the basic escape-time algorithm, we will take advantage of the fact that plotting these fractal images is *"embarrassingly parallel"*.
This means we can parallelize the solution.

However, this will require several basic changes to be made:

1. The combined efforts of multiple instances of function `mj_plot` will now be used to calculate a single fractal image.
Therefore, this function must be adapted so that multiple instances can all perform their own loops in parallel, but no two instances will ever attempt to calculate the same pixel value.
1. The JavaScript coding that creates an instance of the WebAssembly module must be moved into a JavaScript Web Worker
1. The main Web page must be adapted to create multiple Web Worker instances and then send them appropriate messages any time a user changes a value such as the zoom level or the maximum iterations.

In the next section we will look how to implement these changes.
