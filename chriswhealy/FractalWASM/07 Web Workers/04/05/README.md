| Previous | | Next
|---|---|---
| [6: Zooming In](../../../06%20Zoom%20Image/) | [Up](../../../) |
| [7.2 Schematic Overview](../../02/) | [7: WebAssembly and Web Workers](../../) |
| [7.4.4 7.4.4: Send/Receive Web Worker Messages](../04/)  | [7.4: Adapt the Main Thread Coding](../) | 

### 7.4.5: Adapt WebAssembly Function `mj_plot`

No that the UI and Web Worker side of things is done, we finally need to change function `mj_plot` to run in such a way that multiple instances of itself to do start arguing with each other, or trampling on the memory in use by another instance.

This means two fundamental changes need to be made (one of which is very simple):

1. The value of the pixel currently being plotted must be held in shared memory.

   This means that function `mj_plot` can no longer use private index counters such as `$x_pos` and `$y_pos` to keep track which row and column is currently being worked on.  Instead, the next pixel to be calculated must read from shared memory, incremented, then written back again as an ***atomic operation***.  This is known as an atomic read-modify-write operation.
   
   In this manner, multiple instances of the function `mj_plot` can read their next pixel from shared memory, increment it and write it back again without disturbing the work of any other `mj_plot` instance.
   
1. Function `mj_plot` is currently structured as a nested loop.  We first loop around all the rows in the image, then within each row, we loop around each column.  Hence the need for two internal index counters `$x_pos` and `$y_pos`.

   This is fine when there's only one instance of `mj_plot` running, but now that multiple instances of `mj_plot` will all be running in parallel, we cannot safely perform two atomic read-modify-write operations and expect the `$x_pos` and `$y_pos` values to remain related to each other.
   
   What we now need to do is store a single pixel count value in shared memory that represents the total number of pixels in the image (I.E. `$pixel_count = $width  * $height`).
   
   Each instance of `mj_plot` can then safely read-modify-write this single value.  
 
### Modifying Module `mj_plot`

In the same way that we needed to change the `memory` declaration in the `colur_palette` module, we must make the same change here in module `mj_plot.wat`

```wast
(module
  (import "js" "shared_mem" (memory 46 46 shared))
  
  ;; snip
)
```

> ***GOTCHA***
>
> If you forget to make this change, then you will not see any errors at compile time.
> 
> At runtime however, you will see this slightly-less-then-helpful error message in the browser console:
>
> `LinkError: WebAssembly.instantiate(): mismatch in shared state of memory, declared = 0, imported = 1`
> 
> This means this particular module has not declared the use of shared memory, but the memory being imported from the host environment has been created as shared
 
 
### Modifying Function `mj_plot`

The first thing we need to establish is where in shared memory will the pixel count value live?  Here, we are free to choose any locations we like - so long as everyone knows where to look!

We are also plotting two fractal images, so we need two pixel count values: one for the Mandelbrot Set and the other for the Julia Set.

For simplicity, both pixel counts will be `i32` values and live at offsets `0` and `4` for the Mandelbrot and Julia Sets respectively.

This in turn means that the Mandelbrot image data cannot start at offset `0` any more, but must be shifted down by 8 bytes.[^1]

So first we create some local variables to keep track of how many pixels need to be calculated, what the current pixel is, and where in memory can I find the next pixel value.

he following code snippets show the relevant changes to function `mj_plot`.  So right at the start, we need to add:

```wast
(local $pixel_count i32)
(local $this_pixel i32)
(local $next_pixel_offset i32)

;; How many pixels in total need to be calculated?
(local.set $pixel_count (i32.mul (local.get $width) (local.get $height)))

;; Pick up the shared memory location of the next pixel to render
;; Next Mandelbrot Set pixel - offset 0
;; Next Julia Set pixel      - offset 4
(local.set $next_pixel_offset
  (if (result i32)
    (local.get $is_mandelbrot)
    (then (i32.const 0))
    (else (i32.const 4))
  )
)
```

Previously, we used the internal `$x_pos` and `$y_pos` counters to control a nested loop:

```wast
(loop $rows
  ;; Continue plotting rows?
  (if (i32.gt_u (local.get $height) (local.get $y_pos))
  (then

    (loop $cols
      (if (i32.gt_u (local.get $width) (local.get $x_pos))
      (then
        ;; snip
      )
    ) ;; end of $cols loop
  )
) ;; end of $rows loop
```

Now, we simply have a single loop that performs an atomic read-modify-write on the next pixel value in shared memory, then converts that pixel number to the correct row and column coordinates:

```wast
(loop $pixels
  ;; Continue plotting pixels?
  (if (i32.gt_u
    (local.get $pixel_count)
    (local.tee $this_pixel
      (i32.atomic.rmw.add (local.get $next_pixel_offset) (i32.const 1))
    )
  )
  (then
    ;; Convert x position to x coordinate
    (local.set $cx
      (f64.add
        (local.get $cx_int)
        (f64.div
          ;; Derive x position from $this_pixel
          (f64.convert_i32_u (i32.rem_u (local.get $this_pixel) (local.get $width)))
          (local.get $ppu)
        )
      )
    )
    ;; Convert y position to y coordinate
    (local.set $cy
      (f64.add
        (local.get $cy_int)
          (f64.div
            ;; Derive y position from $this_pixel
            (f64.convert_i32_u (i32.div_u (local.get $this_pixel) (local.get $width)))
            (local.get $ppu)
          )
        )
      )
    )
    
    ;; snip
    
  )
) ;; end of $pixels loop
```

Notice the `i32.atomic.rmw.add` statement.  This is the read-modify-write statement that performs three operations as an atomic unit:

1. It reads an `i32` value from the offset in shared memory found in the first argument (`$next_pixel_offset`) and pushes it onto the stack
1. It then adds the value found in the second argument (`i32.const 1`)
1. The result of the addition is written back to the same location in shared memory

The result is that the original value is now on the top of the stack ready for use, and the incremented value is available in shared memory to be read and acted upon by some other thread.

Next, we convert the value of `$this_pixel` into the corresponding row (`$cy`) and column (`$cx`) coordinates using some precalculated intermediate values stored in `$cy_int` and `$cx_int`.

Now that we have derived the correct X and Y coordinates, we simply continue as before...



---
[^1]: Here's a perfect example of where, within its own memory space, a WebAssembly program is only as memory-safe as you make it.  If you accidentally write data to the wrong offset, too bad!  Other than attempting to write outside the bounds of your entire memory space, there are no boundary checks to prevent you from doing this... 😱