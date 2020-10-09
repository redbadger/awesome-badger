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

Having just been made redundant from my previous job and having lots of time on my hands, I decided to learn Rust &mdash; primarily because it compiles to WebAssembly.  After completing the simpler coding exercises, I needed a more real-life application to work on and decided to reimplement my Porous Absorber spreadsheet as a Web-based, WebAssembly app.  Seeing as this was my first real-life app, it took me a while to work out how to get all the pieces to fit together, but after a couple of months of battling my own inexperience, I was able to get this Web-based app up and running.

[![Porous Absorber Web App](./img/Porous%20Abs%20Screenshot.png)](http://whealy.com/acoustics/PA_Calculator/index.html)


## General Architecture

The app was developed in Microsoft's Visual Studio and uses the following hierarchy of Rust modules (for the sake of simplicity, some modules have been omitted):

![High-level Architecture](./img/Rust%20Architecture.png)

The objective here was to create an app that runs in the browser; however, since a browser cannot directly execute a native Rust application, it must first be compiled into a format that a browser can execute &mdash; and this is where WebAssembly comes in.

### Compiling Rust to WebAssembly

To compile a Rust application into a WebAssembly module, you need to use a tool such as [`wasm-pack`](https://rustwasm.github.io/wasm-pack/installer/).  This tool acts as a wrapper around `cargo build` and generates a WebAssembly module (a `.wasm` file) from the compiled Rust code.

However, WebAssembly modules can be executed in a wide variety host environments.  In our case, we wish to execute this WebAssembly module in a browser, so our specific host environment will be the JavaScript runtime environment within a browser.  This therefore means that the `--target` parameter of `wasm-pack` must be set to `web`.

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

The polyfill acts as a wrapper around the WebAssembly module and enables us to use the JavaScript `import` statement as we would for any other JavaScript module.

This makes consumption of WebAssembly-based functionality super-easy.

```javascript
import init
, { porous_absorber
  , slotted_panel
  , perforated_panel
  , microperforated_panel
} from '../pkg/porous_absorber_calculator.js'
```

## How to Start?

### Declare a Rust Library Project

Given that this type of application is going to run within the context of some larger host environment, you start by creating a Rust library project:

```console
$ cargo new --lib some_project
     Created library `some_project` package
```


### Declare a Dependency on `wasm-bindgen`


When writing a Rust application for WebAssembly, the first thing to do is declare a dependency on the [`wasm-bindgen`](https://rustwasm.github.io/docs/wasm-bindgen/introduction.html) crate.  As with all Rust dependencies, this declaration is made in your project's `Cargo.toml` file:

```toml
[dependencies.wasm-bindgen]
version = "^0.2"
features = ["serde-serialize"]
```

In addition to stating our dependency on the `wasm-bindgen` crate, the above statement additionally declares the use of the optional create feature `serde-serialize` (this feature will be needed when transferring information to and from JavaScript)

Now that this basic dependency has been stated, we can start to write some Rust coding that is intended for invocation from the WebAssembly host environment.

### Define the Entry Points Visible to the WebAssembly Host Environment

In the top-level `./src/lib.rs` file, we need to declare at least one function to act as the entry point for code running in the host environment.

In the case of this Porous Absorber Calculator app, there are four entry points - one for each type of absorption device:

* Porous Absober
* Slotted Panel Absorber
* Perforated Panel Absorber
* Microperforated Panel Absorber

So in `./src/lib.rs` we define normal public Rust functions, but precede them with the `#[wasm-bindgen]` macro:

```Rust
#[wasm_bindgen]
pub fn porous_absorber(wasm_arg_obj: JsValue) -> JsValue {
  do_porous_absorber_device(wasm_arg_obj)
}
```

This macro identifies a function as an entry point.  In other words, we're using this macro to construct the WebAssembly module's public API.

There are a couple of things to notice here:

1. Whatever name is used by the public Rust function appears as the name seen in the JavaScript `import` statement shown above.
1. The `porous_absorber` function takes a single argument of type `JsValue` and returns a result that is also of type `JsValue`.

#### So, What Values are of Type `JsValue`?

At the moment, the datatype `JsValue` is something of an untyped-type and does not exist as a specific datatype in Rust.  The actual transfer of data between Rust and the JavaScript host environment happens in the generated JavaScript coding.

Suffice it to say, when you call the exposed `porous_absorber` function from JavaScript, all you need to do is pass in a regular JavScript object.  Then, when the data arrives on the Rust side of the interface, you will receive a serialized JSON object as a text string.

This value must first be de-serialized into a Rust struct whose fields are all of type `String`.  Then if necessary, each `String` value must be parsed into the relevant Rust data type.

In the case of the `porous_absorber` function, this passes the `wasm_arg_obj` parameter stright through to function `do_porous_absorber_device` which does the following.

First the JSON string is deserialized into a predefined struct whose fields are all of type `String`:

```Rust
#[derive(Deserialize)]
struct PorousAbsorberArgs {
  absorber_thickness_mm: String,
  flow_resistivity: String,
  air_gap_mm: String,
  angle: String,
  graph_start_freq: String,
  smooth_curve: String,
  subdivision: String,
  show_diagram: String,
  air_temp: String,
  air_pressure: String,
}

pub fn do_porous_absorber_device(wasm_arg_obj: JsValue) -> JsValue {
  // Parse object received from JavaScript
  let arg_obj: PorousAbsorberArgs = wasm_arg_obj.into_serde().unwrap();

  // SNIP
}
```

We now have an `arg_obj` struct in which each of the individual values are `Strings` that next need to be parsed to the internal data type.  So for instance, when used in calculations, the `absorber_thickness_mm` argument is needed as a `u16` value, so whe next have the statement:

```Rust
  let absorber_thickness_mm = arg_obj.absorber_thickness_mm.parse::<u16>().unwrap();
```

Similarly, when we wish to send data back to JavaScript, the return value of type `JsValue` is created by passing our Rust struct through `JsValue::from_serde().unwrap()`.




Chris W

[![Red Badger Logo - Small](./img/Red%20Badger%20Small.png)](https://red-badger.com/)

