# Introduction to WebAssembly Text
<table style="table-width: fixed; width: 100%">
<tr><th style="width: 45%">Previous</th>
    <th style="width: 10%"></th>
    <th style="width: 45%">Next</th></tr>
<tr><td style="text-align: center"><a href="./04%20WAT%20Datatypes.md">WAT Datatypes</a></td>
    <td style="text-align: center"><a href="./README.md">Top</a></td>
    <td style="text-align: center"><a href="./06%20Arrangement%20of%20WAT%20Instructions.md">Arrangement of WAT Instructions</a></td></tr>
</table>

## 5: Local Variables

As with any other programming language, you can declare variables.  These variable will be local to the scope of a single WebAssembly function:[^1]

```wat
(local $my_value i32)
```

Here, we have declared a local variable called `$my_value` to be of type `i32`.

> **IMPORTANT**  
> Local variables are automatically initialised to zero

Now that we have a local variable, we can store a value in it:

```wat
(local.set $my_value (i32.const 5))
```

> **IMPORTANT**  
> `local.set` consumes the top value from the stack!
> 
> Understanding this behaviour might become clearer if we use the sequential notation for the same assignment:
>
> ```wat
>i32.const 5              ;; Stack = [5]
>local.set $my_value      ;; Stack = []
>```

Assuming that we have just stored `5` in `$my_value`, then when we use `local.get` to fetch it, a copy of the value is placed onto the top of the stack:

```wat
local.get $my_value      ;; Stack = [5]
```

### Naming Local Variables

Strangely enough, you do not need to supply a name when declaring a local variable (or a function for that matter).

This might sound pretty weird, but the point is that only humans benefit from human-readable names.  In a WAT program, its perfectly possible to declare two `i32` variables like this:

```wat
(local i32 i32)     ;; Declare two, unnamed i32 variables
```

Uh, OK....

So how do you reference these local values?  Assuming these are the first two local variables declared in a function, then the first `i32` will be variable `0` and the second, variable `1`.  

The point here is that even if you do not assign a meaningful name to a local variable, that variable will always be accessed using its index number.[^2]

So if you want to store 5 in the second of your local variables (variable `1`), it is quite acceptable to write:

```wat
(local.set 1 (i32.const 5))    ;; Store 5 in local variable 1
```

The problem is, you now need to remember what variable `1` holds.  And this is where humans rapidly begin to struggle, because once we get beyond a small number of abstract tokens, we simply can't remember what they mean.

Us humans need meaningful variable names &mdash; so let's keep using them!



[^1]: You can also declare variables that are global to the scope of the entire module, but we won't worry about these for the time being
[^2]: Where the index number refers to the declaration order