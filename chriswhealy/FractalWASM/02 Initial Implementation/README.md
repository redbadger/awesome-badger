# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [1: Plotting Fractals](/chriswhealy/FractalWASM/01%20Plotting%20Fractals/) | 2: Initial Implementation | [3: Basic WAT Implementation](/chriswhealy/FractalWASM/03%20WAT%20Basic%20Implementation/)
| |  | [2.1: Basic Escape-Time Implementation](/chriswhealy/FractalWASM/02%20Initial%20Implementation/01/)

# 2: Initial Implementation

In its simplest form, the algorithm to plot either the Mandelbrot or Julia Sets is just a highly repetitive calculation known as an "*escape-time*" algorithm.
That is, we perform a feedback loop in which we take the number that comes out of the previous iteration and put it back into the next iteration until the value either escapes to infinity, or we exceed some arbitrary time limit.

## JavaScript Implementation

However, before diving directly into the WAT coding, it would be helpful to see a basic JavaScript implementation.
Firstly, this will help you become familiar with overall structure of the solution, and secondly, it will act as a point of reference if you get lost when looking at the WebAssembly Text implementation.

* [2.1 Basic Escape-Time Implementation](./01/)
* [2.2 Optimised Escape-Time Implementation](./02/)

## Implementation Details

* The fractal image will be displayed using the 2d context of an HTML `canvas` element
* We require a function that can transform the `(x, y)` location of a pixel in the `canvas` element to the corresponding `(x, y)` location on the complex plane.  To start with, we will simply assume that such a function is available and not care about its implementation
* The escape-time algorithm must be called for every pixel in the image.  This algorithm returns a number ranging between 1 and `max_iters`
* To plot the fractal image, we need a function that transforms the number returned by the escape-time algorithm into a colour.  Again, we assume that such a function is available and do not care about its implementation.
