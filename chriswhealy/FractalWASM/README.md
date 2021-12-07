# Plotting Fractals with WebAssembly

## Introduction

This sets of blogs is a continuation of the earlier blogs that give an [Introduction to WebAssembly Text](https://awesome.red-badger.com/chriswhealy/Introduction%20to%20WebAssembly%20Text/)

If you are not familiar with WebAssembly Text (WAT), then please read the above set of blogs because from this point on, I will assume that you are able at least to read and understand a WebAssembly Text program.

In the blogs that follow, we will take a detailed look at how to implement an application in WebAssembly Text that plots the Mandelbrot and Julia Sets

## But Why Not Just Write the Solution in Rust?

I did [here](https://github.com/ChrisWhealy/fractal_explorer)!

But here's the thing...

When I wrote the above solution in Rust, I enjoyed all the advantages of using a language with much richer programming constructs and a compiler that turns out almost bullet-proof code.  However, when I used [`wasm-pack`](https://rustwasm.github.io/wasm-pack/installer/) to transform the Rust executable into a `.wasm` module, the resulting file was 74Kb in size.

This is certainly not large, but it was much larger than I expected given the simplicity of the task being performed.

So as a matter of both curiosity and education, I set about re-implementing this program in WebAssembly Text (WAT) to see just how small I could get the program.

The results are encouraging.  I've got the `.wasm` file down to just 940 bytes...

# Table of Contents
1. [Plotting Fractals](./01%20Plotting%20Fractals/README.md)
1. [Initial Implementation](./02%20Initial%20Implementation/README.md)
1. [Basic WAT Implementation](./03%20WAT%20Basic%20Implementation/README.md)






























[^1]: Please note: there is no space between the words "Web" and "Assembly"
