## Host Environment Assumptions

We will assume that by the time the WebAssembly module is called, the JavaScript host environment has already performed the following tasks:

* Copied the file into shared memory
* Added the end-of-data termination bit `0x80`
* Written the bit length as a big endian, 64-bit integer to the end of the last 512-bit block, and
* Calculated the number of 512-bit message blocks to be processed

In addition to this, the host enviroment and the WebAssembly module need to share common knowledge of the memory offset at which the file data has been written.
As a future development, it would probably be worth removing this hardcoded value from the host environment coding.
Instead, the host environment would pick up an exported memory offset from the WebAssembly module, then write the file data to that particular location.

## WebAssembly Module Assumptions

Within the WebAssembly module, we need certain hardcoded constants to be available.
These values are the fractional parts of the square roots of the first 16 prime numbers, and the fractional parts of the cube roots of the first 64 prime numbers.

The values are simply hard-coded within `(data)` declarations, living at known memory offsets and whose values are supplied in little-endian byte order.

For example, the fractional parts of the square roots of the first 16 primes are given as:

```wast
(data (i32.const 0x000000)
  "\67\E6\09\6A"  ;; 0x000000
  "\85\AE\67\BB"
  "\72\F3\6E\3C"
  "\3A\F5\4F\A5"
  "\7F\52\0E\51"  ;; 0x010010
  "\8C\68\05\9B"
  "\AB\D9\83\1F"
  "\19\CD\E0\5B"
)
```

## Publicly Exported Function

This particular module need only export a single function.
In this case, we will call that function `sha256_hash`:

```wast
(func (export "sha256_hash")
      (param $msg_blk_count i32)  ;; Number of message blocks
      (result i32)                ;; The SHA256 hash is the concatenation of the 8, i32s starting at this location

  ;; SNIP

  ;; Return offset of hash values
  (global.get $HASH_VALS_PTR)
)
```

This function accepts an `i32` argument informing it of how many 512-bit blocks the file has been broken into, and returns an `i32` pointer to the memory location at which the final hash value starts.
It is reasonable to assume that the host environment knows that the return value is of fixed length, so we need only return a pointer rather than a pointer and a length.

## Initialisation

To start with, our 8 hash values must be initialised to the fractional part of the square roots of the first 8 prime numbers.
These values were chosen for two reasons: they can be defined deterministically, and their sequence is truly random (as are the cube roots of the first 64 primes).

This initialsation can be performed by a single `memory.copy` statement.

We also declare a local pointer variable and a local block counter variable.

```wast
(func (export "sha256_hash")
      (param $msg_blk_count i32)  ;; Number of message blocks
      (result i32)                ;; The SHA256 digest is the concatenation of the 8, i32s starting at this location

  (local $blk_count i32)
  (local $blk_ptr   i32)

  (local.set $blk_ptr (global.get $MSG_BLK_PTR))

  ;; Initialise hash values
  ;; Argument order for memory.copy is dest_ptr, src_ptr, length (yeah, I know, it's weird)
  (memory.copy (global.get $HASH_VALS_PTR) (global.get $INIT_HASH_VALS_PTR) (i32.const 32))

  ;; SNIP

  ;; Return offset of hash values
  (global.get $HASH_VALS_PTR)
)
```

## Outer Loop in Function sha256_hash

We know we must perform the same 2-phase processing on every 64-byte chunk of the file, so at the top level of function `sha256_hash`, we start a loop that iterates as many times as there are chunks in the file.

Within this outer loop, all we need to do is call the private functions `$phase_1` and `$phase_2`, increment the pointer and counter, then check for loop continuation.

Once the outer loop has finished processing the entire file, the final output is simply the concatenation of these 8 hash values.

