# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [Calling WebAssembly from a Host Environment](../03/README.md) | [Top](../README.md) | [Local Variable](../05/README.md)

## 4: WAT Datatypes

At the moment, there are only four WebAssembly datatypes:

| | 32-bit | 64-bit
|---|---|---
| Integer | `i32` | `i64`
| Floating point |  `f32`  | `f64`

That's it &mdash; just numbers...

No string datatype; no character datatype.

In fact, there isn't even a Boolean type! [^1]

### Interpreting Integers
One very important point here concerns how you interpret integers.

A floating point number always carries a sign value, but when examining an integer, you are free to choose whether the value is interpreted as an unsigned sequence of bits, or as a twos-complement integer.

This means that when applied to integers, certain comparison instructions such as `gt` or `lt` must additionally state whether or not the most significant bit should be treated as the sign bit.


[^1]: Don't be concerned at the lack of a specific Boolean datatype because this is, in fact, just syntactic sugar.  In WAT, the outcome of a condition is stored simply as an `i32` where zero means `false`, and any non-zero value means `true`.  It's that simple...
