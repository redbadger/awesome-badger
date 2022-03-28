(func $mag           ;; Internal name
  (export "mag")     ;; External name
  (param $real f64)  ;; 1st argument is an f64 known as $real
  (param $imag f64)  ;; 2nd argument is an f64 known as $imag
  (result f64)       ;; One f64 will be left on the stack

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
)