```wast
(func (export "sha256_hash")
      (param $msg_blk_count i32)  ;; Number of message blocks
      (result i32)                ;; The SHA256 digest is the concatenation of the 8, i32s starting at this location

  (local $blk_count i32)
  (local $blk_ptr   i32)

  (local.set $blk_ptr (global.get $MSG_BLK_PTR))

  ;; Initialise hash values
  ;; Argument order for memory.copy is dest_ptr, src_ptr, length (yeah, I know, it's weird)
  (memory.copy (global.get $HASH_VALS_PTR) (global.get $INIT_HASH_VALS_PTR) (i32.const 32))

  ;; Process file in 64-byte blocks
  (loop $next_msg_blk
    (call $phase_1 (i32.const 48) (local.get $blk_ptr) (global.get $MSG_DIGEST_PTR))
    (call $phase_2 (i32.const 64))

    (local.set $blk_ptr   (i32.add (local.get $blk_ptr)   (i32.const 64)))
    (local.set $blk_count (i32.add (local.get $blk_count) (i32.const 1)))

    (br_if $next_msg_blk (i32.lt_u (local.get $blk_count) (local.get $msg_blk_count)))
  )

  ;; Return offset of hash values
  (global.get $HASH_VALS_PTR)
)
```

## Function $phase_1

Function `$phase_1` is responsible for building the message digest.

This function is a sequence of two loops:

* The first loop copies the next 64 bytes of message data into words 0 to 15 of the message digest
* The second loop populates the remaining 48 words (16 to 63) of the message digest

Due to the fact that the SHA256 algorithm expects data to be processed in network byte order, we cannot use the `memory.copy` instruction.
Instead, we must swap the data's endianness using the `i8x16.swizzle` instruction.
This instruction copies a 128-bit block of data onto the stack, and at the same time, swaps the byte order according to the vector of indices supplied as the second argument.

Due to the fact that almost all CPUs nowadays use little-endian byte order, we need to resort to some trickery to ensure that the data always appears on the stack in the required network byte order.

```wast
(func $phase_1
  (param $n           i32)
  (param $blk_ptr     i32)
  (param $msg_blk_ptr i32)

  (local $ptr i32)

  ;; Transfer the next 64 bytes from the message block to words 0..15 of the message digest as raw binary.
  ;; Use v128.swizzle to swap endianness
  (loop $next_msg_sched_vec
    (v128.store
      (i32.add (local.get $msg_blk_ptr) (local.get $ptr))
      (i8x16.swizzle
        (v128.load (i32.add (local.get $blk_ptr) (local.get $ptr)))  ;; 4 words of raw binary in network byte order
        (v128.const i8x16 3 2 1 0 7 6 5 4 11 10 9 8 15 14 13 12)     ;; Rearrange bytes into this order of indices
      )
    )

    (local.set $ptr (i32.add (local.get $ptr) (i32.const 16)))
    (br_if $next_msg_sched_vec (i32.lt_u (local.get $ptr) (i32.const 64)))
  )
```

Now that words 0 to 15 of the message digest have been correctly populated, we can start a second loop to populate the remaining 48 words (16 to 63).

When I initially wrote this second loop, I used a hard-coded iteration limit; however, this made unit testing tricky because I found I needed to test just a single iteration of the loop.
Therefore, it turned out to be very convenient to pass the number of loop iterations as a function argument.
This then allowed me to create a unit test that performed as many loop iterations as needed, without changing the function itself.

Now that testing is complete and the coding works, it might be more intuitive to replace this argument with a hard-coded iteration value; however, it does no harm to keep this feature.

```wast
(func $phase_1
  (param $n           i32)
  (param $blk_ptr     i32)
  (param $msg_blk_ptr i32)

  (local $ptr i32)

  ;; SNIP

  ;; Starting at word 16, populate the next $n words of the message digest
  (local.set $ptr (i32.add (global.get $MSG_DIGEST_PTR) (i32.const 64)))

  (loop $next_pass
    (i32.store (local.get $ptr) (call $gen_msg_digest_word (local.get $ptr)))

    (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))
    (local.set $n   (i32.sub (local.get $n)   (i32.const 1)))

    (br_if $next_pass (i32.gt_u (local.get $n) (i32.const 0)))
  )
)
```

Within this loop, we simply call the function `$gen_msg_digest_word` passing in a pointer to the word we're currently calculating.

## Function $gen_msg_digest_word

