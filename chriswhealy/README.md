# Chris Whealy

[@LogaRhythm](https://twitter.com/LogaRhythm)


> Senior Engineer and Developer working as much as possible with Kotlin, Rust and WebAssembly
> 
> Outside work I play the drums, do audio engineering/live streaming/post production/FoH and tinker with room acoustics


## Blogs

### Plotting Fractals with WebAssembly

If you have read the [Introduction to WebAssembly Text](./Introduction%20to%20WebAssembly%20Text/) blogs described below, then I trust you will also be interested in taking your knowledge another step further.

This set of blogs builds a progressively more optimised set of WebAssembly Text programs that plot the Mandelbrot Set and multiple Julia Sets.

[Plotting Fractals with WebAssembly](FractalWASM/README.md)

### Introduction to WebAssembly Text

WebAssembly is usually thought of as simply a compilation target.  The usual workflow is that you write your application in some other language (such as Rust), then compile it to WebAssembly and have it run pretty much anywhere.

This approach is fine&mdash;most of the time.

However, there are circumstances in which you need to perform a highly repetitive, CPU-intensive task.  Under these conditions, you need to ensure that your application is as small and as fast as possible; and this is where you need to start writing in WebAssembly Text.

[Introduction to WebAssembly Text](./Introduction%20to%20WebAssembly%20Text/)

### `toString || !toString`

> toString, or not toString? That is the question&mdash;  
> Whether 'tis nobler in the mind to suffer  
> the slings and arrows of outrageous type conversion,  
> Or to take up arms against a sea of troublesome JavaScript behaviours,  
> and by opposing end them? To Git, to blame&mdash;  
> No more&mdash;and by a pull request to say we end  
> The heartache and the thousand natural shocks  
> That programmers are heir to&mdash;’tis a consummation  
> Devoutly to be wished!...

(with apologies to the Bard)

[toString or not toString](./toStringOrNotToString/)

### Porous Absorber Calculator

This is a personal project that started in 2004 as an Excel spreadsheet, but has grown significantly since then.

I became interested in room acoustics and, as part of my studying, developed a tool for calculation the absorption curve of a porous absorber.  This tool generates a graph that shows how well a layer of porous material such as Rockwool or glass fibre will absorb sound across the full frequency range.

Then in 2019, when I started to learn Rust, I needed a real-life project to work on; so I decided to re-implement my Excel spreadsheet as a Web-based application written in Rust, then compiled to WebAssembly.

The purpose of this blog is to describe how a Web-based app can be written in Rust, then compiled to WebAssembly and executed in the browser.

[From Rust to the Browser via WebAssembly](./RustWASM/)

### Understanding JavaScript

This is a work-in-progress series of blogs on understanding various internal features of JavaScript

1. [Type Coercion](./InsideJavaScript/01%20Type%20Coercion/)

    5th May 2020

    A somewhat light-hearted look at how type coercion works and some of its more unexpected consequences.

1. [Objects and Arrays](./InsideJavaScript/02%20Objects%20and%20Arrays/)

    7th May 2020

    A look at how JavaScript Objects can be accessed as if they were arrays, and the fact that all JavaScript Arrays are in fact Objects.

1. [Variable Hoisting](./InsideJavaScript/03%20Hoisting/)

    8th May 2020

    JavaScript moves variable declarations to the top of function declarations using a strategy called *"hoisting"*.  Here, we take a look not only at this feature and its consequences, but also at situations in which it does not happen.
