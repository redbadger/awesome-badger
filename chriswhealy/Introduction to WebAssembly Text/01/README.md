# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [Prerequisites](../00/) | [Up](/chriswhealy/introduction-to-web-assembly-text) | [Creating a WebAssembly Module](../02/)

## 1: Benefits of WebAssembly

As of late 2021, WebAssembly is the new kid on the block that is being touted as the answer to a wide variety of computing problems.  Hype aside, WebAssembly does offer a great starting point for solving many computing problems that have previously only been partially solved, or worse still, inadequately solved.

Chief among these benefits is the fact that when packaged as a WebAssembly module, a server can have a much higher degree of confidence regarding the safety of running that code.  Arbitrary units of code can now be executed without worrying whether they contain anything that might attempt to perform externally malicious acts.  WebAssembly has achieved this by adopting the following design principles:

1. ***No Stand-Alone Execution***

   A WebAssembly program cannot run stand-alone; it must be instantiated and then invoked by some host environment.  At the moment, the available host environments are either:
   1. A language runtime such as JavaScript or Rust etc.  In this case, the `.wasm` module is instantiated and invoked by coding written in the host language; or
   1. A WebAssembly System Interface ([WASI](https://wasi.dev/)) such as the one provided by [wasmer](https://wasmer.io).  A WASI allows you to treat a WebAssembly program as if it were a stand-alone program without jeopardising any of the inherent safety features.<br>

1. ***Minimal Instruction Set***

   By design, the functionality offered by the [WebAssembly instruction set](https://pengowray.github.io/wasm-ops/) is very minimal.  For instance, there are no WebAssembly instructions for interacting with the "operating system" level resources such as the network, the file system or the sytem clock.

1. ***Access By Request Only***

   Due to these built-in limitations, a WebAssembly program must, by design, declare to its host environment that it needs access to other system resources or functionality.  Since the host environment now knows exactly which external functionality the module will invoke, it can make a well-informed decision about whether or not it should run that particular `.wasm` module.
