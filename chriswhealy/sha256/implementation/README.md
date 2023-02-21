# WebAssembly Text Implementation

## Host Environment Assumptions

We will assume that by the time the WebAssembly module is called, the host environment has already done the following:

* Copied the file into shared memory
* Added the end-of-data termination bit `0x80`, and
* Written the bit length as a big endian, 64-bit integer to the end of the last 512-bit block
* Calculated the number of 512-bit message blocks to be processed

In addition to this, the host enviroment and the WebAssembly module need to share common knowledge of the memorty offset at which the the file has been written.
As a future development (design feature), it would probably be worth removing this need for shared knowledge so that the host environment simply picks an exported value from WebAssembly module, then writes the file data to that particular location.

## WebAssembly Module Assumptions

Within the WebAssembly module, we need certain hardcoded constants to be available.
These values are the fractional parts of the square roots of the first 16 prime numbers, and the fractional parts of the cube roots of the first 64 prime numbers.

The values are simply hard-coded as `(data)` declarations, living at known memory offsets and whose values are quoted little-endian byte order.
for example, the fractional parts of the square roots of the first 16 primes are given as:

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
In this case, we will call that function `digest`:

```wast
(func (export "digest")
      (param $msg_blk_count i32)  ;; Number of message blocks
      (result i32)                ;; The SHA256 digest is the concatenation of the 8, i32s starting at this location

  ;; SNIP

  ;; Return offset of hash values
  (global.get $HASH_VALS_PTR)
)
```

This function accepts an `i32` argument informing it of how many 512-bit blocks the file hase been broken up into, and returns an `i32` pointer to the memory location at which the final hash value starts.
It is reasonable to assume that the host environment knows that the return value is of fixed length value, so we return only a pointer rather than a pointer and a length.

## Initialisation

To start with, our 8 hash values must initialised to the fractional part of the square roots of the first 8 prime numbers.
These value were chosen because they can are truly random numbers (as are the cube roots of the first 64 primes).

This initialsation can be performed by a single `memory.copy` statement.

We also declare local pointer and local block counter variables.

```wast
(func (export "digest")
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

## Outer Loop in Function `digest`

We know we must perform the same 2-phase processing on every 64-byte chunk of the file, so at the top level of function `digest`, we start a loop that iterates as many times as there are chunks in the message.

Within this outer loop, all we need to do is call the private functions `$phase_1` and  `$phase_2`, increment the pointer and counter, then check for loop continuation.

Once the outer loop has finished processing the entire file, the final output is simply the concatenation of these 8 hash values.

```wast
(func (export "digest")
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

## Function `$phase_1`

Function `$phase_1` is responsible for building the message digest.

This function contains two loops: this first copies the next 64 bytes of message data into words 0 to 15 of the message digest, then the second loop populates words 16 to 63 based on the message data.

Due to to the fact that data must be processed in network byte order, we must use the `i8x16.swizzle` instruction to copy a 128-bit block of data, and at the same time, swap the byte order.
This trick is needed due to the fact that almost all computers nowadays use little-endian byte order.
Therefore we have to reverse the byte order of our data, so that after the CPU has reversed it (into what it thinks is the correct byte order for an `i32` on a little-endian machine), the data appears on the stack in the correct network byte order.

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

Now that words 0 to 15 of the message digest have been populated, we can start a second loop to populate the remaining 48 words (16 to 63).

Initially, the second loop inside this function used a hard-coded loop iteration limit; however, to make unit testing easier, it turned out to be very convenient if the number of loop iterations was supplied as a function argument.
This then allowed a unit test to be created that performed a single loop iteration without the need to change the function itself.

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

## Function `$gen_msg_digest_word`

The `n`th message digest word is calculated using the four, 32-bit values a word indices -2, -7, -15 and -16.

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

## Function `$phase_2`

Now that the message digest has been prepared, we start the second phase of the processing in which a one-way compression algorithm is applied to each 32-bit word in the message digest.
Key to this process is a set of 8, `i32` working variables (`a` to `h`).

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

* It shunts the values of the working variables:<br>
    `h = g`, `g = f`, `f = e` etc, but instead of simply assigning `e = d`, `e` is set equal to `d + $temp1`.<br>
    The shunt then continues with: `d = c`, `c = b` and `b = a`.<br>
    Finally, rather than rotating `h` back into `a`, `a` is set equal to `$temp1 + $temp2`

When all 64 words of the message digest have been processed, the values of the working variables `a` to `h` are added to the corresponding hash values `h[0]` to `h[7]`.
Any 32-bit overflows caused by addition (or any other operation for that matter) are ignored.

Phase 2 finishes with a new set of 8, 32-bit hash values.

```wast
;; Add working variables to hash values and store back in memory - don't worry about overflows
(i32.store          (global.get $HASH_VALS_PTR)                 (i32.add (local.get $h0) (local.get $a)))
(i32.store (i32.add (global.get $HASH_VALS_PTR) (i32.const  4)) (i32.add (local.get $h1) (local.get $b)))
(i32.store (i32.add (global.get $HASH_VALS_PTR) (i32.const  8)) (i32.add (local.get $h2) (local.get $c)))
(i32.store (i32.add (global.get $HASH_VALS_PTR) (i32.const 12)) (i32.add (local.get $h3) (local.get $d)))
(i32.store (i32.add (global.get $HASH_VALS_PTR) (i32.const 16)) (i32.add (local.get $h4) (local.get $e)))
(i32.store (i32.add (global.get $HASH_VALS_PTR) (i32.const 20)) (i32.add (local.get $h5) (local.get $f)))
(i32.store (i32.add (global.get $HASH_VALS_PTR) (i32.const 24)) (i32.add (local.get $h6) (local.get $g)))
(i32.store (i32.add (global.get $HASH_VALS_PTR) (i32.const 28)) (i32.add (local.get $h7) (local.get $h)))
```

## Finally

Once all the 64 byte chunks of the file have been processed, the final hash is simply the concatenation of values `h[0]` to `h[7]`
