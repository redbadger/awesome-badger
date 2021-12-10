| Previous | | Next
|---|---|---
| [1: Plotting Fractals](../01%20Plotting%20Fractals/) | [Up](../) | [3: Basic WAT Implementation](../03%20WAT%20Basic%20Implementation/)

# 2: Initial Implementation

In its simplest form, the algorithm to plot either the Mandelbrot or Julia Sets is just a highly repetitive calculation known as an "*escape-time*" algorithm.  That is, it performs a feedback loop that continues until its value either escapes to infinity, or some arbitrary time limit is reached.

However, before diving into the WebAssembly Text coding, let's first look at the basic algorithm as implemented in JavaScript.

## Assumptions

* The fractal image will be displayed using the 2d context of an HTML `canvas` element
* We require a function that can transform the `(x, y)` location of a pixel in the `canvas` element to the corresponding `(x, y)` location on the complex plane.  To start with, we will simply assume that such a function is available and not care about its implementation
* The escape-time algorithm must be called for every pixel in the image.  This algorithm returns a number ranging between 1 and `max_iters`
* To plot the fractal image, we need a function that transforms the number returned by the escape-time algorithm into a colour.  Again, we assume that such a function is available and do not care about its implementation.

## JavaScript Implementation

Before diving directly into the WAT coding, it is helpful to see the basic implementation in JavaScript.  Firstly, this will help you become familiar with overall structure of the solution, and secondly, it will act as a point of reference if you get lost when looking at the WebAssembly Text implementation.

* [2.1 Basic Escape-Time Implementation](./01/)
* [2.2 Optimised Escape-Time Implementation](./02/)

Now that you understand the JavaScript implementation, we can move on to rewriting this functionality in WebAssembly Text.
