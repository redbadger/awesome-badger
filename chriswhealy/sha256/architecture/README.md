# Architecture

| Previous | [Top](/chriswhealy/sha256-webassembly) | Next
|---|---|---
| [WebAssembly Does Not Have A "raw binary" Data Type](/chriswhealy/sha256/endianness/) | WebAssembly Program Architecture | [WebAssembly Implementation](/chriswhealy/sha256/implementation/)

## Structure Diagram

The architecture of the WebAssembly part of this program is laid out in the following block diagram:

[![block diagram](/chriswhealy/sha256/img/sha256.png)](/chriswhealy/sha256/img/sha256.png)

The program structure is illustrated using [Jackson Structured Programming](https://en.wikipedia.org/wiki/Jackson_structured_programming) where a sequence of steps is shown by the pale yellow boxes, and an iteration of steps is shown by the blue boxes.

The instructions in the child boxes underneath each blue box will be repeated as many times as required, until the condition in the blue box becomes false.
