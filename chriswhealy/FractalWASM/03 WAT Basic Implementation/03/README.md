| Previous | | Next
|---|---|---
| [Initial Implementation](../../02%20Initial%20Implementation/README.md) | [Top](../../README.md) | 
| [Create the WebAssembly Module](../02/README.md) | [Up](../README.md) | [Escape-Time Algorithm](../04/README.md)

## 3.3: Generate the Colour Palette

### Transform an Iteration Value to an RGBA[^1] Colour Value
The coding that generates the colour palette does not need to be described in detail, suffice it to say that a single iteration value can be translated into the red, green and blue colour components by multiplying it by 4 (implemented as a shift left instruction), then passing it through an algorithm that derives an 8-bit value for each colour component using fixed thresholds.[^2]

All of the coding that follows lives within the `module` defined in `mandel_plot.wat`

```wat
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
```

With this 8-bit clamp in place, we create three colour functions that use hard-coded colour thresholds:

```wat
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; Generate colour components
(func $red   (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 0)))
(func $green (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 128)))
(func $blue  (param $iter i32) (result i32) (call $8_bit_clamp (local.get $iter) (i32.const 356)))
```

Finally, we take each of the colour component values, shift them left by the appropriate number of bits, then `OR` them all together to form the 32-bit colour value.

> ***IMPORTANT***
> Due to the fact that all modern processors are [little-endian](https://en.wikipedia.org/wiki/Endianness), we must assemble the RGBA values in reverse order.

```wat
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
```

### Generate the Entire Colour Palette

This particular palette generation algorithm produces colours that are distributed evenly across their range; therefore, changes to `max_iters` will not change the overall range of colours.  However, since we need to generate a lookup table that ranges from 0 to `max_iters`, each time `max_iters` changes, we will need to regenerate the entire colour palette.

```wat
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
```

There are a couple of things to notice about this function:

1. Since this function will only be invoked from the host environment, the internal name has been omitted and only an exported name has been defined.
1. This function does not return a specific value, it writes to shared memory; therefore, it has no `result` clause.
1. In [§3.2](../02/README.md), at the start of the module we defined a global constant called `$palette_offset` whose value is imported from the host environment as property `js.palette_offset`.  This value acts as the starting point for calculating where the next `i32` colour value will be written in memory
1. The loop labeled `$next` continues until our index counter `$idx` exceeds the supplied value of `max_iters`
1. The `i32.store` instruction writes a 4 byte value to memory.  The first argument is the memory offset and the second is the value being stored.  

   So we call function `$colour`, passing in the value of `$idx`, and store the returned value at the memory location calculated from `$palette_offset + ($idx * 4)`[^3]
3. When this function exits, the block of shared memory starting at the offset defined in `$palette_offset` will contain the colours for all iteration values from 0 to `max_iters`



[^1]: RGBA stands for the four values needed to fully define a pixel's colour: Red, Green, Blue and Alpha (opacity)
[^2]: 0 for red, 128 for green, and 356 for blue
[^3]: The cheapest way to implement multiplication by a power of 2 is to perform an `i32.shl` (shift left) instruction by the relevant number of binary places
