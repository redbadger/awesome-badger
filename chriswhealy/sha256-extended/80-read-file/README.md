# Step 8: Read the File

Once all the preparation has been done, reading the file using WASI is actually very straight forward.

The Rust WASI implementation of [`fd_read`](https://github.com/bytecodealliance/wasmtime/blob/06377eb08a649619cc8ac9a934cb3f119017f3ef/crates/wasi-preview1-component-adapter/src/lib.rs#L1210) can be examined if desired, but the WebAssembly call is simply this:

```wat
(call $wasi_fd_read
  (local.get $fd_file)         ;; Descriptor of file being read
  (global.get $IOVEC_BUF_PTR)  ;; Pointer to iovec
  (i32.const 1)                ;; iovec count
  (global.get $IO_BYTES_PTR)   ;; Bytes read
)
```

In this case `$IOVEC_BUF_PTR` points to a single pair of pointers and the `iovec count` argument is `1`.

If we want to read into multiple IO vector buffers, we would supply subsequent pointer pairs, and set the `iovec_count` argument appropriately.

The `i32` at `$IOVEC_BYTES_PTR` will be updated to show the number of bytes read.

Assuming the read operation is successful, we are now almost ready to start calculating the SAH256 value.

## The Special Memory Format of SHA256 Data

The coding above simply transfers the contents of a file from disk into WebAssembly's linear memory.

However, in the case of the SHA256 algorithm, the data being hashed must conform to the following requirements:

1. It must occupy an integer number of 64 byte message blocks
2. The byte immediately following the last data byte ***must*** contain `0x80`.  This insures that even an empty message can be hashed.
3. The last 8 bytes of the last block must be a 64-bit integer ***in big-endian format*** containing the number of bits (not bytes!) of data

The extra coding to perform this task is not shown here, but for the curious, you can find it in [function `$read_file`](https://github.com/ChrisWhealy/wasm_sha256/blob/27a9caa31b834fe575a50bdadcc2fcd82dd0316c/src/sha256.wat#L423) in the `sha256.wat` file.
