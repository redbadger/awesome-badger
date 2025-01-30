# Debugging WASM Functions

This is one area where development in WebAssembly Text seriously lacks developer tools.

The bulk of the JavaScript coding accompanying this WASM module exists simply to provide a test framework through which individual WASM functions can be tested and debugged.

There is another JavaScript module called `dev_sha256sum.mjs` that was used during development.
This includes extra functionality for performance tracing and logging.
If you wish to use this version and make use of the logging functionality, you will first need to uncomment the `(import ...)` statements at the start of `./src/sha566.wat` and then recompile the WASM module.

## Create One or More Logging Functions

In order to debug a function in the WASM module, the easiest way I have found has been to pass a logging function in the JavaScript host environment object:

```javascript
let { instance } = await WebAssembly.instantiate(
  new Uint8Array(readFileSync(pathToWasmFile)),
  {
    wasi: wasi.wasiImport,
    log: { "msg": logWasmMsg },
  },
)
```

Since I wanted to output value from many different places in the WebAssembly program, I found it helpful to create two arbitrary lists:
1. A list of the step (or function) names within the WebAssembly module
2. A list of stages within each function

The names of the steps and their corresponding step details are entirely arbitrary, but in my case, they look like this:

```JavaScript
const stepNames = new Map()
stepNames.set(0, "WASM: path_open - ")
stepNames.set(1, "WASM: fd_seek - ")
stepNames.set(2, "WASM: memory.grow - ")
stepNames.set(3, "WASM: fd_read - ")
stepNames.set(4, "WASM: msg_blocks  - ")

//snip
```

```JavaScript
const stepDetails = new Map()
stepDetails.set(0, "return code  = ")
stepDetails.set(1, "fd  = ")
stepDetails.set(2, "file size  = ")
stepDetails.set(3, "memory.size  = ")
stepDetails.set(4, "bytes read  = ")
stepDetails.set(5, "iovec.buf_addr  = ")
stepDetails.set(6, "iovec.buf_len  = ")

// snip
```

The `logWasmMsg` JavaScript function referred to in the host environment object above then needs to be passed three `i32` arguments and looks like this:

```JavaScript
const logWasmMsg = (step, msg_id, some_val) =>
  console.log(`${stepNames.get(step)}${stepDetails.get(msg_id)}${some_val}`)
```

That is then imported by the WebAssembly module:

```wat
(module
  ;; Import log functions
  (import "log" "msg" (func $log_msg (param i32 i32 i32)))

  ;; snip
)
```

Anytime I need to see what value a WASM function is working with, I call the function `$log_msg` passing in the step number, step detail number and the value to be logged.
That value is then written to the console along with the relevant description.

E.G. The log message for step 3, step detail 4 will display the number of bytes read by `fd_read`:

```wat
(call $log_msg (i32.const 3) (i32.const 4) (global.get $IO_BYTES_PTR))
```

This then produces

```
WASM: fd_read - bytes read = 3278509
```