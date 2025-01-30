# Step 7: Do We Have Enough Memory?

Right at the start of the program, we covered the requirements that WASI places on a WebAssembly module.
One of those requirements was that the WASM module must export its memory using the name `memory`.

At the start of our program, we allocated 2, 64Kb pages of memory and exported them using the name `memory`.

```wat
;; WASI requires the WASM module to export memory using the name "memory"
(memory $memory (export "memory") 2)
```

For safety, it is wise to keep the first memory page completely separate for the SHA256 calculation, and start writing the file data at the start of page 2.
This means that as the memory allocation currently stands, only the 64Kb of memory in page 2 is available for file data.

The first thing to calculate therefore is the size difference between the amount of memory currently available (64Kb) and the size of the file.

```wat
;; size_diff = FILE_SIZE - ((Memory pages - 1) * 64Kb)
(local.set $size_diff
  (i64.sub
    (local.get $file_size_bytes)
    (i64.shl
      ;; Subtract 1 because the first memory page is not available for file data
      (i64.extend_i32_u (i32.sub (memory.size) (i32.const 1)))
      (i64.const 16)
    )
  )
)
```

There are a couple of things to be careful of here:

* The first memory page is reserved for SHA256 calculation values, so this must not be counted as available space.
* The local variable `$file_size_bytes` is an `i64`, but WebAssembly uses `i32`'s to address memory.
  This means firstly that WebAssembly cannot process a file larger than 4Gb; and secondly, that we need to extend the `i32` values so that they can be treated as `i64`s

If the `$size_diff` variable is greater than zero, then we need to calculate how many memory pages will be needed and then call `memory.grow`

```wat
;; Is more memory needed?
(if
  (i64.gt_s (local.get $size_diff) (i64.const 0))
  (then
    (memory.grow
      ;; Only rarely will the file size be an exact multiple of 64Kb, so arbitrarily add an extra memory page
      (i32.add
        ;; Convert the size difference to 64Kb message pages
        (i32.wrap_i64 (i64.shr_u (local.get $size_diff) (i64.const 16)))
        (i32.const 1)
      )
    )
    drop  ;; Don't care about previous number of memory pages
    ;; (call $log_msg (i32.const 2) (i32.const 3) (memory.size))
  )
  ;; (else
  ;;   (call $log_msg (i32.const 2) (i32.const 7) (memory.size))
  ;; )
)
```

Again here, we must be careful to convert an `i64` back to an `i32` before passing its value to `memory.grow`.

During development, I was logging the number of new memory pages using `(call $log_msg ...)` statements.
These have been commented out rather than deleted.

Only now do we have enough memory to read the file successfully!

***But***, before we do that, we must prepare the IO vector buffer used by `fd_read`.

The IO vector buffer is just a fancy name for a pair of pointers.
This buffer can live anywhere in memory where you have 8 bytes of free storage; so in our case, I have decided to store these two pointers at memory address `0x10`, hence the declaration:

```wat
(global $IOVEC_BUF_PTR      i32 (i32.const 0x00000010))
(global $IO_BYTES_PTR       i32 (i32.const 0x00000018))
```

The global declaration of `$IO_BYTES_PTR` is to point to the address at which `fd_read` will write the number of bytes it has just read.

Irrespective of whether we needed to grow memory, the following block of code must always be performed.

```wat
;; Prepare the iovec buffer based on the new memory size
;; iovec data structure is 2, 32-bit words
;; File data starts at $IOVEC_BUF_ADDR
;; Buffer length stored at $IOVEC_BUF_PTR + 4
(i32.store (global.get $IOVEC_BUF_PTR) (global.get $IOVEC_BUF_ADDR))
(i32.store
  (i32.add (global.get $IOVEC_BUF_PTR) (i32.const 4))
  ;; Buffer length = (memory.size - 1) * 65536
  (i32.shl (i32.sub (memory.size) (i32.const 1)) (i32.const 16))
)
```

The first `$IOVEC_BUF_PTR` pointer points to the address at which the file data will be written.
In our case we have arbitrarily decided that all file data will be written to the start of the second 64Kb memory page; so that equates to memory address `0x00010000` (or 65536 in decimal)

The second pointer (living at `$IOVEC_BUF_PTR + 4`) holds the size in bytes of the buffer into which `fd_read` can write.
In our case, this equates to the number of memory pages minus 1 multiplied by 64Kb.

Now (finally) we are ready to read the file.
