| Previous | | Next
|---|---|---
| [2: Initial Implementation](../../02%20Initial%20Implementation/) | [Up](../) | 
| [3.3: Generate the Colour Palette](../03/) | [3: Basic WAT Implementation](../) | [3.5: Calculating the Mandelbrot Set Image](../05/)

## 3.4: Escape-Time Algorithm

The next function we need to write is the escape-time algorithm that actually calculates the iteration value of a given pixel in the fractal image.  To start with, we will not worry about performance optimisations &mdash; these will be added later.

Since this particular algorithm can be used for plotting either the Mandelbrot or Julia Sets, we need a function whose signature is appropriate for either fractal.  This does mean however, that when plotting the Mandelbrot Set, two of the argument values will always be zero.

| Argument | Description | Notes
|---|---|---
| `$zx` | Real part of Iterated value | For the Mandelbrot Set, `z` always starts at 0
| `$zy` | Imaginary part of iterated value | For the Mandelbrot Set, `z` always starts at 0
| `$cx` | Pixel X coordinate (real part) | Caller must transform pixel location to a coordinate
| `$cy` | Pixel Y coordinate (imaginary part) | Caller must transform pixel location to a coordinate
| `$max_iters` | Iteration limit |

If you have read [§8](Introduction%20to%20WebAssembly%20Text/08/) on Loops from the blog series [Introduction to WebAssembly Text](Introduction%20to%20WebAssembly%20Text/), then you will remember that the idiomatic way to write a loop in WebAssembly Text is to assume that the loop will finish then test for continuation, rather than assuming the loop will repeat, then testing for termination.

This coding style is used here.

This function takes two complex numbers `z` and `c` and repeatedly squares `z` and adds `c` until one of the continuation conditions become false.  However, since WebAssembly has no complex number datatype, the real and imaginary parts of the complex arguments `z` and `c` are supplied as two pairs of `f64`s: `zx` and `zy`, and `cx` and `cy`.

```wat
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; Escape time algorithm for calculating either the Mandelbrot or Julia sets
;; Iterates z[n]^2 + c => z[n+1]
(func $escape_time_mj
      (param $zx f64)
      (param $zy f64)
      (param $cx f64)
      (param $cy f64)
      (param $max_iters i32)
      (result i32)

  (local $iters i32)
  (local $zx_sqr f64)
  (local $zy_sqr f64)

  (loop $next_iter
    ;; Remember the squares of the current $zx and $zy values
    (local.set $zx_sqr (f64.mul (local.get $zx) (local.get $zx)))
    (local.set $zy_sqr (f64.mul (local.get $zy) (local.get $zy)))

    ;; Only continue the loop if we're still within both the bailout value and the iteration limit
    (if
      ;; ($BAILOUT > ($zx_sqr + $zy_sqr)) AND ($max_iters > iters)?
      (i32.and
        (f64.gt (global.get $BAILOUT) (f64.add (local.get $zx_sqr) (local.get $zy_sqr)))
        (i32.gt_u (local.get $max_iters) (local.get $iters))
      )
      (then
        ;; $zy = $cy + (2 * $zy * $zx)
        ;; $zx = $cx + ($zx_sqr - $zy_sqr)
        (local.set $zy (f64.add (local.get $cy) (f64.mul (local.get $zy) (f64.add (local.get $zx) (local.get $zx)))))
        (local.set $zx (f64.add (local.get $cx) (f64.sub (local.get $zx_sqr) (local.get $zy_sqr))))
        
        (local.set $iters (i32.add (local.get $iters) (i32.const 1)))
        
        br $next_iter
      )
    )
  )
  
  (local.get $iters)
)
```

Certain optimisations have been added to avoid the need for either expensive function calls or repetitive calculations.

For instance, testing the magnitude of a complex number requires the use of the Pythagorean formula (`a = sqrt(b^2 + c^2)`).  Not only is the call to `sqrt` expensive, but in our case, it is actually unnecessary since we only need to check that the sum of the squares (`a^2 + b^2`) is less than the square of the bailout value.  Hence the global value `$BAILOUT` is set to `4` not `2`
