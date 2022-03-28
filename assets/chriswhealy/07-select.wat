(module
  (func (export "do_select")
        (result i32)

    (local $lower_limit i32)
    (local $upper_limit i32)
    (local $test_val i32)

    (local.set $lower_limit (i32.const 20))
    (local.set $upper_limit (i32.const 100))
    (local.set $test_val    (i32.const 40))

    (select
      (i32.const 111)   ;; Return this value if true
      (i32.const 999)   ;; Return this value if false

      ;; Is $test_val greater than $lower_limit
      (i32.gt_u (local.get $test_val) (local.get $upper_limit))
    )
  )
)
