# JavaScript Host Environment

| Previous | [Top](/chriswhealy/sha256-webassembly) | Next
|---|---|---
| [Unit Testing WebAssembly Functions](/chriswhealy/sha256/testing/) | JavaScript Host Environment | [Summary](/chriswhealy/sha256/summary/)

## Overview

The host environment for this WebAssembly program has been written in server-side JavaScript run by NodeJS.

All JavaScript files have been written as ES6 modules (`.mjs` files) containing exported functions.

## Bare-Bones Architecture

This implementation contains a lot of coding related to peripheral activities such as:

* Performance measurement
* Providing WebAssembly with logging functions
* Implementing a unit test framework

None of the coding related to the above tasks will be described here as this is not central to the task at hand.
Instead, the following bare-bones steps are documented:

1. Instantiate the `.wasm` module
2. Using the file name supplied as a `node` command line argument, read the target file into memory
3. Copy the file contents into WASM shared memory appending the end-of-data marker (`0x80`) and the file's bit length as a big-endian `i64` value
4. Invoke the WASM module's exported `sha256_hash` function passing in the number of 512-bit blocks the file occupies
5. Using the pointer returned by the `sha256_hash` function, convert the 256-bit hash value into a printable string and write it to the console.

```javascript
startWasm(wasmFilePath)
  .then(({ wasmExports, wasmMemory }) => {
    let msgBlockCount = populateWasmMemory(wasmMemory, fileName, _, _)

    // Calculate hash then convert byte offset to i32 index
    let hashIdx32 = wasmExports.sha256_hash(msgBlockCount) >>> 2

    // Convert binary hash to character string
    let wasmMem32 = new Uint32Array(wasmMemory.buffer)
    let hash = wasmMem32.slice(hashIdx32, hashIdx32 + 8).reduce((acc, i32) => acc += i32AsHexStr(i32), "")

    console.log(`${hash}  ${fileName}`)
  })
```

## Instantiate the WASM Module

```javascript
import { readFileSync } from "fs"
import { hostEnv } from "./utils/hostEnvironment.mjs"

const MIN_WASM_MEM_PAGES = 2

export const startWasm =
  async pathToWasmFile => {
    let wasmMemory = new WebAssembly.Memory({ initial: MIN_WASM_MEM_PAGES })

    let { instance } = await WebAssembly.instantiate(
      new Uint8Array(readFileSync(pathToWasmFile)),
      hostEnv(wasmMemory)
    )

    return {
      wasmExports: instance.exports,
      wasmMemory,
    }
  }
```

The `hostEnv` function creates a JavaScript object containing various functions and values imported by the WebAssembly module.
All the imported functions relate either to unit testing or logging and are therefore not relevant for production use; however, the most important value is a reference to the block of shared memory created and populated by the host environment.

```javascript
{
  "memory": {
    "pages": wasmMemory,
  }
}
```

Without this reference to shared memory, the WebAssembly function `sha256_hash` would not have any access to the file data.

## Populate Shared Memory

The WebAssembly module has been instantiated with a default memory allocation of 2, 64Kb pages.
The first memory page holds various values such as the prime number constants, the 512-byte memory digest, and various pointers.
The second memory page holds the file data.

However, before writing the file into that second memory page, we must check to see if the file will fit.
If it does not, we must first grow the memory allocation.

The coding shown below has been stripped back to show only the functional minimum.
Hence, non-essential arguments have been replaced with underscores `_`.

`memPages` is a utility function that calculates the number of 64Kb memory pages a file will need (plus the 9 extra bytes needed for the end-of-data marker and the 64-bit length field).

```javascript
export const populateWasmMemory =
  (wasmMemory, fileName, _, _) => {
    const fileData = readFileSync(fileName)

    // If the file length plus the extra end-of-data marker (1 byte) plus the 64-bit, unsigned integer holding the
    // file's bit length (8 bytes) won't fit into one memory page, then grow WASM memory
    if (fileData.length + 9 > WASM_MEM_PAGE_SIZE) {
      let memPageSize = memPages(fileData.length + 9)
      wasmMemory.grow(memPageSize)
    }

    let wasmMem8 = new Uint8Array(wasmMemory.buffer)
    let wasmMem64 = new DataView(wasmMemory.buffer)

    // Write file data to memory plus end-of-data marker
    wasmMem8.set(fileData, MSG_BLOCK_OFFSET)
    wasmMem8.set([END_OF_DATA], MSG_BLOCK_OFFSET + fileData.length)

    // Write the message bit length as an unsigned, big-endian i64 as the last 64 bytes of the last message block
    let msgBlockCount = msgBlocks(fileData.length + 9)
    wasmMem64.setBigUint64(
      MSG_BLOCK_OFFSET + (msgBlockCount * 64) - 8,  // Byte offset
      BigInt(fileData.length * 8),                  // i64 value
      false                                         // isLittleEndian?
    )

    return msgBlockCount
  }
```

## Convert Binary Hash to Printable String

After the hash has been calculated, the last remaining job is to convert the binary value to a printable string.
This functionality is performed by the following JavaScript code:

```javascript
  let hashIdx32 = wasmExports.sha256_hash(msgBlockCount) >>> 2

  // Convert binary hash to character string
  let wasmMem32 = new Uint32Array(wasmMemory.buffer)
  let hash = wasmMem32.slice(hashIdx32, hashIdx32 + 8).reduce((acc, i32) => acc += i32AsHexStr(i32), "")
```

Here, the utility function `i32AsHexStr` is used within the reducer function to perform the necessary conversion.

There are two important details to bear in mind here:

1. WebAssembly has written the required values to memory as 8, `i32` integers.
   This immediately means that the bytes within these `i32` values will appear in memory in little-endian byte order.
1. The pointer returned from WebAssembly is a byte offset within shared memory.
   However, we need to look at the data in shared memory as an array of `i32` values.
   This means we must do the following:

   * Create a new `Uint32Array` overlay onto shared memory
   * Divide the byte offset by 4 to convert it to an `i32` offset &mdash; hence the unsigned shift right operation `>>> 2`
   * Using the `i32` index value, extract the 8, `i32` hash values via the `Uint32Array` overlay
