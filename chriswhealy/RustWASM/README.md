# Porous Absorber Calculator

The purpose of this blog is not to explain any of the principles of acoustics or how to interpret the data plotted on the graphs shown below, but rather to describe the architecture of a browser-based WebAssembly application in Rust.

## Preamble

My interest in room acoustics started in 2003 when I became involved in the design and build of a recording studio control room.  As part of studying this subject, I implemented what I had learnt in two Excel spreadsheets: the first was a general purpose tool for determining the [reverberation time of a rectilinear control room](http://whealy.com/acoustics/Control%20Room%20Calculator%20V2.67%20XL2007.zip), and the second was a tool for plotting the [absorption curve of a porous absorber]((http://whealy.com/acoustics/Porous%20Absorber%20Calculator%20V1.59.xlsm.zip))

In Excel, the Control Room Calculator look like this:

![Control Room Spreadsheet](./img/Control%20Room%20Excel%20Screenshot.png)

And the Porous Absorber Calculator look like this:

![Porous Absorber Spreadsheet](./img/Porous%20Abs%20Excel%20Screenshot.png)

Unfortunately due to their age, these spreadsheets will only function correctly in the Windows version of Excel (sorry, Mac users...)

### Fast Forward to 2019

Having just been made redundant from my previous job and having lots of time on my hands, I decided to learn Rust &mdash; primarily because it compiles to WebAssembly.

Having completed all the simpler coding exercises, I was looking for a more real-life application to work on and decided to reimplement my Porous Absorber spreadsheet as a Web-based, WebAssembly app.  Seeing as this was my first real-life app, it took me a while to work out how to get all the pieces to fit together, but after a couple of months, I was able to get this [Web-based app](http://whealy.com/acoustics/PA_Calculator/index.html) up and running.

![Porous Absorber Web App](./img/Porous%20Abs%20Screenshot.png)


## General Architecture

The Rust app was developed in Microsoft's Visual Studio and uses the following hierarchy of Rust modules (some modules have been omitted for the sake of simplicity):

![High-level Architecture](./img/Rust%20Architecture.png)

Our objective is to create an app that runs in the browser; however, a browser cannot directly execute a native Rust application, so we need to compile the application into a format that can be executed by the browser &mdash; and this is where WebAssembly comes in.

### Compiling Rust to WebAssembly

To compile a Rust application into a WebAssembly module, you need to use a tool such as [`wasm-pack`](https://rustwasm.github.io/wasm-pack/installer/).  This tool acts as a wrapper around `cargo build` and generates a WebAssembly module (a `.wasm` file) from the compiled Rust code.

However, WebAssembly modules can be executed in a wide variety host environments.  In our case, we wish to execute this WebAssembly module in a browser, so our specific host environment will be the JavaScript runtime environment within a browser.  This therefore means that the `--target` will be `web`.

```console
$ wasm-pack build --release --target web
[INFO]: 🎯  Checking for the Wasm target...
[INFO]: 🌀  Compiling to Wasm...
   Compiling autocfg v1.0.1
   Compiling proc-macro2 v1.0.24
   Compiling unicode-xid v0.2.1
   Compiling syn v1.0.42
   Compiling log v0.4.11
   Compiling wasm-bindgen-shared v0.2.68
   Compiling serde_derive v1.0.116
   Compiling cfg-if v0.1.10
   Compiling serde v1.0.116
   Compiling bumpalo v3.4.0
   Compiling lazy_static v1.4.0
   Compiling ryu v1.0.5
   Compiling itoa v0.4.6
   Compiling serde_json v1.0.58
   Compiling wasm-bindgen v0.2.68
   Compiling arrayvec v0.4.12
   Compiling nodrop v0.1.14
   Compiling libm v0.1.4
   Compiling num-traits v0.2.12
   Compiling num-integer v0.1.43
   Compiling num-bigint v0.2.6
   Compiling num-rational v0.2.4
   Compiling num-iter v0.1.41
   Compiling num-complex v0.2.4
   Compiling num-format v0.4.0
   Compiling quote v1.0.7
   Compiling num v0.2.1
   Compiling wasm-bindgen-backend v0.2.68
   Compiling wasm-bindgen-macro-support v0.2.68
   Compiling wasm-bindgen-macro v0.2.68
   Compiling js-sys v0.3.45
   Compiling web-sys v0.3.45
   Compiling porous_absorber_calculator v1.1.0 (/Users/chris/Developer/porous_absorber)
    Finished release [optimized] target(s) in 30.72s
[INFO]: ⬇️  Installing wasm-bindgen...
[INFO]: Optimizing wasm binaries with `wasm-opt`...
[INFO]: ✨   Done in 31.46s
[INFO]: 📦   Your wasm pkg is ready to publish at /Users/chris/Developer/porous_absorber/pkg.
```

Notice to to fully compile all the crates in this particular application takes around 30 seconds; however, to recompile on the changes in the `porous_absorber` app takes only a couple of seconds.

### WebAssembly in the Browser

The addition of the `--target web` parameter tells `wasm-pack` that we wish to run the generated WebAssembly module in the browser, ans `wasm-pack` then helpfully generates a JavaScript polyfill for us.

![Generated WASM File](./img/Generated%20WASM%20File.png)

This polyfill means we don't have to write any of our own JavaScript code to interact directly with the WebAssembly module; instead, we simply `import` the JavaScript polyfill as we would any other JavaScript module.

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

