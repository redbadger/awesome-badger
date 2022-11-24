# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [6: Zooming In](/chriswhealy/FractalWASM/06%20Zoom%20Image/) | 7: WebAssembly and Web Workers |
| | | [7.1: JavaScript Web Workers](/chriswhealy/FractalWASM/07%20Web%20Workers/01/)

## 7: WebAssembly and Web Workers

In order to take advantage of the fact that plotting fractal images is an *embarrassingly parallel* task, we need to look at how we can spread out the computational workload across multiple instances of the same WebAssembly program.
This is where we will see that Web Workers form the basic building block for this solution.

We now need to make quite a few small, but significant changes to our coding.

And along the way we will discover several gotcha's that can prove confusing if you're not already aware of them!

1. [JavaScript Web Workers](./01/)
1. [Schematic Overview](./02/)
1. [Create the Web Worker](./03/)
1. [Adapt the Main Thread Coding](./04/)
