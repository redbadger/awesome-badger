| Previous | | Next
|---|---|---
| [2: Initial Implementation](../02%20Initial%20Implementation/) | [Up](../) | [4: Optimised WAT Implementation](../04%20WAT%20Optimised%20Implementation/)

# 3: Basic WAT Implementation

Starting from a Web page written in HTML and JavaScript, we want to display an image of the Mandelbrot set; however, the CPU-intensive task of calculating the fractal image will not be implemented in JavaScript, but rather delegated to a WebAssembly program that we will now write.

The image information created by WebAssembly is made available to JavaScript by means of shared memory.

1. [Shared Memory](./01/)
1. [Create the WebAssembly Module](./02/)
1. [Generate the Colour Palette](./03/)
1. [Escape-Time Algorithm](./04/)
1. [Calculating the Mandelbrot Set Image](./05/)
1. [Displaying the Rendered Fractal Image](./06/)