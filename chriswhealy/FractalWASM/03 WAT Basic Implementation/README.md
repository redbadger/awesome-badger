# 3: WAT - Basic Implementation

First of all, we need to look at the initial task we want to perform:

1. Starting from a Web page written in HTML and JavaScript, we want to display an image of the Mandelbrot set
1. The CPU-intensive task of calculating the fractal image will not be implemented in JavaScript, but rather delegated to a WebAssembly program
1. Information will be transferred between JavaScript and WebAssembly by means of shared memory

1. [Shared Memory](./01/README.md)
1. [Create the WebAssembly Module](./02/README.md)
1. [Generate the Colour Palette](./03/README.md)
1. [Escape-Time Algorithm](./04/README.md)
