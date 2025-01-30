# Step 1: Start WASI in the Host Environment

***IMPORTANT***<br>
The steps described here need to happen in parallel with steps described in the next chapter. 

## 1.1) Create a WASI Instance

In our case, the host environment is a JavaScript program running within Node.js.[^1]

Inside a JavaScript module (that is a `.mjs` file), a WASI instance can be created using code similar to this:

```javascript
import { WASI } from "wasi"

const wasi = new WASI({
  args: process.argv,
  version: "unstable",
  preopens: { ".": process.cwd() }, // This directory is available as fd 3 when calling WASI path_open
})
```

In addition to creating a WASI instance, this code does two other important things:

1. The line `args: process.argv` makes the entire Node.js command line available to the WebAssembly module
2. The value of the `preopens` property is an object containing one or more directories that WASI will preopen on behalf of WebAssembly

   The property names within the object passed to `preopens` are the directory names as seen by WebAssembly.

   The property values are the directories to which we are granting WebAssembly access.

   In this case, we are granting WebAssembly access to read files in (or beneath) the directory in which we start Node.js (that is, the relative path `"."`).

## 1.2) Understanding WASI Prerequisites

The above coding is all well and good, but it will not work unless your WebAssembly module has fulfilled certain prerequisites imposed by WASI.

1. There are two ways memory can be shared between a WebAssembly module and the host environment that started it; either:
   * The WASM modules allocates some memory then shares it with the host environment using an `export` statement, or
   * The host environment allocates some memory then allows the WebAssembly module to access it via an `import` statement.
   
   WASI requires you to use the first option.
   The WebAssembly module is required to allocate some memory, then export it using the specific name `memory`.

   So in our WAT coding, we must have a statement much like this:

   ```wat
   (memory $memory (export "memory") 2)
   ```

2. WASI also expects the WebAssembly module to export a function called `_start`.
   In the host environment, you must start your WASI instance by calling `wasi.start()`, and this in turn, automatically invokes the WebAssembly function `_start`.

   ***IMPORTANT***<br>
   If such a function does not exist, then an exception will be thrown.

   If you have no need for a `_start` function, then simply declare it as a no-op function like this:

   ```wat
   (func (export "_start"))
   ```

   However, in our case, the `_start` function is needed because this is where we will implement the functionality to parse the command line arguments.

## 1.3) Instantiate the WebAssembly Module

We now create an instance of the WebAssembly module by calling `WebAssembly.instatiate`

The first argument is the contents of the `.wasm` file stored as a `Uint8Array`.

The second argument is a host environment object.
As long as the WebAssembly module knows about the property names, the properties in the environment object can have any names you like.

In this case, we are using the property name `wasi` and setting its value to be the entire set of operating system functions exposed via the `wasiImports` object.

```javascript
let { instance } = await WebAssembly.instantiate(
  new Uint8Array(readFileSync(pathToWasmMod)),
  {
    wasi: wasi.wasiImport
  },
)
```

This grants the WebAssembly module access to all the operating system calls listed in the `.wasiImport` object.

## 1.4) Use WASI to Start the WebAssembly Module Instance

After we have waited for the `instance` to be created, the last step is to use `wasi` to start the WASM module:

```javascript
wasi.start(instance)
```

Since this whole process is asynchronous, the finished JavaScript module to start the WebAssembly module will look much like this:

```javascript
import { readFileSync } from "fs"
import { WASI } from "wasi"

const startWasm =
  async pathToWasmMod => {
    //  Define WASI environment
    const wasi = new WASI({
      args: process.argv,
      version: "unstable",
      preopens: { ".": process.cwd() }, // This directory is available as fd 3 when calling WASI path_open
    })

    let { instance } = await WebAssembly.instantiate(
      new Uint8Array(readFileSync(pathToWasmMod)),
      {
        wasi: wasi.wasiImport,
      },
    )

    wasi.start(instance)
  }

await startWasm("./bin/sha256_opt.wasm")
```

[^1]: In Node.js versions 18 and higher, the WASI interface is available by default.  In versions from 12 to 16, WASI will only be available if you start `node` with the flag `--experimental-wasi-unstable-preview1`
