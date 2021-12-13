| Previous | | Next
|---|---|---
| [5: Plotting a Julia Set](../05%20MB%20Julia%20Set/) | [Up](../) | 
| [6.2 Add Slider for Changing `max_iters`](../02/) | [6: Zooming In](../) | 

### 6.3: Looking at the Problem We've Just Created

Take a look the performance of the [current version](../mb-julia-set.html) of this Web page.  As long as the value of `max_iters` stays low, and we don't zoom in very far, everything runs very smoothly.

But start to raise the iteration limit and zoom in, and things really start to slow down.

Over 7 seconds to draw the Mandelbrot Set and over 2 seconds to draw the Julia Set.  This problem become worse if we look at regions near or within the Mandelbrot Set (the black areas) because these are the places where our escape-time algorithm must run to completion before (I.E. run all the way up to `max_iters`) before we know that the pixel will be black.

Oh dear...

![Slow Runtime](Slow%20Runtime.png)

There several techniques for improving the performance here.  Some are based on watching the trajectory of the iterated coordinates each time around the the escape-time algorithm.  If a repeating series of coordinates is detected, then we bail out early.

However, here we're not going to modify the basic escape-time algorithm; instead, we will take advantage of the fact that plotting these fractal images is *"embarrassingly parallel"*.  This means we can use Web Workers to create multiple instances of our WebAssembly module, then call multiple copies of the `mj_plot` function.

In the next section we will look how WebAssembly allows us to use multiple threads that can all act upon the same block of linear memory by means of the atomic read-write-modify (`atomic.rmw`) statement.  This means we don't need to care about locks or mutexes.

