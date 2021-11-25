;; Conjugate of a complex number
;; conj(a+bi) => (a-bi)
(func $conj                     ;; Internal name
  (export "conj")               ;; External name
  (param $a f64)                ;; 1st argument is an f64 known as $a
  (param $b f64)                ;; 2nd argument is an f64 known as $b
  (result f64 f64)              ;; Two f64s will be left behind on the stack

  (local.get $a)                ;; Push $a. Stack = [$a]
  (f64.neg (local.get $b))      ;; Push $b then negate its value.  Stack = [-$b, $a]
)
