| Previous | | Next
|---|---|---
| [5: Plotting a Julia Set](../05%20MB%20Julia%20Set/) | [Up](../) | 
| [6.2 Add Slider for Changing `max_iters`](../02/) | [6: Zooming In](../) | 

### 6.3: Looking at the Problem We've Just Created

Take a look the performance of the [current version](../mb-julia-set.html) of this Web page.  As long as the value of `max_iters` stays low, and we don't zoom in very far, everything runs very smoothly.

But start zooming in and raising the iteration limit, and things really start to slow down.  The particular screen shot below shows a typical example of the problem: over 7 seconds to draw the Mandelbrot Set and over 2 seconds to draw the Julia Set.

This problem only becomes worse if we look at regions near or within the Mandelbrot Set (the black areas) because these are the places where our escape-time algorithm must run to completion (I.E. run all the way up to `max_iters`) before we know that the pixel will be black.

Oh dear...

![Slow Runtime](Slow%20Runtime.png)

There are several techniques for improving the performance here.  Some are based on watching the trajectory of the iterated coordinates each time around the the escape-time loop.  If a repeating series is detected, then we know that the orbit is stable and therefore we can bail out early.

However, we're going to take a different approach.  Instead of modifying the basic escape-time algorithm, we will take advantage of the fact that plotting these fractal images is *"embarrassingly parallel"*.  This means we can use Web Workers to parallelize the solution.

However, several basic changes will first need to be made:

1. Adapt the WebAssembly function `mj_plot` to use the `atomic.rmw` (read-modify-write) statement.  This allows multiple instances of the same WebAssembly module to act upon the same block of linear memory without interfering with each other, and without the need to manage locks or mutexes.
1. Create multiple instances of our WebAssembly module
1. Adapt the JavaScript coding to call multiple copies of the `mj_plot` function from Web Workers

In the next section we will look how to implement these changes.

