# Introduction to WebAssembly Text
<table style="table-width: fixed; width: 100%">
<tr><th style="width: 45%">Previous</th>
    <th style="width: 10%"></th>
    <th style="width: 45%">Next</th></tr>
<tr><td style="text-align: center"><a href="./02%20WebAssembly%20Module.md">WebAssembly Module</a></td>
    <td style="text-align: center"><a href="./README.md">Top</a></td>
    <td style="text-align: center"><a href="./04%20WAT%20Datatypes.md">WAT Datatypes</a></td></tr>
</table>

## 3: Calling WebAssembly from a Host Environment

Now that we have a slightly less useless WebAssembly module that we can call from the command line, let's now look at using JavaScript to act as the host environment for this module.

### Create a `.wasm` file

When working from the command line, we used the `wasmer` tool to both compile and run the WebAssembly module in a single step.  Now we need simply compile the WebAssembly Text file and ensure that the generated `.wasm` file is accessible to our JavaScript runtime environment.

To compile the WebAssembly Text file, change into the same directory as the `.wat` file, then invoke the `wat2wasm` tool:

```bash
wat2wasm 02-slightly-less-useless.wat
```

This now creates a `.wasm` file that is a mere 39 bytes in size.

### Create a WebAssembly Host Environment in JavaScript

[03-wasm-host-env.js](./src/03-wasm-host-env.js)
```javascript
import { readFileSync } from 'fs'

const start = async () => {
  const wasmBin = readFileSync('./02-slightly-less-useless.wasm')
  const wasmObj = await WebAssembly.instantiate(wasmBin)

  console.log(`Answer = ${wasmObj.instance.exports.answer()}`)
}

start()
```

Here, we create an asynchronous function called `start` that does the following things:

1. Synchronously read the contents of the `.wasm` file into a constant called `wasmBin`
1. Pass the contents of the `.wasm` file to `WebAssembly.instantiate()`.  This will asynchronously create a WebAssembly object
1. After we've waited for the WebAssembly object to be created, using the `instance` property, we can call the `answer` function via the `exports` property.

Open a command line and run the above program using NodeJS

```bash
node 03-wasm-host-env.js 
Answer = 42
```

> ***IMPORTANT***
> In this example, our Host Environment was written in JavaScript and then invoked using NodeJS.
>
> Should you wish to run this JavaScript from within a browser, you must be aware of the following differences and restrictions:
> 
>  1. Remove the `import` statement and replace the call to `readFileSync()` with an `await` call to `fetch()`
>  1. For security reasons, browsers will not open `.wasm` files using the `file://` protocol.  This means therefore that the web page within which your JavaScript coding executes cannot be opened simply by pointing your browser at the `.html` file in your local file system.  The Web page **must** be supplied to the browser using your local Web Server.
>  1. Your local Web Server must be correctly configured to transfer `.wasm` files using the MIME type `application/wasm`
>  1. If you are developing a JavaScript program that uses Web Workers to create multiple instances of the same WebAssembly module, then your local Web Server must be additionally configured to include the following HTTP headers:
>     ```
>    Cross-Origin-Embedder-Policy: require-corp  
>    Cross-Origin-Opener-Policy: same-origin
>     ```

Let's now take a more detailed look at how to write a useful WebAssembly Text program.