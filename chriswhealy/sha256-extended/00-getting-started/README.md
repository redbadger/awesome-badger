# Getting Started With WASI File IO

If a WebAssembly program needs to interact with the filesystem, it can only do so using the interface provided by WASI.
In addition to this, the level of file system interaction provided by WASI exists at a lower level than you might be used to when working in a high level language such as Python or JavaScript.

## Understanding WebAssembly Sandboxing

All WebAssembly programs run within their own isolated sandbox.
This not only prevents the WebAssembly program from damaging areas of memory that belong to other programs, but it also prevents the WASM program from making inappropriate operating system calls such as accessing the filesystem or the network.

However, there are many situations in which it is perfectly appropriate for a WebAssembly program to interact with the operating system.
In this case, our WebAssembly program has a legitimate need to read a file from disk.

This is one of the areas in which WASI bridges the gap between the isolated world of WebAssembly and the "outside world", so to speak.

## File IO from WebAssembly

Broadly speaking, the following steps are needed for a WebAssembly program to read a file into memory:

1. Obtain a file descriptor to the target directory
2. Call `path_open` to open the file
3. Discover how large the file is by calling `fd_seek` and reading to the end of the file
4. Call `fd_seek` a second time to reset the file IO pointer back to the start of the file
5. Based on the size of the file, it may be necessary to allocate more WebAssembly memory by calling `memory.grow`
6. Now that we know we have sufficient space, call `fd_read` to read the file into memory
7. Finally, close the file by calling `fd_close`

The key point to understand here, is that WebAssembly ***cannot*** create its own file descriptors.
This step ***must*** be done for it by the WASI interface running in the host environment.

This means that the host environment retains complete control over the files a WebAssembly program is permitted to access.

## Standard File Descriptors

A file descriptor is simply a small integer that acts as a handle to some object in the file system: typically a file or a directory.
When a WebAssembly program starts, the host environment automatically makes three file descriptors available to it.

* fd `0` = Standard in (`stdin`)
* fd `1` = Standard out (`stdout`)
* fd `2` = Standard error (`stderr`)

Any other files needed by the WebAssembly program will be identified by file descriptor `3` and higher.
It is usual (but not a requirement) for file descriptors to be created in sequential order.
