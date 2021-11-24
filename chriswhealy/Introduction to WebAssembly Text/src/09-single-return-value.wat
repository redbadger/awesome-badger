(func $mag           ;; Internal name
  (export "mag")     ;; External name
  (param $real f64)
  (param $imag f64)
  (result f64)

  ;; Find the square root of the top value on the stack, then push the result
  ;; back onto the stack
  (f64.sqrt
    ;; Pop the top two value off the stack, add them up and push the result back
    ;; onto the stack
    (f64.add
      ;; Square the real part and push the result onto the stack
      (f64.mul (local.get $real) (local.get $real))

      ;; Square the imaginary part and push the result onto the stack
      (f64.mul (local.get $imag) (local.get $imag))
    )
  )

  ;; When we exit the function, the stack has a single f64 value left behind by
  ;; the square root instruction.  This then becomes the function's implicit
  ;; return value
)
