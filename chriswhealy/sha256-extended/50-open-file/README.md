# Step 5: Open the File

Opening a file using WASI means calling the `path_open` function.
This function takes quite a few arguments, so it is first worth looking at the WASI Rust implementation of [`path_open`](https://github.com/bytecodealliance/wasmtime/blob/06377eb08a649619cc8ac9a934cb3f119017f3ef/crates/wasi-preview1-component-adapter/src/lib.rs#L1819) to get an idea of what information we need to supply.

The Rust function signature looks like this:

```rust
pub unsafe extern "C" fn path_open(
    fd: Fd,
    dirflags: Lookupflags,
    path_ptr: *const u8,
    path_len: usize,
    oflags: Oflags,
    fs_rights_base: Rights,
    fs_rights_inheriting: Rights,
    fdflags: Fdflags,
    opened_fd: *mut Fd,
) -> Errno
```

A successful call to this function returns a file descriptor with the correct capabilities.[^1]
If we get the capability flags wrong, then the resulting file descriptor will still point to an open file, but we are likely to get back `Errno = 76` (Not capable) when trying to perform our required operations.

1. `fd`: The first argument is the file descriptor of the directory in (or below) which we expect to find the file we want to open.
   In our case, this is file descriptor `3` that WASI pre-opened for us.
2. `dirFlags`: We can pass zero here because we are not interested in following symbolic links
3. `path_ptr`: A pointer to the file pathname &mdash; in our case, this is the pointer to `$arg3`
4. `path_len`: The length of the path name that we have just calculated (`25` in our case)
5. `oflags`: A set of flags that determine whether we are opening a file or a directory, and what should happen if that object either does or does not already exist.
6. `fs_rights_base`: These are the capability flags assigned to the file descriptor.
7. `fs_rights_inheriting`: Inherited capability flags that we can ignore.
8. `fdflags`: A set of flags that describe the manner in which data is written to the file
9. `opened_fd`: A pointer to the file descriptor that `path_open` will create

The WebAssembly coding looks like this:

```wat
(call $wasi_path_open
  (local.get $fd_dir)        ;; fd of preopened directory
  (i32.const 0)              ;; dirflags (no special flags)
  (local.get $path_offset)   ;; path (pointer to file path in memory)
  (local.get $path_len)      ;; path_len (length of the path string)
  (i32.const 0)              ;; oflags (O_RDONLY for reading)
  (i64.const 6)              ;; Base rights (RIGHTS_FD_READ 0x02 OR'ed with RIGHTS_FD_SEEK 0x04)
  (i64.const 0)              ;; Inherited rights
  (i32.const 0)              ;; fs_flags (O_RDONLY)
  (global.get $FD_FILE_PTR)  ;; Write new file descriptor here
)
```

The only flags that we need to specify are the base rights.
Here we must switch on bit 2 for "read capability" and bit 3 for "seek capability", which are OR'ed together to give 6.

Assuming that we are allowed to open this file, we will get back a new file descriptor that can be saved in a local variable as follows:

```wat
;; Pick up the file descriptor value
(local.set $fd_file (i32.load (global.get $FD_FILE_PTR)))
```

Although the file we want to read is now open, we cannot yet start reading from it.
First we must check that our WebAssembly module has sufficient memory allocated to it.

[^1]: Capabilities are a set of actions that the program is allowed to perform on a file.  For example, whether you can write to that file, whether you can perform a seek operation, or whether your write operation is allowed to extend the current size of the file, etc.
