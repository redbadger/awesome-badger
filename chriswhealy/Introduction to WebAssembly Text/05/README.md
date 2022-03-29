# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [WAT Datatypes](../04/) | [Up](/chriswhealy/introduction-to-web-assembly-text) | [Arrangement of WAT Instructions](../06/)

## 5: Local Variables

As with any other programming language, you can declare variables inside a function using the `local` keyword:[^1]

```wast
(local $my_value i32)
```

Here, we have declared that within a function (not shown here) we have a local variable of type `i32` called `$my_value`.

> **IMPORTANT**<br>
> 1. Variable names must start with a dollar sign
> 1. Local variables are automatically initialised to zero

Now that we have a local variable, we can store a value in it:

```wast
i32.const 5              ;; Push a value onto the stack
local.set $my_value      ;; Pop the value off the stack and store it in the named variable
```

Now that variable `$my_value` contains `5`, we can use `local.get` to push a copy of that value back onto the stack:

```wast
local.get $my_value      ;; Stack = [5]
```

### Naming Local Variables

Strangely enough, you do not need to supply a name when declaring either a local variable or a function.

This might sound pretty weird, but the point is that human-readable names are only of benefit to humans.  In a WAT program, it's perfectly possible to declare variables like this:

```wast
(local i32 i32 f64)  ;; Declare three unnamed variables, two i32s and an f64
```

Uh, OK...  So how do you reference these local values?

Internally, WebAssembly uses index numbers to reference variables and functions.

Within the scope of a module, functions are indexed from `0` on the basis of the order in which the function declarations are encountered.

Within the scope of a function, variables are indexed from `0` on the basis of their declaration order.

Assuming these are the first local variables declared in a function, then the two `i32`s will be variables `0` and `1`, and the `f64` will be variable `2`.

The point here is that even if you do not assign a human-readable name to a local variable, that variable can always be accessed using its index number.

So if you want to store 5 in the second of your local variables (variable `1`), it is quite acceptable to write:

```wast
(local.set 1 (i32.const 5))    ;; Store 5 in local variable 1
```

The problem is, you now need to remember what variable `1` holds.  And this is where humans rapidly begin to struggle, because once we get beyond a small number of abstract tokens, we simply can't remember what they mean.

Us humans need meaningful variable names &mdash; so let's keep using them!

<hr>

[^1]: You can also declare variables that are global to the scope of the entire module, but we won't worry about these for the time being
