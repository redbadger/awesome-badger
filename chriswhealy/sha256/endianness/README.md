## A Fundamental Collision of Concepts

1. The basic unit of data processed by the SHA256 algorithm is an uninterpreted sequence of 32 bits (I.E. raw binary)
1. WebAssembly only has numeric data types

WebAssembly can only read data from memory using one of its numeric data types.
So like it or not, if you use an `i32` instruction to read a value from memory, that value will be interpreted as an integer whose byte order is determined by the endianness of the CPU on which you're running.
(Almost all processors nowadays are [little-endian](https://en.wikipedia.org/wiki/Endianness))

For example, if you call `(i32.load (local.get $some_offset))`, then WebAssembly will use the following logic:

* The developer wants the 32-bit ***integer*** found in memory at `$some_offset` to be placed on the stack
* Since I'm running on a little-endian processor, the data in memory ***must*** have been stored in little-endian byte order
* So, before placing the value on the stack, I must reverse the byte order otherwise there will be a nonsense value on the stack...

So the raw binary value `0x0A0B0C0D` in memory appears on the stack as `0x0D0C0B0A`...

![Uh...](/chriswhealy/sha256/img/uh.gif)

> This problem *might* be fixed when the [Garbage Collection proposal](https://github.com/WebAssembly/gc/blob/master/proposals/gc/MVP.md) is implemented, but it probably won't involve the arrival of a new datatype called `raw32`.
>
> If such a data type were created, then a naïve solution might look like this:
>
> ```wast
> (local $raw_bin raw32)
> (local.set $raw_bin (raw32.load $some_offset))
> ```
>
> This would be great, but I doubt it will be implemented that way...

So the problem is simply this: before the SHA256 algorithm can start, we must swap the endianness of the data in memory so that when it is loaded onto the stack, the bytes appear in the expected network order.

## Workaround

Fortunately in our case, there is a simple workaround.

The host environment writes the file data to shared memory ***in network order***.
The file is then divided into 64-byte chunks, where each chunk forms the seed value at the start of the next 512-byte message digest.

All we need to do is this:

* Treat the data in this 64-byte chunk as if it were 16 `i32` values
* Swap the endianness of each `i32` value
* Write the swapped `i32` values to the start of the message digest

After that, we no longer need to care about endianness because the data will always appear on the stack in the correct byte order.

Finally, after the hash has been generated, we need to generate a character string that swaps the bytes back into network order.
In our particular case, the coding in the JavaScript host environment takes responsibility for converting the binary hash value into a printable string.

### Parallel Operations

We could reverse the byte-order of each `i32` individually, but fortunately, WebAssembly makes a large number of SIMD (***S***ingle ***I***nstruction, ***M***ultiple ***D***ata) instructions available to us.
These instructions are designed to peform the same operation on multiple data values *in parallel*.
This not only simplifies the coding, but gives us a four-fold performance improvement.

In the loop where the raw binary file data is copied from the message block into the start of the message digest, instead of using the `memory.copy` instruction, we can use the SIMD instruction `i8x16.swizzle`.

"Swizzle" is just a goofy name for rearranging a set of things into a new order.

```wast
;; Transfer the next 64 bytes from the message block to words 0..15 of the message schedule as raw binary
;; Use i8x16.swizzle to swap endianness
(loop $next_msg_sched_vec
  (v128.store
    (i32.add (global.get $MSG_SCHED_OFFSET) (local.get $offset))
    (i8x16.swizzle
      (v128.load (i32.add (local.get $blk_ptr) (local.get $ptr)))  ;; 4 words of raw binary in network byte order
      (v128.const i8x16 3 2 1 0 7 6 5 4 11 10 9 8 15 14 13 12)     ;; Rearrange bytes into this order of indices
    )
  )

  (local.set $offset (i32.add (local.get $offset) (i32.const 16)))
  (br_if $next_msg_sched_vec (i32.lt_u (local.get $offset) (i32.const 64)))
)
```

Notice that we are now using instructions belonging to a different dataype: `v128` (128-bit vector), not `i32`.

The `i8x16` instruction belongs to the `v128` data type and means *"treat this block of 128 bits as if it were 16, 8-bit integers"*.

Here, we load a block of 128 bits onto the stack, then using `i8x16.swizzle`, we rearrange the byte order according to the vector of indices supplied as the second argument.
The same block of data is then treated as a group of four `i32` values which are written back to memory.

![Swap Endianness using i8x16.shuffle](/chriswhealy/sha256/img/i8x16.swizzle.png)

Now, when those `i32`s are read back onto the stack, WebAssembly will assume that they have been stored in little-endian byte order, and the bytes will be reversed &mdash; back into network byte order.

Thus by some simple trickery, we have ensured that the data is always processed in the correct byte order.
