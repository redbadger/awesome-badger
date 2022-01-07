# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [WAT Datatypes](../04/) | [Up](/chriswhealy/introduction-to-web-assembly-text) | [Arrangement of WAT Instructions](../06/)

## 5: Local Variables

As with any other programming language, you can declare variables.  These variable will be local to the scope of a single WebAssembly function:[^1]

```wast
(local $my_value i32)
```

Here, we have declared a local variable called `$my_value` to be of type `i32`.

> **IMPORTANT**<br>
> Local variables are automatically initialised to zero

Now that we have a local variable, we can store a value in it:

```wast
(local.set $my_value (i32.const 5))
```

> **IMPORTANT**<br>
> `local.set` consumes the top value from the stack and stores it in the named variable
>
> This behaviour might become clearer if we use the sequential notation for the same assignment:
>
> ```wast
>i32.const 5              ;; Stack = [5], $my_value = 0
>local.set $my_value      ;; Stack = [],  $my_value = 5
>```

Assuming that we have just stored `5` in `$my_value`, then when we use `local.get` to fetch it, a copy of the value is placed onto the top of the stack:

```wast
local.get $my_value      ;; Stack = [5]
```

### Naming Local Variables

Strangely enough, you do not need to supply a name when declaring a local variable (or a function for that matter).

This might sound pretty weird, but the point is that only humans benefit from human-readable names.  In a WAT program, it's perfectly possible to declare variables like this:

```wast
(local i32 i32 f64)  ;; Declare three unnamed variables, two i32s and an f64
```

Uh, OK....  So how do you reference these local values?

Assuming these are the first local variables declared in a function, then the two `i32`s will be variables `0` and `1`, and the `f64` will be variable `2`.

The point here is that even if you do not assign a human-readable name to a local variable, that variable can always be accessed using its index number.[^2]

So if you want to store 5 in the second of your local variables (variable `1`), it is quite acceptable to write:

```wast
(local.set 1 (i32.const 5))    ;; Store 5 in local variable 1
```

The problem is, you now need to remember what variable `1` holds.  And this is where humans rapidly begin to struggle, because once we get beyond a small number of abstract tokens, we simply can't remember what they mean.

Us humans need meaningful variable names &mdash; so let's keep using them!

<hr>

[^1]: You can also declare variables that are global to the scope of the entire module, but we won't worry about these for the time being
[^2]: Where the index number refers to the declaration order
