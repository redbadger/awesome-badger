# Plotting Fractals in WebAssembly

| Previous | | Next
|---|---|---
| [3: Basic WAT Implementation](../../03%20WAT%20Basic%20Implementation/) | [Top](/chriswhealy/plotting-fractals-in-webassembly) | [5: Plotting a Julia Set](../../05%20MB%20Julia%20Set/)
| | [4: Optimised WAT Implementation](../) | [4.2 Modify Render Loop](../02/)

### 4.1: Check for Early Bailout

#### Main Cardioid Check

To check whether the current location on the complex plane falls within the Mandelbrot Set's main cardioid, we must first derive an intermediate value `q` from the `x` and `y` coordinates of the current pixel.
In JavaScript, we do that as follows:

```javascript
q = (x - 0.25)^2 + y^2
```

Then test the following equality:

```javascript
q * (q + (x - 0.25)) <= y^2 / 4
```

If this returns true, then the point lies within the main cardioid and there is no point running the escape-time algorithm.

So, let's now write a WAT function that implements this check.

If you've read the [Introduction to WebAssembly Text](../../../Introduction%20to%20WebAssembly%20Text/), you'll remember that in [§7](../../../Introduction%20to%20WebAssembly%20Text/07/) we saw how WebAssembly uses `i32` values as Booleans: where zero means `false`, and any non-zero value means `true`.
Hence, the `i32` returned by this function can be treated as a Boolean:

```wast
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; Main cardioid check
(func $is_in_main_cardioid
      (param $x f64)
      (param $y f64)
      (result i32)

  (local $x_minus_qtr f64)
  (local $y_sqrd f64)
  (local $q f64)

  (local.set $x_minus_qtr (f64.sub (local.get $x) (f64.const 0.25)))
  (local.set $y_sqrd      (f64.mul (local.get $y) (local.get $y)))

  ;; Intermediate value $q = ($x - 0.25)^2 + $y^2
  (local.set $q
    (f64.add (f64.mul (local.get $x_minus_qtr) (local.get $x_minus_qtr))
             (local.get $y_sqrd)
    )
  )

  ;; Main cardioid check: $q * ($q + ($x - 0.25)) <= $y^2 / 4
  (f64.le
    (f64.mul (local.get $q) (f64.add (local.get $q) (local.get $x_minus_qtr)))
    (f64.mul (f64.const 0.25) (local.get $y_sqrd))
  )
)
```

#### Period 2 Bulb Check

To check whether the current location on the complex plane falls within the period 2 bulb, we test the following equality.
Again, in JavaScript, this is:

```javascript
(x + 1)^2 + y^2 <= 0.0625
```

Here's the WebAssembly function that implements this check:

```wast
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; Period 2 bulb check: ($x + 1)^2 + $y^2 <= 0.0625
(func $is_in_period_two_bulb
      (param $x f64)
      (param $y f64)
      (result i32)
  (local $x_plus_1 f64)
  (local.set $x_plus_1 (f64.add (local.get $x) (f64.const 1.0)))

  (f64.le
    (f64.add
      (f64.mul (local.get $x_plus_1) (local.get $x_plus_1))
      (f64.mul (local.get $y) (local.get $y))
    )
    (f64.const 0.0625)
  )
)
```

#### Early Bailout Check

Finally, we can combine these two functions into a simple check for early bailout

```wast
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; Check for early bailout
(func $early_bailout
      (param $x f64)
      (param $y f64)
      (result i32)
  (i32.or
    (call $is_in_main_cardioid   (local.get $x) (local.get $y))
    (call $is_in_period_two_bulb (local.get $x) (local.get $y))
  )
)
```
