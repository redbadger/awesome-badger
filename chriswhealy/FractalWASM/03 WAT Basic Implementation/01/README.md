# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [2: Initial Implementation](/chriswhealy/FractalWASM/02%20Initial%20Implementation/) | [3: Basic WAT Implementation](/chriswhealy/FractalWASM/03%20WAT%20Basic%20Implementation/) | [4: Optimised WAT Implementation](/chriswhealy/FractalWASM/04%20WAT%20Optimised%20Implementation/)
| | 3.1: Shared Memory | [3.2: Create the WebAssembly Module](/chriswhealy/FractalWASM/03%20WAT%20Basic%20Implementation/02/)

## 3.1: Shared Memory

When JavaScript and WebAssembly interact, it is typical for these two runtime environments to exchange data using a block of shared memory.


### How Much Shared Memory Do We Need?

#### Image Memory

We know that we will be using an HTML `canvas` element to display an image that is 800 by 450 pixels in size.
We also know that each pixel requires 4 bytes (one byte for each of the Red, Green and Blue values and an additional byte for the opacity, or alpha channel).
Therefore, we will need:

```javascript
800 * 450 * 4 bytes per pixel = 1,440,000 bytes
```

So to store the image alone, we will require about one and a half megabytes of memory.
However, we also know that WebAssembly allocates memory in units (or pages) of 64Kb.
Therefore, we need to calculate how many whole memory pages to allocate:

```javascript
Math.ceil(1440000 / 65536) = 22 pages
```

#### Colour Palette Memory

In addition to the memory needed for the image, we also need to allocate some memory for the colour palette.[^1]

The colour palette is simply a precalculated lookup table that allows us to translate an iteration value into an RGBA colour value.
Assuming we limit the maximum number of iterations to 32,768 and each colour requires 4 bytes, then we will need to allocate a further 2 pages of WebAssembly memory:

```javascript
(32768 colours * 4 bytes per colour) / 65536 = 2 pages
```

#### Total Memory Requirements

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

Since we are allocating memory in JavaScript, then sharing it with WebAssembly, we do not need to allocate a specific `ArrayBuffer` object because one is created for us when we call `new WebAssembly.Memory()`.[^2]

We do however, still need to create an 8-bit, unsigned integer array to act as an overlay on this `ArrayBuffer`.
This will be needed to transfer the image data from WebAssembly shared memory to the `canvas`.

### Decide How Shared Memory Should be Used

Now that we have written the JavaScript code to allocate a block of linear memory large enough to hold both the image and the colour palette, we must decide how this block of memory is to be subdivided.
And here, we are free to follow any scheme we like &mdash; we just have to keep track of what data structures live where and be very careful not to trample on our own data![^3]

In our case, the simplest way to do this is to say that the image data will start at offset 0 and the colour palette data will start at the full page boundary after the image data.
This does means there will be a few bytes of wasted space, but since we're not running on a device with very limited memory, this is not a particularly critical issue.

So we can arbitrarily define our two memory offsets to be:

```javascript
image_offset = 0
palette_offset = WASM_PAGE_SIZE * mImagePages
               = 65536 * 22
               = 1441792
```

giving a memory layout that looks like this:

![Memory Layout](/assets/chriswhealy/Memory%20Layout.png)

### Sharing JavaScript Memory with Web Assembly

The next step is to share this block of memory with our WebAssembly module (that we have not written yet...)

If the host environment has created resources that need to be shared with a WebAssembly module, those resources must be made available at the time the WebAssembly module is instantiated.

Sharing host resources with WebAssembly is done simply by creating a JavaScript object structured as a two-level namespace and whose property names are entirely arbitrary.
For instance, below we create an object called `host_fns` for sharing the memory and offset values we have created:

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
  host_fns                     // The host resources being shared with this module instance
)
```

Notice that instantiating a WebAssembly module requires the use of `await`; therefore, this call must be located within an asynchronous function.

---

[^1]: It is possible to avoid the need for storing colour palette information by dynamically calculating the colour value each time a pixel iteration value is calculated; however, this is not a very efficient approach because each iteration value translates to a static colour value.  Therefore, it is much more efficient to precalculate all the colour values from 1 to `max_iters` and store them in a lookup table.
[^2]: We will not need to deal with this particular problem here, but it is worth knowing that under certain circumstances, the `ArrayBuffer` used by JavaScript to share memory with a WebAssembly module can become invalid.  At this point, you must throw away the old JavaScript `ArrayBuffer` and allocate a new one.<br>See [this blog](https://awesome.red-badger.com/chriswhealy/memory-grow-and-arraybuffers) for details
[^3]: Pay attention here!  This a good example of where, within its own memory space, a WebAssembly program only has the memory safety you give it.  If you're not careful, you can end up writing code that tramples over top of other data structures in your own memory.
