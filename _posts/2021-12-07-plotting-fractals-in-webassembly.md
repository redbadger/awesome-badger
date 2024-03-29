---
layout: post
title:  "Plotting Fractals in WebAssembly"
date:   2021-12-07 12:00:00 +0000
redirect_from: /chriswhealy/FractalWASM/
category: chriswhealy
author: Chris Whealy
excerpt: This set of blogs builds a progressively more optimised set of WebAssembly Text programs that plot the Mandelbrot and Julia Sets.
---

## Introduction

This tutorial is a continuation of the earlier [Introduction to WebAssembly Text](/chriswhealy/introduction-to-web-assembly-text)

If you are not familiar with WebAssembly Text (WAT), then please read the above introductory tutorial first because from this point on, I will assume that you are at least able to read and understand a WebAssembly Text program.

In the tutorials that follow, we will take a detailed look at how to implement an application in WebAssembly Text that plots the Mandelbrot and Julia Sets

## But Why Not Just Write the Solution in Rust?

I did [here](https://github.com/chriswhealy/fractal_explorer)!

But here's the thing...

When I wrote the above solution in Rust, I enjoyed all the advantages of using a language with much richer programming constructs and a compiler that turns out almost bullet-proof code.  However, when I used [`wasm-pack`](https://rustwasm.github.io/wasm-pack/installer/) to transform the Rust executable into a `.wasm` module, the resulting file was 74Kb in size.

This is certainly not large, but it was much larger than I expected given the simplicity of the task being performed.

So as a matter of both curiosity and education, I set about re-implementing this program in WebAssembly Text (WAT) to see just how small I could get it.

The results are encouraging because the hand-crafted `.wasm` file is now about 150 times smaller - just 493 bytes...

## Live Demo

[Plotting Fractals Using WebAssembly Threads and Web Workers](https://raw-wasm.pages.dev/)

# Table of Contents
1. [Plotting Fractals](/chriswhealy/FractalWASM/01%20Plotting%20Fractals/)
1. [Initial Implementation](/chriswhealy/FractalWASM//02%20Initial%20Implementation/)
1. [Basic WAT Implementation](/chriswhealy/FractalWASM//03%20WAT%20Basic%20Implementation/)
1. [Optimised WAT Implementation](/chriswhealy/FractalWASM//04%20WAT%20Optimised%20Implementation/)
1. [Plotting a Julia Set](/chriswhealy/FractalWASM//05%20MB%20Julia%20Set/)
1. [Zooming In](/chriswhealy/FractalWASM//06%20Zoom%20Image/)
1. [WebAssembly and Web Workers](/chriswhealy/FractalWASM//07%20Web%20Workers/)

[^1]: Please note: there is no space between the words "Web" and "Assembly"
