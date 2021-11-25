# Introduction to WebAssembly Text

| Previous | | Next
|---|---|---
| [Conditions](../07/README.md) | [Top](../README.md) | [More About Functions](../09/README.md)

## 8: Loops

Let's now extend the previous code fragment to see how it could be used to control a loop.  The condition we just looked at is now used to perform a basic loop that does something 5 times:

```wat
(local %counter i32)  ;; Remember, local variables are automatically initialised to zero

(loop $do_it_again
  ;; As long as the limit is greater than the counter, proceed with the loop
  ;; Comparison statements leave an i32 value on the top of the stack.
  ;; If the top of the stack is [0], then this means false.
  ;; Any other value means true
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

* ***Check for Termination***  
   Most languages assume that the loop should continue, then repeatedly ask "*Should I stop now?*".

   That's fine and you could certainly structure a loop this way in WAT...
   
* ***Check for Continuation***  
   In WAT however, it is more idiomatic to assume that the loop should **not** continue, then repeatedly ask "*Should I continue?*".

   If the loop should continue, we enter the `then` block and do whatever needs to be done.  At the end of the `then` block there is an explicit branch `br` statement that jumps back to the start of the loop.

   Under all other conditions, we simply drop out at the bottom of the loop.