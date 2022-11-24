# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [5: Plotting a Julia Set](/chriswhealy/FractalWASM/05%20MB%20Julia%20Set/) | 6: Zooming In | [7: WebAssembly and Web Workers](/chriswhealy/FractalWASM/07%20Web%20Workers/)
| | | [6.1: Add Zoom In/Out Functionality](/chriswhealy/FractalWASM/06%20Zoom%20Image/01/)

## 6: Zooming In

Now that we can dynamically plot a Julia Set corresponding to any location on the Mandelbrot Set, it would be nice to be able to zoom in on the Mandelbrot Set.

However, in order to see a reasonable level of detail as we zoom in, it will also be necessary to increase the maximum number of iterations.

In this particular section, we will only be changing the JavaScript and HTML coding.
Our underlying WebAssembly function does not need to change.

1. [Add Zoom In/Out Functionality](./01/)
1. [Add Slider for Changing `max_iters`](./02/)
1. [Looking at the Problem We've Just Created](./03/)
