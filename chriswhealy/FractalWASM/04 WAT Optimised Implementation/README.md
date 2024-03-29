# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [3: Basic WAT Implementation](/chriswhealy/FractalWASM/03%20WAT%20Basic%20Implementation/) | 4: Optimised WAT Implementation  | [5: Plotting a Julia Set](/chriswhealy/FractalWASM/05%20MB%20Julia%20Set/)
| | | [4.1: Check for Early Bailout](/chriswhealy/FractalWASM/04%20WAT%20Optimised%20Implementation/01/)

## 4: Optimised WAT Implementation

Now that we have a working implementation, let's add an optimisation that will greatly improve performance.

As it mentioned in [§2.2](/chriswhealy/FractalWASM/02%20Initial%20Implementation/02/), there are certain locations on the Mandelbrot Set where we know that the escape-time algorithm will ***never*** escape to infinity.
Unfortunately, our simplistic escape-time algorithm cannot know this until it has repeated the loop `max_iters` times.
This is a big waste of time, since we can already determine that this particular pixel will be black.

Therefore, to improve performance, we will first test whether the current pixel falls within either the main cardioid or the period 2 bulb.
If it does, we can bail out early.
To achieve this, we need to do the following:

1. [Check for Early Bailout](./01/)
1. [Modify the Render Loop](./02/)
