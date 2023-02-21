# Summary

Several things were learned during this exercise:

* The resulting binary is only 934 bytes 😎
* WebAssembly would benefit from a set raw binary data types such as `raw32` or `raw64`; that way, we would not need all that `i8x16.swizzle` shenannigans to convert the endianness of data that needs to be processed in network byte order.
* Unit testing WebAssembly functions (especially the private ones) is do-able, but awkward.
   Quite a lot of extra coding in both the WebAssembly module and the host environment is needed to facilite this.
* The run time performance could be improved
   * The JavaScript coding in the host environment that copies the data to shared memory is known to be horrifically slow!

     I just need to get around to fixing this!
   * The WebAssembly performance could be improved by splitting message digest preparation and hash value calculation into separate WASM modules that both act upon the same block of shared memory.

     There could be multiple threads dedicated to preparing a set of 512-byte message digest blocks, then another thread would consume those message digests in sequential order to generate the final hash.

     However, this would then require the host environment to be much more tightly coupled to the WebAssembly environment.
     Instead of instantiating a single `.wasm` module, the host environment would have to instantiate a pair of `.wasm` modules that then must be invoked in exactly the correct order.

     To me, this is rearanging the problem rather than solving it...

Whilst it must be said that coding directly in WebAssembly Text is a labour-intensive task (and is therefore probably not a good choice for your everyday, high-level coding tasks), the upside is that it requires you to form a deep understanding of your problem space.
This in turn then leads you to providing a clearer, more efficient solution.

If you need to solve a CPU-bound problem (and time allows), I would certainly recommend learning to code directly in WebAssembly Text as it will discipline your mind to write only those instructions that are absolutely necessary for solving the problem.
