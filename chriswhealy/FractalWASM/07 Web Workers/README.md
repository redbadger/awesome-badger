# Plotting Fractals in WebAssembly

| Previous | | Next
|---|---|---
| [6: Zooming In](../06%20Zoom%20Image/) | [Top](/2021/12/07/plotting-fractals-in-webassembly.html) |

## 7: WebAssembly and Web Workers

In order to take advantage of the fact that plotting fractal images is an *embarrassingly parallel* task, we need to look at how we can plot these fractal images by implementing multiple instances of the same task, then running them in parallel.  This is where we will see that a Web Worker forms the basic building block for this solution.

In order to improve our runtime performance, we will spread out the computational workload across multiple instances of the same Web Worker program.

We now need to make quite a few small, but significant changes to our coding.  And along the way we will discover several gotcha's that can prove confusing if you're not already aware of them!

1. [JavaScript Web Workers](./01/)
1. [Schematic Overview](./02/)
1. [Create the Web Worker](./03/)
1. [Adapt the Main Thread Coding](./04/)
