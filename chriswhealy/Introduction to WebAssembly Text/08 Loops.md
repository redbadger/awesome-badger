# Introduction to WebAssembly Text
<table style="table-width: fixed; width: 100%">
<tr><th style="width: 45%">Previous</th>
    <th style="width: 10%"></th>
    <th style="width: 45%">Next</th></tr>
<tr><td style="text-align: center"><a href="./07%20Conditions.md">Conditions</a></td>
    <td style="text-align: center"><a href="./README.md">Top</a></td>
    <td style="text-align: center"><a href="./09%20More%20About%20Functions.md">More About Functions</a></td></tr>
</table>

## 8: Loops

Let's now extend the previous code fragment to see how it could be used to control a loop.  The above condition is used to perform a basic loop that does something 5 times:

```wat
(local %counter i32)

(loop $do_it_again
  ;; As long as the limit is greater than the counter, proceed with the loop
  ;; Comparison statements leave an i32 value on the top of the stack.
  ;; If the comparison is true, then the top of the stack = [1], else [0]
  (if (i32.gt_u (i32.const 5) (local.get $counter))
    (then
      ;; True. Top of stack contains a non-zero i32
      ;; Do something here
      
      ;; Increment the counter
      (local.set $counter (i32.add (local.get $counter) (i32.const 1)))
      
      ;; Jump to the start of the loop
      (br $start_again)
    )
  )
) ;; end of loop $do_it_again

;; More instructions after the loop...
```

Notice that a loop condition can be specified in two ways:

* Most languages assume that the loop should always continue, then repeatedly check for a termination condition: "*Should the loop stop now?*".

   That's fine and you could certainly structure a loop this way in WAT...
   
* In WAT however, it is more idiomatic to assume that the loop should **not** continue, then repeatedly check a continuation condition: "*Should the loop continue?*".

   If the loop should continue, we enter the `then` block, do whatever needs to be done, then finally, there is an explicit branch `br` statement that jumps back to the start of the loop.

So what happens if the continuation condition evaluates to `false`?

We simply drop out at the bottom of the loop labeled `$do_it_again`.