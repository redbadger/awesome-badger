# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [Conditions](../07/) | [Up](/chriswhealy/introduction-to-web-assembly-text) | [More About Functions](../09/)

## 8: Loops

Let's now extend the previous code fragment to see how it could be used to control a loop.

### It's a Loop Jim, but Not as we Know it..

A loop in a WAT program is structured somewhat differently from loop constructs in other languages.  If we were to build a WAT loop like this, then it would not loop at all...

```wast
(loop %some_optional_label
  ;; Do stuff here
)
```

Say what...?

The point here is that WAT makes the basic assumption that all loops should terminate unless we specifically decide otherwise.  This means that when we hit the close parenthesis at the end of the loop body, unless there is a specific instruction to branch back to the start of the loop, we will simply drop out and continue with whatever instructions come next.

***IMPORTANT***

* A WAT loop is merely a block of code that has a labeled start point
* If you do not provide a human-readable label for the loop, as with local variables, the loop will be indentified by its index number
* A loop block will ***not*** be repeated automatically
* If the coding in a loop block is to be repeated, you must explicitly issue a branch `br` instruction to jump back to the start of the loop
* You cannot branch to the start of a loop from outside the loop body

Generally speaking therefore, WAT loops are structured like this:

```wast
(loop $loop_label
  ;; Test for continuation, not termination
  ;; As long as the loop limit is greater than the loop counter, then continue
  (if (i32.gt_u (local.get $loop_limit) (local.get $loop_counter))
    (then
      ;; Do repetitive stuff here

      ;; Increment $loop_counter
      (local.set (i32.add (local.get $loop_counter) (i32.const 1)))

      ;; Jump back to the start of the loop
      (br $loop_label)
    )
  ) ;; If the condition fails, we simply drop out of the loop
)
```

The point to get used to here is the way in which loop execution is controlled:

***Check for Termination***

Most languages assume that the loop should continue, then repeatedly ask "*Should I stop now?*".

That's fine and you could certainly structure a loop this way in WAT...

***Check for Continuation***

In WAT however, it is more idiomatic to assume that the loop should stop, then repeatedly ask "*Should I continue?*".
