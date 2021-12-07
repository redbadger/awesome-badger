## 3.4: Escape-Time Algorithm

The next function to write the escape-time algorithm that actually calculates the iteration value of a given pixel in the fractal image.

To start with, we will simply implement the brute-force approach to this calculation.  Performance optimisations will be added later.

Since this particular algorithm can be used for plotting either the Mandelbrot or Julia Sets, we need a function whose signature is appropriate for either fractal.

| Argument | Description | Notes
|---|---|---
| `$mandel_x` | Current pixel X coordinate | Derived from image pixel X location
| `$mandel_y` | Current pixel Y coordinate | Derived from image pixel Y location
| `$x` | Pointer X position on Mandelbrot Set | Always zero when plotting the Mandelbrot Set
| `$y` | Pointer Y position on Mandelbrot Set | Always zero when plotting the Mandelbrot Set
| `$max_iters` | Iteration limit |


```wat
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; Escape time algorithm for calculating either the Mandelbrot or Julia sets
(func $escape_time_mj
      (param $mandel_x f64)
      (param $mandel_y f64)
      (param $x f64)
      (param $y f64)
      (param $max_iters i32)
      (result i32)

  (local $iters i32)
  (local $new_x f64)
  (local $new_y f64)
  (local $x_sqr f64)
  (local $y_sqr f64)

  (loop $next_iter
    ;; Store x^2 and y^2 values
    (local.set $x_sqr (f64.mul (local.get $x) (local.get $x)))
    (local.set $y_sqr (f64.mul (local.get $y) (local.get $y)))
    
    ;; Only continue the loop if we're still within both the bailout value and the iteration limit
    (if
      (i32.and
        ;; $BAILOUT > ($x^2 + $y^2)?
        (f64.gt
          (global.get $BAILOUT)
          (f64.add (local.get $x_sqr) (local.get $y_sqr))
        )
        ;; $max_iters > iters?
        (i32.gt_u (local.get $max_iters) (local.get $iters))
      )
      (then
        ;; $new_x = $mandel_x + ($x^2 - $y^2)
        (local.set $new_x
          (f64.add
            (local.get $mandel_x)
            (f64.sub (local.get $x_sqr) (local.get $y_sqr))
          )
        )
        ;; $new_y = $mandel_y + ($y * 2 * $x)
        (local.set $new_y
          (f64.add (local.get $mandel_y)
                   (f64.mul (local.get $y) (f64.add (local.get $x) (local.get $x)))
          )
        )
        (local.set $x (local.get $new_x))
        (local.set $y (local.get $new_y))
        (local.set $iters (i32.add (local.get $iters) (i32.const 1)))

        br $next_iter
      )
    )
  )

  (local.get $iters)
)
```

The mechanics of the actual calculation implemented here is not particularly important; however, a significant difference between this function and the others we've written so far is that this ones takes floating point `f64` arguments, not integers.