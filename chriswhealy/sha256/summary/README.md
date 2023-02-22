# Summary

Several things were learned during this exercise:

* The resulting binary is only 934 bytes 😎
* The runtime performance is not as fast as the C implementation, but is pretty respectable
* WebAssembly would benefit from having a raw binary data type that could includes such instructions as `raw32` or `raw64`; that way, we would not need all that `i8x16.swizzle` shenannigans to convert the endianness of data that needs to be processed in network byte order.
* Unit testing WebAssembly functions (especially private ones) is do-able, but awkward.
   Quite a lot of extra coding in both the WebAssembly module and the host environment is needed to facilite this.
* The runtime performance of the JavaScript host environment needs to be improved!

Whilst it must be said that coding directly in WebAssembly Text is a labour-intensive task (and is therefore probably not a good choice for your everyday, high-level coding tasks), the upside is that it requires you to form a deep understanding of your problem space.
This in turn then leads you to providing a smaller and more efficient solution.

If you need to solve a CPU-bound problem (and time allows), I would certainly recommend learning to code directly in WebAssembly Text as it will discipline your mind to write only those instructions that are absolutely necessary for solving the problem.
