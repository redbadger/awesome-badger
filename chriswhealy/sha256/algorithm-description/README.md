## SHA256 Algorithm Description

All the algorithms in the SHA-2 family start by generating a digest of a particular length (512 bits in our case).
Then, using a one-way compression algorithm, they generate an output value whose bit pattern is highly susceptible to change.
This susceptibility to change is based on the fact that the algorithms implement a behaviour known as the [avalance effect](https://en.wikipedia.org/wiki/Avalanche_effect); that is, if a single input bit changes, then there is a 50% probability that every output bit will change.