The `n`th message digest word is calculated using the four words found at indices `n-2`, `n-7`, `n-15` and `n-16`.

Refer to the [algorithm overview](/chriswhealy/sha256/algorithm-overview/) to see what the `$sigma` function does.

```wast
(func $gen_msg_digest_word
      (param $ptr i32)
      (result i32)

  (i32.add
    (i32.add
      (i32.load (i32.sub (local.get $ptr) (i32.const 64)))    ;; word_at($ptr - 16 words)
      (call $sigma                                            ;; Calculate sigma0
        (i32.load (i32.sub (local.get $ptr) (i32.const 60)))  ;; word_at($ptr - 15 words)
        (i32.const 7)
        (i32.const 18)
        (i32.const 3)
      )
    )
    (i32.add
      (i32.load (i32.sub (local.get $ptr) (i32.const 28)))   ;; word_at($ptr - 7 words)
      (call $sigma                                           ;; Calculate sigma1
        (i32.load (i32.sub (local.get $ptr) (i32.const 8)))  ;; word_at($ptr - 2 words)
        (i32.const 17)
        (i32.const 19)
        (i32.const 10)
      )
    )
  )
)
```

## Function $phase_2

Now that the message digest has been prepared, we start the second phase of the processing in which a one-way compression algorithm is applied to each 32-bit word in the message digest.
Key to this process is a set of 8, `i32` working variables `a` to `h`.

Each iteration of the loop does two things:

* It calculates two intermediate values `$temp1` and `$temp2`

   ```wast
   ;; temp1 = $h + $big_sigma1($e) + constant($idx) + msg_schedule_word($idx) + $choice($e, $f, $g)
   (local.set $temp1
     (i32.add
       (i32.add
         (i32.add
           (local.get $h)
           (call $big_sigma (local.get $e) (i32.const 6) (i32.const 11) (i32.const 25))
         )
         (i32.add
           ;; Fetch constant at word offset $idx
           (i32.load (i32.add (global.get $CONSTANTS_PTR) (i32.shl (local.get $idx) (i32.const 2))))
           ;; Fetch message digest word at word offset $idx
           (i32.load (i32.add (global.get $MSG_DIGEST_PTR) (i32.shl (local.get $idx) (i32.const 2))))
         )
       )
       ;; Choice = ($e AND $f) XOR (NOT($e) AND $G)
       (i32.xor
         (i32.and (local.get $e) (local.get $f))
         ;; WebAssembly has no bitwise NOT instruction 😱
         ;; NOT is therefore implemented as i32.xor($val, -1)
         (i32.and (i32.xor (local.get $e) (i32.const -1)) (local.get $g))
       )
     )
   )

   ;; temp2 = $big_sigma0($a) + $majority($a, $b, $c)
   (local.set $temp2
     (i32.add
       (call $big_sigma (local.get $a) (i32.const 2) (i32.const 13) (i32.const 22))
       ;; Majority = ($a AND $b) XOR ($a AND $c) XOR ($b AND $c)
       (i32.xor
         (i32.xor
           (i32.and (local.get $a) (local.get $b))
           (i32.and (local.get $a) (local.get $c))
         )
         (i32.and (local.get $b) (local.get $c))
       )
     )
   )
   ```

   Again, refer to the [algorithm overview](/chriswhealy/sha256/algorithm-overview/) to see what the `$big_sigma` function does.

* It shunts the values of the working variables down the list, injecting `$temp1` into the new value of `e` and rather than rotating the old value of `h` back into `a`, it sets the new value of `a` to be `$temp1 + $temp2`.

    ```
    h = g
    g = f
    f = e
    e = d + $temp1
    d = c
    c = b
    b = a
    a = $temp1 + $temp2
    ```

When all 64 words of the message digest have been processed, the values of the working variables `a` to `h` are added to the corresponding hash values `h[0]` to `h[7]`.
Any overflows are simply ignored.

Phase 2 finishes with a new set of 8, 32-bit hash values in variables `h[0..7]`.

## Finally

Once all the 64 byte chunks of the file have been processed, the final hash is simply the concatenation of values `h[0]` to `h[7]`
