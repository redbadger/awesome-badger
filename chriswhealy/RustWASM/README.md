# Porous Absorber Calculator

The purpose of this blog is not to explain any of the principles of acoustics or how to interpret the data plotted on the graphs shown below, but rather to describe the architecture of a browser-based WebAssembly application written in Rust.

## Preamble

My interest in room acoustics started in 2003 when I became involved in the design and build of a recording studio control room.  As part of studying this subject, I implemented what I had learnt in two Excel spreadsheets: the first was a general purpose tool for determining the [reverberation time of a rectilinear control room](http://whealy.com/acoustics/Control%20Room%20Calculator%20V2.67%20XL2007.zip), and the second was a tool for plotting the [absorption curve of a porous absorber](http://whealy.com/acoustics/Porous%20Absorber%20Calculator%20V1.59.xlsm.zip)

In Excel, the Control Room Calculator look like this:

![Control Room Spreadsheet](./img/Control%20Room%20Excel%20Screenshot.png)

And the Porous Absorber Calculator look like this:

![Porous Absorber Spreadsheet](./img/Porous%20Abs%20Excel%20Screenshot.png)

Unfortunately due to their age, these spreadsheets will only function correctly in the Windows version of Excel (sorry, Mac users...)

### Fast Forward to 2019

Having just been made redundant from my previous job and having lots of time on my hands, I decided to learn Rust &mdash; primarily because it compiles to WebAssembly.

Having completed all the simpler coding exercises, I was looking for a more real-life application to work on and decided to reimplement my Porous Absorber spreadsheet as a Web-based, WebAssembly app.  Seeing as this was my first real-life app, it took me a while to work out how to get all the pieces to fit together, but after a couple of months of battling my own inexperience, I was able to get this [Web-based app](http://whealy.com/acoustics/PA_Calculator/index.html) up and running.

![Porous Absorber Web App](./img/Porous%20Abs%20Screenshot.png)


## General Architecture

The app was developed in Microsoft's Visual Studio and uses the following hierarchy of Rust modules (for the sake of simplicity, some modules have been omitted):

![High-level Architecture](./img/Rust%20Architecture.png)

The objective here was to create an app that runs in the browser; however, since a browser cannot directly execute a native Rust application, it must be compiled into a format that a browser can execute &mdash; and this is where WebAssembly comes in.

### Compiling Rust to WebAssembly

To compile a Rust application into a WebAssembly module, you need to use a tool such as [`wasm-pack`](https://rustwasm.github.io/wasm-pack/installer/).  This tool acts as a wrapper around `cargo build` and generates a WebAssembly module (a `.wasm` file) from the compiled Rust code.

However, WebAssembly modules can be executed in a wide variety host environments.  In our case, we wish to execute this WebAssembly module in a browser, so our specific host environment will be the JavaScript runtime environment within a browser.  This therefore means that the `--target` will be `web`.

```console
$ wasm-pack build --release --target web
[INFO]: 🎯  Checking for the Wasm target...
[INFO]: 🌀  Compiling to Wasm...
   Compiling porous_absorber_calculator v1.1.0 (/Users/chris/Developer/porous_absorber)
    Finished release [optimized] target(s) in 2.63s
[INFO]: ⬇️  Installing wasm-bindgen...
[INFO]: Optimizing wasm binaries with `wasm-opt`...
[INFO]: ✨   Done in 3.38s
[INFO]: 📦   Your wasm pkg is ready to publish at /Users/chris/Developer/porous_absorber/pkg.
```

### Executing a WebAssembly Module in the Browser

The addition of the `--target web` parameter tells `wasm-pack` that we wish to run the generated WebAssembly module in the browser, and `wasm-pack` then helpfully generates a JavaScript polyfill for us.

![Generated WASM File](./img/Generated%20WASM%20File.png)

The polyfill acts as a wrapper around the WebAssembly module and enables us to use teh `import` statement as we would for any other JavaScript module.

This makes consumption of WebAssembly-based functionality super-easy.

```javascript
import init
, { porous_absorber
  , slotted_panel
  , perforated_panel
  , microperforated_panel
} from '../pkg/porous_absorber_calculator.js'
```




















Chris W

[![Red Badger Logo - Small](./img/Red%20Badger%20Small.png)](https://red-badger.com/)

