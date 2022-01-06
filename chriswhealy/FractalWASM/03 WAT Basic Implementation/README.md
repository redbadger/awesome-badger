# Plotting Fractals in WebAssembly

| Previous | | Next
|---|---|---
| [2: Initial Implementation](../02%20Initial%20Implementation/) | [Top](/2021/12/07/plotting-fractals-in-webassembly.html) | [4: Optimised WAT Implementation](../04%20WAT%20Optimised%20Implementation/)

# 3: Basic WAT Implementation

The Web page used to implement the JavaScript version of the Mandelbrot Set is a good starting point from which to invoke the WebAssembly version of this program.

The only difference now is that the CPU-intensive task of calculating the fractal image will be implemented in a hand-crafted WebAssembly program.  The image data created by the WebAssembly program is then made available to JavaScript by means of shared memory.

1. [Shared Memory](./01/)
1. [Create the WebAssembly Module](./02/)
1. [Generate the Colour Palette](./03/)
1. [Escape-Time Algorithm](./04/)
1. [Calculating the Mandelbrot Set Image](./05/)
1. [Displaying the Rendered Fractal Image](./06/)
