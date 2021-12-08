| Previous | | Next
|---|---|---
| [2: Initial Implementation](../../02%20Initial%20Implementation/README.md) | [Up](../README.md) | 
| [3.3: Generate the Colour Palette](../03/README.md) | [3: Basic WAT Implementation](../README.md) | [3.5: Calculating the Mandelbrot Set Image](../05/README.md)

## 3.4: Escape-Time Algorithm

The next function we need to write is the escape-time algorithm that actually calculates the iteration value of a given pixel in the fractal image.  To start with, we will not worry about performance optimisations &mdash; these will be added later.

Since this particular algorithm can be used for plotting either the Mandelbrot or Julia Sets, we need a function whose signature is appropriate for either fractal.  This does mean however, that when plotting the Mandelbrot Set, two of the argument values will always be zero.

| Argument | Description | Notes
|---|---|---
| `$mandel_x` | Current pixel X coordinate | Derived from image pixel X location
| `$mandel_y` | Current pixel Y coordinate | Derived from image pixel Y location
| `$x` | Pointer X position on Mandelbrot Set | Always zero when plotting the Mandelbrot Set
| `$y` | Pointer Y position on Mandelbrot Set | Always zero when plotting the Mandelbrot Set
| `$max_iters` | Iteration limit |

If you have read [§8](Introduction%20to%20WebAssembly%20Text/08/README.md) on Loops from the blog series [Introduction to WebAssembly Text](Introduction%20to%20WebAssembly%20Text/README.md), then you will remember that the idiomatic way to write a loop in WebAssembly Text is to assume that the loop will finish then test for continuation, rather than assuming the loop will repeat, then testing for termination.

This coding style is used here.

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
      ;; Continue as long as $BAILOUT > ($x^2 + $y^2) and $max_iters > $iters
      (i32.and
        (f64.gt (global.get $BAILOUT) (f64.add (local.get $x_sqr) (local.get $y_sqr)))
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

The mechanics of the actual calculation are not particularly important; however, there is an important difference between this function and the others we've written so far; that is, this one works with both `f64` floating point values and `i32` integer values.

The point to understand here is that we must now be careful how we use each of the local variables, because any particular instruction cannot use arguments of mixed datatype.