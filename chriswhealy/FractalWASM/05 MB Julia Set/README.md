| Previous | | Next
|---|---|---
| [4: Optimised WAT Implementation](../04%20WAT%20Optimised%20Implementation/README.md) | [Up](../README.md) | 

## 5: Plotting a Julia Set

Now that we have an efficient means of plotting the Mandelbrot Set, we can now add an additional HTML `canvas` element to the Web page to display a Julia Set.

For every point on the Mandelbrot Set, there is a corresponding Julia Set.  So as the mouse pointer moves over the Mandelbrot Set, a completely new Julia Set needs to be rendered.  Consequently, every time a `mousemove` event goes off over the `canvas`, our now dual-purpose escape-time algorithm will be invoked.

This is where we will start to see the benefits of writing in WebAssembly Text, because we can focus on low-level efficiency.

We need to make two sets of changes:

1. [Web Page Changes](./01/README.md)
1. [WebAssembly Changes](./02/README.md)

