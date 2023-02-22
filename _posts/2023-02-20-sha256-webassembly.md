---
layout: post
title:  "Implementing the SHA256 Hash Algorithm in WebAssembly Text"
date:   2023-02-20 12:00:00 +0000
category: chriswhealy
author: Chris Whealy
excerpt: WebAssembly Text (WAT) is ideally suited for implementing CPU intensive algorithms such as calculating a file's SHA256 hash.  This blog describes not only how I got this algorithm working in WebAssembly Text, but takes a wider view and looks at the areas where improvements could be made both in the performance of the host environment (JavaScript, in this case) and in the overall developer experience of working with WAT.
---

## Table of Contents

- [SHA256 Algorithm Overview](/chriswhealy/sha256/algorithm-overview/)
- [WebAssembly Does Not Have A "raw binary" Data Type](/chriswhealy/sha256/endianness/)
- [WebAssembly Program Architecture](/chriswhealy/sha256/architecture/)
- [WebAssembly Implementation](/chriswhealy/sha256/implementation/)
- [Unit Testing WebAssembly Functions](/chriswhealy/sha256/testing/)
- [JavaScript Host Environment](/chriswhealy/sha256/host-environment/)
- [Summary](/chriswhealy/sha256/summary/)

## Development Objectives

1. See how small a binary can be produced when the SHA256 digest algorithm is implemented directly in WebAssembly Text
1. Compare the runtime performance of the WebAssembly module with the native `sha256sum` program supplied with macOS

The Git repo containing the working software can be [found here](https://github.com/ChrisWhealy/wasm_sha256)

## Development Challenges

Two challenges had to be overcome during development:

1. The SHA256 algorithm expects to handle data in network byte order, but WebAssembly only has numeric data types that automatically rearrange a value's byte order according to the CPU's endianness.
1. Unit testing WASM functions within a module is an entirely manual process.
   This presented an interesting challenge - especially when writing unit tests for private WASM functions
