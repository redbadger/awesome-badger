# Architecture

The architecture of the WebAssembly part of this program is laid out in the following block diagram:

![block diagram](/chriswhealy/sha256/img/sha256.png)

This diagram uses [Jackson Structured Programming](https://en.wikipedia.org/wiki/Jackson_structured_programming) to show a sequence of steps (pale yellow boxes) and an iteration of steps (the blue boxes).

The instructions in the child boxes underneath each blue box will be repeated as many times as required, until the condition in the blue box becomes false.
