# Introduction to WebAssembly Text
<table style="table-width: fixed; width: 100%">
<tr><th style="width: 45%">Previous</th>
    <th style="width: 10%"></th>
    <th style="width: 45%">Next</th></tr>
<tr><td style="text-align: center"><a href="./03%20Calling%20WebAssembly%20from%20a%20Host%20Environment.md">Calling WebAssembly from a Host Environment</a></td>
    <td style="text-align: center"><a href="./README.md">Top</a></td>
    <td style="text-align: center"><a href="./05%20Local%20Variables.md">Local Variables</a></td></tr>
</table>

## 4: WAT Datatypes

At the moment, there are only four WebAssembly datatypes:

* `i32` 32-bit integer
* `i64` 64-bit integer
* `f32` 32-bit floating point
* `f64` 64-bit floating point

That's it &mdash; just numbers...

No string datatype. No character datatype.  In fact, there isn't even a Boolean type!

> **IMPORTANT**
> One very important point here concerns how you interpret integers.
> 
> A floating point number always carries a sign value, but when examining an integer, you are free to choose whether the value is interpreted as an unsigned sequence of bits, or as a twos-complement integer.

Don't be concerned at the lack of a specific Boolean datatype because this is, in fact, just syntactic sugar.  In WAT, the outcome of a condition is stored simply as an `i32` where zero means `false`, and any non-zero value means `true`.

It's that simple...
