# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [1: Plotting Fractals](../../01%20Plotting%20Fractals/) | [2: Initial Implementation](../) | [3: WAT Basic Implementation](../../03%20WAT%20Basic%20Implementation/)
| | 2.1: Basic Escape-Time Implementation | [2.2: Optimised Escape-Time Implementation](../02/)

## 2.1: Basic Escape-Time Implementation

### Basic Boundary Conditions

First, we need to define the limits that will prevent us looping forever:

```javascript
const maxIters = 1000
const bailout  = 4
```

### Helper Functions

We need a few helper functions:

* `pixel2XCoord` and `pixel2YCoord`

   These functions translate X and Y canvas positions to coordinates on the complex plane
   
* `iter2Colour`

   Transforms an iteration number into a colour

At the moment, we don't care how these helper functions have been implemented

```javascript
const maxIters = 1000
const bailout  = 4

const pixel2XCoord = pos => ...
const pixel2YCoord = pos => ...
const iter2Colour  = n   => ...
```

### Working with a `canvas` HTML ELement

Next, we need to get some information from the `canvas` HTML element:

* get a reference to the `canvas` HTML element called `mandelImage`
* get a reference to the `canvas`'s 2d context
* create an image in the 2d context the same size as the entire canvas

```javascript
const mCanvas  = document.getElementById('mandelImage')
const mContext = mCanvas.getContext('2d')
const mImage   = mContext.createImageData(mCanvas.width, mCanvas.height)
```

Next we need to create an `ArrayBuffer` large enough to hold the actual image data

```javascript
let buf = new ArrayBuffer(mImage.data.length)
```

This `ArrayBuffer` is the data structure into which we will write the image data, but we also have a bit of a problem: JavaScript does not allow direct access to the contents of an `ArrayBuffer`.

So the way we read/write data to/from an `ArrayBuffer` is by creating one or more overlay objects, or masks, that sit over top of the `ArrayBuffer`.  Then, by accessing the overlaid objects, we are able to access the contents of the `ArrayBuffer`.

```javascript
let buf8  = new Uint8ClampedArray(buf)
let buf32 = new Uint32Array(buf)
```

`buf8` gives us access to the contents of the `ArrayBuffer` as if it were an array of unsigned, 8-bit integers, and `buf32` gives up access to the `ArrayBuffer` as if it were an array of unsigned, 32-bit integers.

So we now have two different ways to look at the same block of linear memory.  We should also bear in mind that the value returned by `buf8.length` will be 4 times larger than the value returned by `buf32.length`, even though they are both reporting information about the same underlying `ArrayBuffer`.

### Calculate the Colour of Each Canvas Pixel

We now need to loop over each row in the image, and within each row, loop over each column.  Here is a badly unoptimised implementation of such a nested loop:

```javascript
for (let iy = 0; iy < mCanvas.height; ++iy) {
  for (let ix = 0; ix < mCanvas.width; ++ix) {
    // Get the iteration value of the current pixel
    let iter = escapeTime(ix, iy)

    // Translate the iteration value into a colour
    let colour = iter2Colour(iter)

    // Write the 4 bytes of colour data to the ArrayBuffer using the 32-bit overlay
    buf32[iy * mCanvas.width + ix] = colour
  }
}

// Transfer the ArrayBuffer data into the image, then display it in the canvas
mImage.data.set(buf8)
mCanvas.putImageData(mImage, 0, 0)
```

Notice what's happening here: within the loop, we use the `buf32` overlay to write 4 bytes of colour data into the `ArrayBuffer` in a single assignment; then after the loop has finished, we use the `buf8` overlay to transfer the contents of the `ArrayBuffer` into the canvas image.

Ignoring questions of efficiency for the time being, we now have a working loop structure.

### Escape Time Algorithm

The last detail is to provide an implementation of the actual escape time algorithm that calculates the iteration value of one pixel in the Mandelbrot Set

```javascript
const escapeTime = (xPixel, yPixel) => {
  let x0 = pixel2XCoord(xPixel)
  let y0 = pixel2YCoord(yPixel)
  let xTemp = 0
  let iterCount = 0
  let x = 0
  let y = 0

  while (x*x + y*y < bailout && iterCount < maxIters) {
    xTemp = x*x - y*y + x0
    y = 2*x*y + y0
    x = xTemp
    iterCount += 1
  }

  return iterCount
}
```

Here is a working version of this unoptimized [basic implementation](basic-implementation.html)

As you can see, this is not a very efficient implementation since it takes several hundred milliseconds to render the entire image.
