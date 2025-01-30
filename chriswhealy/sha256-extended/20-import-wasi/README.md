# Step 2: Import WASI Functions Into WebAssembly

In parallel with the instructions in step 1, you should also add the following statements to your WebAssembly Text program.

## 2.1) Declare Function Signature Types

Although it is not a requirement, it is more idiomatic to declare WebAssembly function signature types.
This also improves code reusability.

Both of the following sets of declarations must occur right at the start of the WAT coding.

```wat
(module
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Function types for WASI calls
  (type $type_wasi_args      (func (param i32 i32)                             (result i32)))
  (type $type_wasi_path_open (func (param i32 i32 i32 i32 i32 i64 i64 i32 i32) (result i32)))
  (type $type_wasi_fd_seek   (func (param i32 i64 i32 i32)                     (result i32)))
  (type $type_wasi_fd_io     (func (param i32 i32 i32 i32)                     (result i32)))
  (type $type_wasi_fd_close  (func (param i32)                                 (result i32)))
```

Once the function signature types have been declared, you can then declare which WASI functions need to be imported into your WAT program.

```wat
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Import OS system calls via WASI
  (import "wasi" "args_sizes_get" (func $wasi_args_sizes_get (type $type_wasi_args)))
  (import "wasi" "args_get"       (func $wasi_args_get       (type $type_wasi_args)))
  (import "wasi" "path_open"      (func $wasi_path_open      (type $type_wasi_path_open)))
  (import "wasi" "fd_seek"        (func $wasi_fd_seek        (type $type_wasi_fd_seek)))
  (import "wasi" "fd_read"        (func $wasi_fd_read        (type $type_wasi_fd_io)))
  (import "wasi" "fd_write"       (func $wasi_fd_write       (type $type_wasi_fd_io)))
  (import "wasi" "fd_close"       (func $wasi_fd_close       (type $type_wasi_fd_close)))
```

The WAT `(import)` statement creates a proxy function within WebAssembly (E.G. `$wasi_fd_seek`) that is mapped to an external WASI function (E.G. `wasi.fd_seek`).
