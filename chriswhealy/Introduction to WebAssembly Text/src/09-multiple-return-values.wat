;; Conjugate of a complex number
;; conj(a+bi) => (a-bi)
(func $conj
      (export "conj")
      (param $a f64)
      (param $b f64)
      (result f64 f64)

  ;; Put the real part on the stack
  (local.get $a)

  ;; Negate the complex part then put it on the stack
  (f64.neg (local.get $b))
)
