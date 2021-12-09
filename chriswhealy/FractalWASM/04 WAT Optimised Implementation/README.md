| Previous | | Next
|---|---|---
| [3: Basic WAT Implementation](../03%20WAT%20Basic%20Implementation/README.md) | [Up](../README.md) | [5: Plotting a Julia Set](../05%20MB%20Julia%20Set/README.md)

## 4: Optimised WAT Implementation

Now that we have a working implementation, let's add an optimisation that will greatly improve performance.

As it mentioned in [§2.2](../02%20Initial%20Implementation/02/README.md), there are certain locations on the Mandelbrot Set where we know that the escape-time algorithm will always escape to infinity.  Therefore, to improve performance, we will first test whether the current pixel falls within one of these areas.  If it does, we can save ourselves the cost of running an expensive algorithm because we already know the outcome &mdash; black.

To achieve this, we need to do the following:

1. [Check for Early Bailout](./01/README.md)
1. [Modify Render Loop](./02/README.md)

