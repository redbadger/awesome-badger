# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [4: Optimised WAT Implementation](../04%20WAT%20Optimised%20Implementation/) | 5: Plotting a Julia Set | [6: Zooming In](../06%20Zoom%20Image/)
| | | [5.1: Web Page Changes](./01/)

## 5: Plotting a Julia Set

Now that we have an efficient means of plotting the Mandelbrot Set, we can add a second HTML `canvas` element to display the Julia Set.

For every point on the Mandelbrot Set, there is a corresponding Julia Set.
So as the mouse pointer moves over the Mandelbrot Set, a completely new Julia Set needs to be rendered.
Consequently, every time a `mousemove` event goes off over the Mandelbrot `canvas`, our now dual-purpose plot function needs to be called.

This is where we start to see the benefits of writing in WebAssembly Text.
Since we can focus on low-level efficiency, we can produce a very small, very fast program.

To plot the additional Julia Sets, we need to make two sets of changes:

1. [Web Page Changes](./01/)
1. [WebAssembly Changes](./02/)

Here's a working version of the [Mandelbrot Set with Dynamic Julia Sets](mb-julia-set.html)

### How Big is the WASM Module Now?

Good question, glad you asked...  😃

Now that we have a single WebAssembly module that can plot both the Mandelbrot and Julia Sets, it is worth looking at the size of the compiled module:

```bash
$ ll
total 56
drwxr-xr-x   8 chris  staff    256  9 Dec 19:04 .
drwxr-xr-x  10 chris  staff    320  9 Dec 18:41 ..
drwxr-xr-x   3 chris  staff     96  9 Dec 14:42 01
drwxr-xr-x   3 chris  staff     96  9 Dec 14:42 02
-rw-r--r--   1 chris  staff    894  9 Dec 16:26 README.md
-rw-r--r--   1 chris  staff   6812  9 Dec 18:25 mb-julia-set.html
-rw-r--r--   1 chris  staff    712  9 Dec 19:04 mj_plot.wasm
-rw-r--r--   1 chris  staff  11936  9 Dec 14:08 mj_plot.wat
```

Wow! Only 712 bytes!

This is not as small as the program could be, but its a big step forwards (downwards?) compared to the 74Kb module mentioned in the [introduction](/chriswhealy/plotting-fractals-in-webassembly).
