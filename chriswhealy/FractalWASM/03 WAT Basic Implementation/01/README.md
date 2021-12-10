| Previous | | Next
|---|---|---
| [2: Initial Implementation](../../02%20Initial%20Implementation/) | [Up](../) | 
| | [3: Basic WAT Implementation](../) | [3.2: Create the WebAssembly Module](../02/)

## 3.1: Shared Memory

### How Much Shared Memory Do We Need?

As we have seen from the JavaScript implementation, the image displayed on the HTML `canvas` is stored in an `ArrayBuffer`.  This fact remains true irrespective of whether the fractal image has been calculated by a JavaScript program or a WebAssembly program.

We know that our `canvas` image is 800 by 450 pixels in size and that each pixel requires 4 bytes (one for each of the Red, Green and Blue values and one byte for the opacity, or alpha channel):

```javascript
800 * 450 * 4 bytes per pixel = 1,440,000 bytes
```

So we will require about one and a half megabytes to store the image.  However, we also know that WebAssembly memory can only be allocated in 64Kb pages.  Therefore, we need to calculate how many whole memory pages to allocate:

```javascript
Math.ceil(1440000 / 65536) = 22 pages
```

So, 22 memory pages of 64Kb each will be needed to store the image.

In addition to memory needed for the image, we also need to allocate some memory for the colour palette information.[^1]

The colour palette is simply a precalculated lookup table that allows us to translate an iteration value into a colour.  Assuming we limit the maximum number of iterations to 32,768 and each colour requires 4 bytes, then we will need to allocate a further 2 pages of WebAssembly memory:

```javascript
(32768 * 4) / 65536 = 2 pages
```

So in total, we need to allocate `22 + 2 = 24` memory pages.

Here's the JavaScript code to implement this in a more generic manner:

```javascript
const WASM_PAGE_SIZE = 1024 * 64

const DEFAULT_CANVAS_WIDTH  = 800
const DEFAULT_CANVAS_HEIGHT = 450

const mCanvas  = document.getElementById('mandelImage')
mCanvas.width  = DEFAULT_CANVAS_WIDTH
mCanvas.height = DEFAULT_CANVAS_HEIGHT

const mContext    = mCanvas.getContext('2d')
const mImage      = mContext.createImageData(mCanvas.width, mCanvas.height)
const mImagePages = Math.ceil(mImage.data.length / WASM_PAGE_SIZE)

const palettePages = 2

const wasmMemory = new WebAssembly.Memory({
  initial : mImagePages + palettePages
})

const wasmMem8 = new Uint8ClampedArray(wasmMemory.buffer)
```

In this case, we do not need to allocate a specific `ArrayBuffer` object, because one is created for us when we call `new WebAssembly.Memory()`.  We do however, still need to create an 8-bit, unsigned integer array to act as an overlay on this `ArrayBuffer`.

### Decide How Shared Memory Should be Used

Now that we have a block of linear memory large enough to hold both the image and the colour palette, we must decide how this block of memory is to be subdivided.  And here, we are free to follow any scheme we like &mdash; we just have to keep track of what data structures live where and be very careful not to trample on our own data!

In our case, the simplest way to do this is to say that the image data will start at offset 0 and the colour palette data will start at the full page boundary after the image data.  This does means that there will be a few bytes of wasted space, but this is not a particularly critical issue.

So we can arbitrarily define our two memory offsets to be:

```javascript
image_offset = 0
palette_offset = WASM_PAGE_SIZE * mImagePages
               = 65536 * 22
               = 1441792
```

giving a memory layout that looks like this:

![Memory Layout](Memory%20Layout.png)

### Sharing JavaScript Memory with Web Assembly

Now that we have allocated enough memory and know where within that memory our two blocks of data can be found, we can now share this memory with our WebAssembly module (that we have not written yet...)

If the host environment needs to share any of its resources with a WebAssembly module, those resources must be made available at the time the WebAssembly module is instantiated.

Sharing host resources with WebAssembly is done simply by creating a JavaScript object structured as a two layer namespace, whose property names are entirely arbitrary.  For instance, below we create an object called `host_fns` for sharing the memory and offset values we have created:

```javascript
const host_fns = {
  js : {
    shared_mem : wasmMemory,
    image_offset : 0,
    palette_offset : WASM_PAGE_SIZE * mImagePages,
  }
}
```

Now, assuming that our (as yet, unwritten) WebAssembly module lives in the same directory as the HTML file running this JavaScript code, and that it is called `mandel_plot.wasm`, then the code to instantiate this module would look like this:

```javascript
const wasmObj = await WebAssembly.instantiateStreaming(
  fetch('./mandel_plot.wasm'), // Asynchronously fetch the .wasm file
  host_fns                     // Host environment resources being shared with this module instance
)
```

Notice that instantiating a WebAssembly module requires the use of `await`; therefore, this call must be located within an asynchronous function.

---

[^1]: It is possible to avoid the need for storing colour palette information by dynamically calculating the colour value each time a pixel iteration value is calculated; however, this is not a very efficient approach because each iteration value translates to a static colour value.  Therefore, it is much more efficient to precalculate all the colour values from 1 to `max_iters` and store them in a lookup table.
