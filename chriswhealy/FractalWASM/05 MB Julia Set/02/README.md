| Previous | | Next
|---|---|---
| [4: Optimised WAT Implementation](../../04%20WAT%20Optimised%20Implementation/README.md) | [Up](../../README.md) | 
| [5.1 Web Page Changes](../01/README.md) | [5: Plotting a Julia Set](../README.md) | 

### 5.2: WebAssembly Changes

Our existing WebAssembly function `mandel_plot` is already very close to what we need for plotting a Julia Set.  The only changes needed are:

#### Rename Function To `mj_plot`

Since the function that calculates a fractal image is now a dual-purpose, this should be reflected in the name.

```wat
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; Plot Mandelbrot or Julia set
(func (export "mj_plot")

  ;; snip...
```

#### Supply Function `mj_plot` With Additional Arguments

When we were only plotting the Mandelbrot Set, we didn't care about what type of image we were plotting, or where the mouse pointer was located over that image.  However, in order to plot a Julia Set, we now need to know some extra values:

1. The mouse pointer's coordinates are supplied as two `f64` values called `zx` and `zy`
1. A Boolean argument called `is_mandelbrot` to say whether a Mandelbrot or Julia Set calculation is performed[^1]
1. An `i32` argument holding the offset in memory where the particular image data starts.[^2]

The function signature has now expanded and looks like this:

```wat
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; Plot Mandelbrot or Julia set
(func (export "mj_plot")
       (param $width i32)         ;; Canvas width
       (param $height i32)        ;; Canvas height
       (param $origin_x f64)      ;; X origin coordinate
       (param $origin_y f64)      ;; Y origin coordinate
       (param $zx f64)            ;; Mouse X coordinate in Mandelbrot Set
       (param $zy f64)            ;; Mouse Y coordinate in Mandelbrot Set
       (param $ppu i32)           ;; Pixels per unit (zoom level)
       (param $max_iters i32)     ;; Maximum iteration count
       (param $is_mandelbrot i32) ;; Are we plotting the Mandelbrot Set?
       (param $image_offset i32)  ;; Shared memory offset of image data
```

#### Skip Early Bailout Check For Julia Sets

The test for early bailout only applies when plotting Mandelbrot Set; therefore, before checking this, we must first test which type of fractal is being plotted.

Previously, we arbitrarily checked for early bailout, but now this check should only be performed if the `$is_mandelbrot` flag is also switched on.  henece the two values are `AND`ed together below:

```wat
;; Store the current pixel's colour using the value returned from the following if expression
(i32.store
  (local.get $pixel_offset)
    (if (result i32)
      ;; If we're plotting the Mandelbrot Set, can we avoid running the escape-time algorithm?
      (i32.and
        (local.get $is_mandelbrot)
        (call $early_bailout (local.get $cx) (local.get $cy))
      )
```

#### Swap Argument Order

Maybe there's a glitch in my implementation, but when plotting the Julia Set, I found that the order of the first two pairs of arguments to function `escape_time_mj` need to be swapped around, otherwise it plots a strange hybrid Mandelbrot/Julia image.

Hence the call to `escape_time_mj` contains an `if` expression that reverses the order in which the `zx`, `zy` and `cx`, `cy` argument pairs are pushed onto the stack.

```wat
(local.tee $pixel_val
  ;; Reverse argument order for function $escape_time_mj when plotting Julia Set
  (call $escape_time_mj
    (if (result f64 f64 f64 f64 i32)
      (local.get $is_mandelbrot)
      (then
        (local.get $zx) (local.get $zy)
        (local.get $cx) (local.get $cy)
        (local.get $max_iters)
      )
      (else
        (local.get $cx) (local.get $cy)
        (local.get $zx) (local.get $zy)
        (local.get $max_iters)
      )
    )
  )
)
```






[^1]: This is needed because the performance optimisation to check whether a point lies in the main cardioid or the period 2 bulb is only relevant for the Mandelbrot Set
[^2]: Now that function `mj_plot` is used to plot both types of fractal, it is simpler to supply the memory offset at which the image data should be written as an argument, rather than trying to decide which of several possible memory offsets should be used that have been supplied from the host environment.