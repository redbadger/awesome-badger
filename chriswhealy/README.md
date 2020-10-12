# Chris Whealy

[@LogaRhythm](https://twitter.com/LogaRhythm)


> Senior Engineer and Developer working as much as possible with Rust and WebAssembly
> Outside work I play the drums, do audio engineering/post production/FOH and tinker with room acoustics


## Blogs

### Porous Absorber Calculator

This is a personal project that started in 2004 as an Excel spreadsheet, but has grown significantly since then.

I became interested in room acoustics and, as part of my studying, developed a tool for calculation the absorption curve of a porous absorber.  This tool generates a graph that shows how well a layer of porous material such as Rockwool or glass fibre will absorb sound across the full frequency range.

Then in 2019, when I started to learn Rust, I needed a real-life project to work on; so I decided to reimplement my Excel spreadhseet as a Web-based application written in Rust, then compiled to WebAssembly.

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
