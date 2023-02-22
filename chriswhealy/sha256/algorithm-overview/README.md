# SHA256 Algorithm Overview

| Previous | [Top](/chriswhealy/sha256-webassembly) | Next
|---|---|---
| | SHA256 Algorithm Overview | [WebAssembly Does Not Have A "raw binary" Data Type](/chriswhealy/sha256/endianness/)

## SHA256: What Is It?

The SHA256 hash algorithm is one of the ***S***ecure ***H***ash ***A***lgorithm-2 family of cryptographic functions published by the United States [National Security Agency](https://en.wikipedia.org/wiki/National_Security_Agency) in 2001.

The purpose of this family of algorithms is to generate an output called a ***hash*** that, for all practical purposes, can be considered unique for the given input.
In this sense, a hash acts like a message's unique digital fingerprint.

In the same way that the probability of finding two human beings with identical fingerprints is unfeasibly low, so the probability that any two input messages will generate the same SHA256 hash value is also unfeasibly low.
Putting this another way, "hash collisions" are so unlikely that for all practical purposes, a SHA256 hash can be considered entirely unique.

In more technical language, for any secure hash value of length `n` bits, the probability that a brute force attack can discover the input value that generated it is one chance in <code>2<sup>n</sup></code>.

In our case, we are creating a hash value 256 bits long, so that's 1 chance in 2<sup>256</sup> or 1.15792089237 * 10<sup>77</sup> &mdash; and herein lies the strength of the SHA-2 family of algorithms; namely, that the chances of being able to use a forged hash value are so astronomically small that it's not even worth starting.

## Small Input Changes Create Large Output Changes

All the algorithms in the SHA-2 family start by generating a digest (also known as a "schedule") of a particular length (512 bytes in our case).
Then, using a one-way compression[^1] algorithm, they generate a unique output value whose bit pattern is highly susceptible to change.

This susceptibility to change is based on the fact that the algorithms exhibit a behaviour known as the [avalance effect](https://en.wikipedia.org/wiki/Avalanche_effect); that is, if a single input bit changes, then each output bit will have a 50% probability of changing.

The SHA-2 family of algorithms perform an initial preparation phase, then repeat a 2-phase compression process:

## Phase 0: Preparation

### Seed value preparation

1. Define 16, 32-bit values `s[0..15]` where each value is the fractional part of the square root of the first 16 prime numbers
1. Define 64, 32-bit values `k[0..63]` where each value is the fractional part of the cube root of the first 64 prime numbers
1. Create 8, 32-bit hash values `h[0..7]` and initialise such that `h[n] = s[n]`

### Message Preparation

1. Append a single bit `1` to the message (I.E. for data obtained from a file, append `0x80`)
1. Calculate the message's total bit length (which will always be &ge; 1)
1. Append sufficient bit `0`s to bring the message length up to the next 512-bit boundary, minus 64 bits
1. Write the bit length as a big-endian, 64-bit integer into the last 64 bits of the message

The message now occupies an integer number of 512-bit blocks.

## Phase 1: Build The Digest

The message digest is a 512-byte block viewed as 64, 32-bit words (`md[0..63]`)

1. Copy the next 64-byte message chunk to words `0..15` of the message digest
1. Populate the remaining 48 message digest words as follows:

   <pre>
   for n in 16..63
     &sigma;0    = rotr(md[n-15], 7) XOR rotr(md[n-15], 18) XOR shr(md[n-15], 3)
     &sigma;1    = rotr(md[n-2], 17) XOR rotr(md[n-2], 19)  XOR shr(md[n-2], 10)
     md[n] = md[n-16] + &sigma;0 + md[n-7] + &sigma;1
   end
   </pre>

## Phase 2: Compress The Digest

1. Initialise 8 working variables `a..h` from the corresponding hash values:

   <pre>
   a = h[0]
   b = h[1]
   c = h[2]
   d = h[3]
   e = h[4]
   f = h[5]
   g = h[6]
   h = h[7]
   </pre>

2. For each word in the message digest, calculate a set of intermediate values and use them to update the working variables as follows:

   <pre>
   for n in 0..63
     // Calculate intermediate values
     &Sigma;0       = rotr(a, 2) XOR rotr(a, 13) XOR rotr(a, 22)
     &Sigma;1       = rotr(e, 6) XOR rotr(e, 11) XOR rotr(e, 25)
     choice   = (e AND f) XOR (NOT(e) AND g)
     majority = (a AND b) XOR (a AND c) XOR (b AND c)
     temp1    = h + &Sigma;1 + choice + k[n] + md[n]
     temp2    = &Sigma;0 + majority

     // Shunt working variables
     h = g
     g = f
     f = e
     e = d + temp1
     d = c
     c = b
     b = a
     a = temp1 + temp2
   end
   </pre>

3. After the above loop has processed all 64 words in the message digest, phase 2 ends by adding the working variables `a..h` to the corresponding hash values `h[0..7]`.
Any arithmetic overflows are simply ignored.

   <pre>
   h[0] += a
   h[1] += b
   h[2] += c
   h[3] += d
   h[4] += e
   h[5] += f
   h[6] += g
   h[7] += h
   </pre>

## Final Output

Phases 1 and 2 are repeated until the input message has been consumed, then the final digest is simply the concatenation of the eight hash values `h[0..7]`.


[^1]: Be careful not to confuse the "one-way compression" used by the SHA-2 algorithms with the more familiar "data" or "two-way compression" performed by programs such as `zip`.<br>Programs such as `zip` are only useful because they specifically create a two-way mapping between the compressed data and the original data.  Without this, you'd never be able to `unzip` your files.<br>However, in cryptography, this two-way mapping is precisely what we must avoid creating!<br>Consequently, the SHA-2 family of algorithms have been specifically designed to exclude any practical possibilty of recovering the original data from its compressed form; yet at the same time, the compressed form must be constructed in such a way that it could only have come from the source data.
