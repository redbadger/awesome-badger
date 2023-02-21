---
layout: post
title:  "Implementing the SHA256 Message Digest Algorithm in WebAssembly Text"
date:   2023-02-20 12:00:00 +0000
category: chriswhealy
author: Chris Whealy
excerpt: WebAssembly Text (WAT) is ideally suited for implementing CPU intensive algorithms such as calculating a file's SHA256 digest.  This blog describes not only how I got this algorithm working in WebAssembly Text, but takes a wider view at the areas where improvements could be made both in the host environment (JavaScript in this case) and in the overall developer experience of working with WAT.
---

## SHA256: What Is It?

The SHA256 algorithm is one of the ***S***ecure ***H***ash ***A***lgorithm-2 family of cryptographic functions published by the United States [National Security Agency](https://en.wikipedia.org/wiki/National_Security_Agency) in 2001.

The purpose of these algorithms is to generate an output called a ***hash*** that, for all practical purposes, can be considered unique for the given input.
In this sense, a hash can be thought of as a message's unique digital fingerprint.

In the same way that the probability of finding two human beings with identical fingerprints is unfeasibly low, so the probability that any two input messages will generate the same SHA256 hash value is also unfeasibly low.

In more technical terms, for any secure hash value of length `n` bits, the probability of a brute force attack finding the input value that generated it is one chance in <code>2<sup>n</sup></code>.

In our case, we are creating a hash value 256 bits long, so that's 1 chance in 2<sup>256</sup> or 1.15792089237 * 10<sup>77</sup> &mdash; and herein lies the strength of the SHA-2 family of algorithms; namely, that the chances of being able to use a forged hash value are so astronomically small that it's not even worth starting.

## Development Objectives

1. See how small a binary can be produced when the SHA256 digest algorithm is implemented directly in WebAssembly Text
1. Compare the runtime performance of the WebAssembly module with the native `sha256sum` program supplied with macOS

The Git repo containing the working software can be [found here](https://github.com/ChrisWhealy/wasm_sha256)

## Development Challenges

Two challenges had to be overcome during development:

1. The SHA256 algorithm expects to handle data in network byte order, but WebAssembly only has numeric data types that automatically rearrange a value's byte order according to the CPU's endianness.
1. Unit testing WASM functions within a module is an entirely manual process.
   This presented an interesting challenge when writing unit tests for WASM functions that did not need to be exported (I.E. private functions)

## Table of Contents

- [SHA256 Algorithm Overview](/chriswhealy/sha256/algorithm-overview/)
- [WebAssembly Has No `raw` Data Type](/chriswhealy/sha256/endianness/)
- [WebAssembly Program Architecture](/chriswhealy/sha256/architecture/)
- [WebAssembly Implementation](/chriswhealy/sha256/implementation/)
- [Unit Testing WebAssembly Functions](/chriswhealy/sha256/testing/)
- [Host Environment](/chriswhealy/sha256/host-environment/)
- [Summary](/chriswhealy/sha256/summary/)
