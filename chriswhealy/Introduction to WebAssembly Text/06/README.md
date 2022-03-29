# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [Local Variables](../05/) | [Up](/chriswhealy/introduction-to-web-assembly-text) | [Conditions](../07/)

## 6: Arrangement of WAT Instructions
WebAssembly is a stack-based language.  This means that most instructions behave in the following way:

* Pop one or more values off the stack
* Transform these values in some way that often generates a new value
* If a new value is generated, push it back onto the stack[^1]

### Sequential WAT Instructions

If you disassemble a `.wasm` program using a tool such as `wasm2wat`, you will see the WAT instructions listed sequentially (that is, in the order described by [Reverse Polish Notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation)).

Using sequential notation, two numbers are added together by first pushing both values onto the stack *then* calling the `add` operation.  The `add` operation then pops the top two values off the stack, adds them up and pushes the result back onto the stack.

```wast
i32.const 3    ;; Push 3.  Stack = [3]
i32.const 5    ;; Push 5.  Stack = [5,3]

i32.add        ;; Pop 2 values, add them and push the result.  Stack = [8]
```

In addition to the fact that we have to issue instructions in this apparently backwards manner, each instruction explicitly carries the name of the datatype upon which it operates.  In this case, we are working with 32-bit integers; therefore, each instruction is prefixed with `i32.`[^2]

Similar prefixes exist for 64-bit integers (`i64`), and 32- and 64-bit floating points (`f32` and `f64`)

### Folded WAT Instructions or "S-Expressions"

It is also possible to fold WAT instructions into what is known as an [S-Expression](https://en.wikipedia.org/wiki/S-expression).  If you have used any of the LISP family of languages such as [Clojure](https://clojure.org/), then you will have already come across this syntactical style.

Instead of writing three sequential instructions, we could fold them together into an S-Expression like this:

```wast
(i32.add (i32.const 3) (i32.const 5))
```

Although the folded (or S-Expression) form of WAT is generally easier to read, you should get used to reading both the sequential and folded forms because tools such as the WebAssembly disassembler (`wasm2wat`) always outputs instructions sequentially.

<hr>

[^1]: Some instructions do not generate a new value.  For instance `i32.store` consumes the top two values from the stack (an address and a value), but the result is that 4 bytes are written to memory.  Nothing is pushed back onto the stack.
[^2]: WebAssembly instructions cannot operate on values of mixed datatype. The assembler will throw an error if you attempt to use `i32.add` to add two values that are not both of type `i32`
