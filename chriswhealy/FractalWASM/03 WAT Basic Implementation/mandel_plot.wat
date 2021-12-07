(module
  (import "js" "shared_mem" (memory 24))

  (global $image_offset   (import "js" "image_offset")   i32)
  (global $palette_offset (import "js" "palette_offset") i32)

  (global $BAILOUT f64 (f64.const 4.0))
  (global $BLACK   i32 (i32.const 0xFF000000))

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Utility function used for colour component generation
  (func $8_bit_clamp
    (param $n i32)
    (param $diff i32)
    (result i32)
    (local $temp i32)

    ;; Add colour-specific offset and mask out all but the junior 10 bits
    ;; $temp = ($n + $diff) & 1023
    (local.set $temp (i32.and (i32.add (local.get $n) (local.get $diff)) (i32.const 1023)))

    ;; If $temp uses at least 9 bits
    (if (result i32)
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

      ;; Should the loop be continued?
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

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Plot Mandelbrot set
  (func $mandel_plot
        (export "mandel_plot")
        (param $width i32)          ;; Canvas width
        (param $height i32)         ;; Canvas height
        (param $origin_x f64)       ;; X origin location
        (param $origin_y f64)       ;; Y origin location
        (param $ppu i32)            ;; Pixels per unit (zoom level)
        (param $max_iters i32)      ;; Maximum iteration count
    (local $x_pos i32)
    (local $y_pos i32)
    (local $x_coord f64)
    (local $y_coord f64)
    (local $temp_x_coord f64)
    (local $temp_y_coord f64)
    (local $pixel_offset i32)
    (local $pixel_val i32)
    (local $pixel_colour i32)
    (local $ppu_f64 f64)

    (local $half_width f64)
    (local $half_height f64)

    (local.set $half_width  (f64.convert_i32_u (i32.shr_u (local.get $width) (i32.const 1))))
    (local.set $half_height (f64.convert_i32_u (i32.shr_u (local.get $height) (i32.const 1))))

    (local.set $pixel_offset (global.get $image_offset))
    (local.set $ppu_f64 (f64.convert_i32_u (local.get $ppu)))

    ;; Intermediate X and Y coords based on static values
    ;; $origin - ($half_dimension / $ppu)
    (local.set $temp_x_coord (f64.sub (local.get $origin_x) (f64.div (local.get $half_width) (local.get $ppu_f64))))
    (local.set $temp_y_coord (f64.sub (local.get $origin_y) (f64.div (local.get $half_height) (local.get $ppu_f64))))

    (loop $rows
      ;; Continue plotting rows?
      (if (i32.gt_u (local.get $height) (local.get $y_pos))
        (then
          ;; Translate y position to y coordinate
          (local.set $y_coord
            (f64.add
              (local.get $temp_y_coord)
              (f64.div (f64.convert_i32_u (local.get $y_pos)) (local.get $ppu_f64))
            )
          )

          (loop $cols
            ;; Continue plotting columns?
            (if (i32.gt_u (local.get $width) (local.get $x_pos))
              (then
                ;; Translate x position to x coordinate
                (local.set $x_coord
                  (f64.add
                    (local.get $temp_x_coord)
                    (f64.div (f64.convert_i32_u (local.get $x_pos)) (local.get $ppu_f64))
                  )
                )

                ;; Check if iteration value equals max_iters
                (if (i32.eq
                      ;; Calculate the current pixel's iteration value
                      (local.tee $pixel_val
                        (call $escape_time_mj
                          (local.get $x_coord) (local.get $y_coord)
                          (f64.const 0) (f64.const 0)
                          (local.get $max_iters)
                        )
                      )
                      (local.get $max_iters)
                    )
                  (then
                    ;; Any pixel that hits $max_iters is arbitrarily set to black
                    (i32.store (local.get $pixel_offset) (global.get $BLACK))
                  )
                  (else
                    ;; Lookup the relevant colour from the palette and store it as the current image pixel
                    (i32.store
                      (local.get $pixel_offset)
                      (i32.load
                        (i32.add (global.get $palette_offset) (i32.shl (local.get $pixel_val) (i32.const 2)))
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
