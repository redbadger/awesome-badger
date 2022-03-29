# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [Creating a WebAssembly Module](../02/) | [Up](/chriswhealy/introduction-to-web-assembly-text) | [WAT Datatypes](../04/)

## 3: Using a Language Runtime as a WebAssembly Host Environment

Now that we can call our slightly-less-useless WebAssembly module from the command line, let's look at calling it from a JavaScript program.  In other words, we're now going to use JavaScript as the WebAssembly host environment.

### Create a `.wasm` file

When using `wasmer` as the host environment, behind the scenes it performed two tasks.  It:

1. Compiled the `.wat` file into a `.wasm` file, then
1. Executed the `.wasm` file

However, when a language runtime such as JavaScript acts as the host environment, these two tasks are typically performed at different times in the development process.

So first, we need to assemble the WebAssembly Text file into a `.wasm` file.  To do this, change into the same directory as the `.wat` file, then invoke the `wat2wasm` tool:

```bash
wat2wasm 02-slightly-less-useless.wat
```

This now creates a `.wasm` file that is a mere 39 bytes in size.

Since there are some implementation differences between a server-side JavaScript environment and a browser-based JavaScript environment, it is necessary to provide two versions of the following example.

### Using JavaScript (NodeJS) as the WebAssembly Host Environment

As a prerequisite for using NodeJS, we must first create a `package.json` file containing the single line:

```json
{ "type": "module" }
```

Next, we need to create a JavaScript program that does the following:

1. Synchronously read the contents of the `.wasm` file into a constant called `wasmBin`
1. Create an executable instance of the `.wasm` file using `WebAssembly.instantiate()`
1. Using the `wasmObj`'s `instance` property, we can call the `answer` function via the `exports` property.

[03-wasm-host-env.js](/assets/chriswhealy/03-wasm-host-env.js)
```javascript
import { readFileSync } from 'fs'

const start = async () => {
  const wasmBin = readFileSync('./02-slightly-less-useless.wasm')
  const wasmObj = await WebAssembly.instantiate(wasmBin)

  console.log(`Answer = ${wasmObj.instance.exports.answer()}`)
}

start()
```

Open a command line and run the above program using NodeJS

```bash
node 03-wasm-host-env.js
Answer = 42
```

### Using JavaScript (Browser) as the WebAssembly Host Environment

If we now want to run the same WebAssembly module in a browser, we must make the following changes.

Create an HTML file containing the following code:

```html
<!DOCTYPE html>
<html>
<script>
  const start = async () => {
    const wasmObj = await WebAssembly.instantiateStreaming(fetch('./02-slightly-less-useless.wasm'))

    console.log(`Answer = ${wasmObj.instance.exports.answer()}`)
  }

  start()
</script>

</html>
```

Place this file in under your local webserver's document root directory and display it through the browser.  In the developer tools, you will see `Answer = 42` in the console.

***IMPORTANT TECHNICAL DETAILS***

1. For security reasons, browsers will not open `.wasm` files using the `file://` protocol.  This means therefore that the web page within which your JavaScript coding executes cannot be opened simply by pointing your browser at the `.html` file in your local file system.  Any Web page containing a WebAssembly module **must** be supplied to the browser using your local Web Server.

1. Your local Web Server must be correctly configured to add the `application/wasm` MIME type to a `.wasm` file.

   For example on a macOS machine, ensure that the file `/private/etc/apache2/mime.types` contains the line <code>application/wasm&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;wasm</code>

1. If you are developing a JavaScript program that uses Web Workers to create multiple instances of the same WebAssembly module, then your local Web Server must additionally be configured to include the following HTTP headers:

   ```
   Cross-Origin-Embedder-Policy: require-corp
   Cross-Origin-Opener-Policy: same-origin
   ```

   If you are using Apache as your WebServer, then the `<Ifmodule headers_module>` section of `httpd.conf` should contain at least these directives:

   ```conf
   <IfModule headers_module>
       Header set Cross-Origin-Embedder-Policy "require-corp"
       Header set Cross-Origin-Opener-Policy "same-origin"
    </IfModule>
   ```

Let's now take a more detailed look at how to write a useful WebAssembly Text program.
