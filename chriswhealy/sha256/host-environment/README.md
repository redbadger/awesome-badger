# SHA256 Host Environment

The host environment for this WebAssembly program has been written in server-side JavaScript run by NodeJS.

All JavaScript files have been written as ES6 modules (`.mjs` files) containing exported functions.

## Bare-Bones Architecture

This implementation contains a lot of coding related to activities such as performance measurement, providing WebAssembly with logging functions, and implementing a unit test framework.
None of this coding will be described as its purpose is only peripheral to the task at hand.

What is documented below are the following bare-bones steps:

1. Instantiate the `.wasm` module
2. Using the file name supplied as a `node` command line argument, read the target file into memory
3. Copy the file contents into WASM shared memory adding the end-of-data marker (`0x80`) and the file's bit length as a big-endian `i64` value
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

    // Output performance tracking marks
    perfTracker.listMarks()
  })
```

## Instantiate the WASM Module

```javascript
import { readFileSync } from "fs"
import { hostEnv } from "./hostEnvironment.mjs"

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
All the imported functions relate to unit testing and are not relevant for production use; however, the most important value is a reference to the block of shared memory created and populated by the host environment.

```javascript
{
  "memory": {
    "pages": wasmMemory,
  }
}
```

Without this reference to shared memory, the WebAssembly function `sha256_hash` would not have any access to the file data.

## Populate Shared Memory

Now that the WebAssembly module has been instantiated with a minimal memory allocation, we need to read the target file and copy that data into shared memory.

The immediate question though is whether or not the minimal two pages of shared memory allocated when the WebAssmebly module was instatiated will be big enough to contain the file.

The coding shown below has been stripped back to show only the functional minimum.
Hence, non-essential arguments have been replaced with underscores `_`.

`memPages` is a utility function that calculates the number of 64Kb memory pages a file will need (plus the 9 extra bytes needed for the end-of-data marker and the 64-bit length field).

```javascript
export const populateWasmMemory =
  (wasmMemory, fileName, _, _) => {
    const fileData = readFileSync(fileName, { encoding: "binary" })

    // If the file length plus the extra end-of-data marker (1 byte) plus the 64-bit, unsigned integer holding the
    // file's bit length (8 bytes) won't fit into one memory page, then grow WASM memory
    if (fileData.length + 9 > WASM_MEM_PAGE_SIZE) {
      let memPageSize = memPages(fileData.length + 9)
      wasmMemory.grow(memPageSize)
    }

    let wasmMem8 = new Uint8Array(wasmMemory.buffer)
    let wasmMem64 = new DataView(wasmMemory.buffer)

    // Write file data to memory plus end-of-data marker
    // TODO Major performance problem here!
    // Writing a large file into WASM memory as a Uint8Array is EXTREMELY slow!!
    wasmMem8.set(stringToAsciiArray(fileData), MSG_BLOCK_OFFSET)
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

### OOPS! Performance Problem

The coding here takes the simple option and treats WASM shared memory as a buffer of unsigned, 8-bit integers (`Uint8Array`).
Whilst this removes the need to worry about all that byte-swapping shennanigans created by the CPU's endianness, it does create a pretty big performance problem.
The bottom line is that writing data as individual bytes is slow!

The solution would be to use a JavaScript `DataView` and write the data as unsigned, 64-bit values &mdash; but I haven't had time to implement this yet...

To see this performance problem, just run the program against a very large file with performance tracking switch on:

```bash
$ node index.mjs <some_large_file> true
03841701df49179e7be90c5988aed8c61cd1941ca5cec7f0092a485cbe5be555  <some_large_file>
Start up                :    0.029 ms
Instantiate WASM module :    2.265 ms
Read target file        :   83.653 ms
Populate WASM memory    : 7290.563 ms
Calculate SHA256 hash   : 1590.331 ms
Report result           :    5.773 ms

Done in 8972.614 ms
```

The above statitics are for a file that is nearly 100Mb is size.  Simply simply writing the data to shared memory took about 5 times longer than calculating the actual hash.
Ouch!

## Convert Binary Hash to Printable String

After the hash has been calculated, the last remaining job is to convert the binary value to a printable string:

```javascript
  let hashIdx32 = wasmExports.sha256_hash(msgBlockCount) >>> 2

  // Convert binary hash to character string
  let wasmMem32 = new Uint32Array(wasmMemory.buffer)
  let hash = wasmMem32.slice(hashIdx32, hashIdx32 + 8).reduce((acc, i32) => acc += i32AsHexStr(i32), "")
```

Here, the utility function `i32AsHexStr` is used as reducer to perform the necessary conversion.

There are two important details to bear in mind here:

1. WebAssembly has written the required values to memory as 8, `i32` integers.
   This immediately means that the data will appear in memory in little-endian byte order.
1. The pointer returned from WebAssembly is a byte offset within shared memory.
   Since we will be extracing the value as 4-byte `i32`'s, this byte offset must be converted to an `i32` offset &mdash; Hence the unsigned shift right `>>>` to divide this value by 4
