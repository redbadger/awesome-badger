# Step 6: Read the File Size

When using WASI, the simplest way to read a file's size is to seek to the end of the file, then make a record of how many bytes have been passed over.

After performing a seek-to-the-end operation, the file pointer must be reset to the start of the file, otherwise any subsequent attempts to read from the file will return nothing, as we've already hit end-of-file.

The Rust WASI implementation of [`fd_seek`](https://github.com/bytecodealliance/wasmtime/blob/06377eb08a649619cc8ac9a934cb3f119017f3ef/crates/wasi-preview1-component-adapter/src/lib.rs#L1550) looks like this:

```rust
pub unsafe extern "C" fn fd_seek(
    fd: Fd,
    offset: Filedelta,
    whence: Whence,
    newoffset: *mut Filesize,
) -> Errno
```

1. The file descriptor `fd` is the one we've just created by calling `$wasi_path_open`.
1. The `offset` is set to zero to ensure we start reading from the beginning of the file.
1. `whence` is set to `2` which means `end-of-file`.
1. `newoffset` points to the memory location where the file size will be written

So seeking to the end of the file is simple enough:

```wat
(call $wasi_fd_seek
  (local.get $fd_file)
  (i64.const 0)  ;; Offset
  (i32.const 2)  ;; Whence = END
  (global.get $FILE_SIZE_PTR)
)
```

We then store the file size in a local variable:

```wat
(local.set $file_size_bytes (i64.load (global.get $FILE_SIZE_PTR)))
```

If we stopped at this point, we would have obtained the file's size, but we would also have left the file descriptor pointing to the end of the file.

So we must now reset the file pointer by calling `fd_seek` again, but this time `whence` is set to `0` meaning `start-of-file`

```wat
(call $wasi_fd_seek
  (local.get $fd_file)
  (i64.const 0)  ;; Offset
  (i32.const 0)  ;; Whence = START
  (global.get $FILE_SIZE_PTR)
)
```

However, the global pointer `$FILE_SIZE_PTR` has points to a memory address containing zero; so we must either remember never to read from that location again, or just to be safe, we must update the address pointed to by `$FILE_SIZE_PTR` with the file's actual size:

```wat
;; Write file size back at the expected location
(i64.store (global.get $FILE_SIZE_PTR) (local.get $file_size_bytes))
```

Now that we know how big the file is, we are now in a position to decide whether it will fit in the current memory allocation.
