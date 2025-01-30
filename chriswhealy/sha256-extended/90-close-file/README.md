# Step 9: Close the File

We could omit this step and let WASI clean up any open files when it terminates; however, it's better to play by the rules and close the file as soon as we know it is no longer needed.

Closing a file using WASI is simply a matter of passing the open file descriptor to `fd_close` and typically, ignoring the return code.

```wat
(call $wasi_fd_close (local.get $fd_file))
drop
```