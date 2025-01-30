# Step 3: Count the Command Line Arguments

One of the properties in the host environment object is called `args` and has the value `process.argv`.
This makes the entire command line received by NodeJS available to the WASM module.

In the WASM function `_start`, we must first determine how many arguments we have received by calling the WASI function `args_sizes_get`.

This function is imported into WebAssembly at the start of the module and is known internally as `$wasi_args_sizes_get`:

```wat
(type $type_wasi_args (func (param i32 i32) (result i32)))
(import "wasi" "args_sizes_get" (func $wasi_args_sizes_get (type $type_wasi_args)))
```

## 3.1) Take a look at the Rust `wasmtime` implementation

In order to understand how to interact with this function, it is helpful to look at the Rust coding that implements the WASI function [`args_sizes_get()`](https://github.com/bytecodealliance/wasmtime/blob/06377eb08a649619cc8ac9a934cb3f119017f3ef/crates/wasi-preview1-component-adapter/src/lib.rs#L506)

Here, you see the following Rust function signature:

```rust
pub unsafe extern "C" fn args_sizes_get(argc: *mut Size, argv_buf_size: *mut Size) -> Errno
```

If this function call is successful, you get back an error number of `0` that can be ignored by calling `drop`.

## 3.2) Call `args_sizes_get`

Whenever you call a WASI function, you will (almost always) need to pass one or more pointers; however, to avoid hardcoding memory addresses into function calls, the following global pointers have been declared:

```wat
(global $ARGS_COUNT_PTR     i32 (i32.const 0x000004c0))
(global $ARGV_BUF_SIZE_PTR  i32 (i32.const 0x000004c4))
```

Then, when we call WASI functions, we always reference these global values:

The WASI function then performs its processing and returns information to the calling program by writing that data to the memory locations identified by the pointers.

```wat
;; How many command line args have we received?
(call $wasi_args_sizes_get (global.get $ARGS_COUNT_PTR) (global.get $ARGV_BUF_SIZE_PTR))
drop
```

The actual return value of the function call is used only for error handling.
Here, we have assumed that `args_sizes_get` always gives a return code of zero, so we arbitrarily `drop` the value left on the stack.

![Calling `args_sizes_get`](/chriswhealy/sha256-extended/img/args_sizes_get.png)

We store the values returned by WASI by loading the `i32` values found at the addresses stored in these pointers:

```wat
;; Remember the argument count and the total length of arguments
(local.set $argc          (i32.load (global.get $ARGS_COUNT_PTR)))
(local.set $argv_buf_size (i32.load (global.get $ARGV_BUF_SIZE_PTR)))
```

For this command line:

```bash
node sha256sum.mjs ./tests/war_and_peace.txt
```

We get back the value `3` for `argc`; however, the value returned for `argv_buf_size` is much longer than the string value shown above would lead us to believe.
This is because the program name `node` and file name `sha256sum.mjs` have both been expanded to their fully qualified names.

Hence, the value of `argv_buf_size` is actually `0x83` (131 characters)

***IMPORTANT***<br>
The string length of 131 also includes a null terminator character (`0x00`) at the end of each argument.
This must be accounted for when calculating argument lengths.