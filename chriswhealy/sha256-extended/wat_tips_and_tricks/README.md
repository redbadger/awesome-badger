# WebAssembly Text Programming Tips and Tricks

Whenever I write a program directly in WebAssembly Text, I have found the following tips and tricks make life a lot easier.

## 1) Always Write Out a Memory Map

If you do not keep very careful track of what values live at what memory location and how long they are, you might easily find your coding has trampled all over its own data!

In this example, I have mapped out the start of the memory in page 1 as follows

```wat
;; Memory Map
;;             Offset  Length   Type    Description
;; Page 1: 0x00000000       4   i32     file_fd
;;         0x00000004       4           Unused
;;         0x00000008       8   i64     fd_seek file size + 9
;;         0x00000010       8   i32x2   Pointer to iovec buffer, iovec buffer size
;;         0x00000018       8   i64     Bytes transferred by the last io operation
```

## 2) Never Hard Code memory Offsets

Any time you need to reference an explicit memory offset, never hardcode such values in the coding because this will rapidly become unmanageable when (not if!) you decide to rearrange the memory layout.

So the locations shown in the memory map above have the following corresponding global declarations:

```wat
(global $FD_FILE_PTR        i32 (i32.const 0x00000000))
(global $FILE_SIZE_PTR      i32 (i32.const 0x00000008))
(global $IOVEC_BUF_PTR      i32 (i32.const 0x00000010))
(global $IO_BYTES_PTR       i32 (i32.const 0x00000018))
```

Now, whenever you want to access a value in memory, you can do so via a named pointer.

## 3) Don't Trample on Your Own Memory!

Although a WebAssembly module is completely sandboxed (making it completely impossible to write to a memory location outside the module's scope), you have unlimited access to any and all locations within your own memory.
This means that there are no bounds checks for reading or writing values!

Therefore, if you aren't ***very*** careful to check the length of the data you're reading or writing, you could easily corrupt your own data.

In other words, there is the potential to make a big mess very quickly.

## 4) Create One or More Log Functions in the Host Environment

During development, it is very useful for the host environment to provide your WASM module with one or more log functions.
These can then be imported and called from various locations in your WebAssembly program to help you trace the values currently passing through your WASM functions.

See the page on [Debugging WASM](/chriswhealy/sha256-extended/debugging_wasm/README.md) for more details.
