(module
  (import "js" "shared_mem" (memory 24))

  (global $image_offset   (import "js" "image_offset")   i32)
  (global $palette_offset (import "js" "palette_offset") i32)

  (global $BAILOUT f64 (f64.const 4.0))
  (global $BLACK   i32 (i32.const 0xFF000000))

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Derive a colour component from supplied iteration and threshold values
  (func $8_bit_clamp
    (param $n i32)
    (param $threshold i32)
    (result i32)
    (local $temp i32)

    ;; Add colour-specific threshold, then mask out all but the junior 10 bits
    ;; $temp = ($n + $threshold) & 1023
    (local.set $temp (i32.and (i32.add (local.get $n) (local.get $threshold)) (i32.const 1023)))

    ;; How many bits does $temp use?
    (if (result i32)
      ;; At least 9 bits
      (i32.ge_u (local.get $temp) (i32.const 256))
      (then
        ;; If bit 10 is switched off invert value, else return zero
        (if (result i32)
          (i32.lt_u (local.get $temp) (i32.const 512))
          (then (i32.sub (i32.const 510) (local.get $temp)))
          (else (i32.const 0))
        )
      )
      (else (local.get $temp))
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Generate colour components
  (func $red   (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 0)))
  (func $green (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 128)))
  (func $blue  (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 356)))

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Transform an iteration value to an ABGR colour
  (func $colour
    (param $iter i32)
    (result i32)
    (local $iter4 i32)
    (local.set $iter4 (i32.shl (local.get $iter) (i32.const 2)))

    ;; Little-endian processor requires the colour component values in ABGR order, not RGBA
    (i32.or
      (i32.or
        (i32.const 0xFF000000)   ;; Fully opaque
        (i32.shl (call $blue (local.get $iter4)) (i32.const 16))
      )
      (i32.or
        (i32.shl (call $green (local.get $iter4)) (i32.const 8))
        (call $red (local.get $iter4))
      )
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Generate entire colour palette
  (func (export "gen_palette")
        (param $max_iters i32)

    (local $idx i32)

    (loop $next
      (if (i32.gt_u (local.get $max_iters) (local.get $idx))
        (then
          (i32.store
            (i32.add (global.get $palette_offset) (i32.shl (local.get $idx) (i32.const 2)))
            (call $colour (local.get $idx))
          )
          (local.set $idx (i32.add (local.get $idx) (i32.const 1)))
          (br $next)
        )
      )
    )
  )

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
        (i32.and
          ;; $BAILOUT > ($zx_sqr + $zy_sqr)?
          (f64.gt (global.get $BAILOUT) (f64.add (local.get $zx_sqr) (local.get $zy_sqr)))

          ;; $max_iters > iters?
          (i32.gt_u (local.get $max_iters) (local.get $iters))
        )
        (then
          ;; $zy = $cy + (2 * $zy * $zx)
          (local.set $zy (f64.add (local.get $cy) (f64.mul (local.get $zy) (f64.add (local.get $zx) (local.get $zx)))))
          ;; $zx = $cx + ($zx_sqr - $zy_sqr)
          (local.set $zx (f64.add (local.get $cx) (f64.sub (local.get $zx_sqr) (local.get $zy_sqr))))

          (local.set $iters (i32.add (local.get $iters) (i32.const 1)))

          br $next_iter
        )
      )
    )

    (local.get $iters)
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Main cardioid check
  (func $is_in_main_cardioid
        (param $x f64)
        (param $y f64)
        (result i32)
    (local $x_minus_qtr f64)
    (local $y_sqrd      f64)
    (local $q           f64)

    (local.set $x_minus_qtr (f64.sub (local.get $x) (f64.const 0.25)))
    (local.set $y_sqrd      (f64.mul (local.get $y) (local.get $y)))

    ;; Intermediate value $q = ($x - 0.25)^2 + $y^2
    (local.set $q (f64.add (f64.mul (local.get $x_minus_qtr) (local.get $x_minus_qtr)) (local.get $y_sqrd)))

    ;; Main cardioid check: $q * ($q + ($x - 0.25)) <= $y^2 / 4
    (f64.le
      (f64.mul (local.get $q) (f64.add (local.get $q) (local.get $x_minus_qtr)))
      (f64.mul (f64.const 0.25) (local.get $y_sqrd))
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Plot Mandelbrot set
  (func (export "mandel_plot")
        (param $width i32)          ;; Canvas width
        (param $height i32)         ;; Canvas height
        (param $origin_x f64)       ;; X origin coordinate
        (param $origin_y f64)       ;; Y origin coordinate
        (param $ppu i32)            ;; Pixels per unit (zoom level)
        (param $max_iters i32)      ;; Maximum iteration count
    (local $x_pos i32)
    (local $y_pos i32)
    (local $cx f64)
    (local $cy f64)
    (local $cx_int f64)
    (local $cy_int f64)
    (local $pixel_offset i32)
    (local $pixel_val i32)
    (local $ppu_f64 f64)
    (local $half_width f64)
    (local $half_height f64)

    (local.set $half_width  (f64.convert_i32_u (i32.shr_u (local.get $width) (i32.const 1))))
    (local.set $half_height (f64.convert_i32_u (i32.shr_u (local.get $height) (i32.const 1))))

    (local.set $pixel_offset (global.get $image_offset))
    (local.set $ppu_f64 (f64.convert_i32_u (local.get $ppu)))

    ;; Intermediate X and Y coords based on static values
    ;; $origin - ($half_dimension / $ppu)
    (local.set $cx_int (f64.sub (local.get $origin_x) (f64.div (local.get $half_width) (local.get $ppu_f64))))
    (local.set $cy_int (f64.sub (local.get $origin_y) (f64.div (local.get $half_height) (local.get $ppu_f64))))

    (loop $rows
      ;; Continue plotting rows?
      (if (i32.gt_u (local.get $height) (local.get $y_pos))
        (then
          ;; Translate y position to y coordinate
          (local.set $cy
            (f64.add
              (local.get $cy_int)
              (f64.div (f64.convert_i32_u (local.get $y_pos)) (local.get $ppu_f64))
            )
          )

          (loop $cols
            ;; Continue plotting columns?
            (if (i32.gt_u (local.get $width) (local.get $x_pos))
              (then
                ;; Translate x position to x coordinate
                (local.set $cx
                  (f64.add
                    (local.get $cx_int)
                    (f64.div (f64.convert_i32_u (local.get $x_pos)) (local.get $ppu_f64))
                  )
                )

                ;; Store the current pixel's colour using the value returned from the following if expression
                (i32.store
                  (local.get $pixel_offset)
                  (if (result i32)
                    ;; Can we avoid running the escape-time algorithm?
                    (call $early_bailout (local.get $cx) (local.get $cy))
                    ;; Yup, so we know this pixel will be black
                    (then (global.get $BLACK))
                    ;; Nope, we can't bail out early
                    (else
                      (if (result i32)
                        ;; Does the current pixel hit max_iters?
                        (i32.eq
                          (local.get $max_iters)
                          ;; Calculate the current pixel's iteration value and store in $pixel_val
                          (local.tee $pixel_val
                            (call $escape_time_mj
                              (f64.const 0) (f64.const 0)
                              (local.get $cx) (local.get $cy)
                              (local.get $max_iters)
                            )
                          )
                        )
                        ;; Yup, so return black
                        (then (global.get $BLACK))
                        ;; Nope, so return whatever colour corresponds to this iteration value
                        (else
                          ;; Push the relevant colour from the palette onto the stack
                          (i32.load
                            (i32.add (global.get $palette_offset) (i32.shl (local.get $pixel_val) (i32.const 2)))
                          )
                        )
                      )
                    )
                  )
                )

                ;; Increment column and memory offset counters
                (local.set $x_pos (i32.add (local.get $x_pos) (i32.const 1)))
                (local.set $pixel_offset (i32.add (local.get $pixel_offset) (i32.const 4)))

                br $cols
              )
            )
          ) ;; end of $cols loop

          ;; Reset column counter and increment row counter
          (local.set $x_pos (i32.const 0))
          (local.set $y_pos (i32.add (local.get $y_pos) (i32.const 1)))

          br $rows
        )
      )
    ) ;; end of $rows loop
  )
)
