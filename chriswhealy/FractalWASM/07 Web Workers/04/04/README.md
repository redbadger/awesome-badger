# Plotting Fractals in WebAssembly

| Previous | | Next
|---|---|---
| [6: Zooming In](../../../06%20Zoom%20Image/) | [Top](/2021/12/07/plotting-fractals-in-webassembly.html) |
| [7.2 Schematic Overview](../../02/) | [7: WebAssembly and Web Workers](../../) |
| [7.4.3 Create Web Workers](../03/)  | [7.4: Adapt the Main Thread Coding](../) | [7.4.5 Adapt WebAssembly Function `mj_plot`](../05/)

### 7.4.4: Send/Receive Web Worker Messages

### Receiving Web Worker Messages

After each worker instance is created, we attach the function `worker_msg_handler` to handle any completion messages received from the workers.  This function does the following:

1. Like all Web Worker message handlers, it receives an object argument having a property called `data`.  This property is destructured to obtain the `action` and  `payload` properties, then `payload` is further destructured obtain the details of the worker thread that sent the message.
1. If the `action` is `exec_complete`, then the `plot_time.wCount` counter is incremented
1. Unless the `plot_time.wCount` counter indicates that all the worker threads have finished, then nothing further happens
1. If all the worker threads have finished, then the end time is recorded, the image data is transferred from WebAssembly shared memory to the `canvas`, the counters and activity flag are reset and most importantly, the `i32` pixel counters in shared memory are reset to 0.

   We are now ready to plot another fractal image.

As previously stated, only the essential parts of the code are shown here:

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Create WASM memory object for sharing resources from the host environment
const totalMemPages = mImagePages + jImagePages + palettePages

const wasmMemory = new WebAssembly.Memory({
  initial : totalMemPages,
  maximum : totalMemPages,
  shared : true,
})

const wasmMem8  = new Uint8ClampedArray(wasmMemory.buffer)
const wasmMem32 = new Uint32Array(wasmMemory.buffer)

// Record worker thread activity
let plot_time = { start : 0, end : 0, wCount : 0, isActive : false }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Handle message received from worker thread
const worker_msg_handler = ({ data }) => {
  const { action, payload } = data
  const { worker_id, fractal, times } = payload

  switch(action) {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // One of the workers has finished
    case 'exec_complete':
      plot_time.wCount += 1

      // Have all the workers finished yet?
      if (plot_time.wCount === WORKERS) {
        plot_time.end = performance.now()

        switch(fractal) {
          case "mb":
            mImage.data.set(wasmMem8.slice(mImageStart, mImageEnd))
            mContext.putImageData(mImage,0,0)

            break

          case "julia":
            jImage.data.set(wasmMem8.slice(jImageStart, jImageEnd))
            jContext.putImageData(jImage,0,0)

            break

          default:
        }

        // Reset X,Y iteration counters in shared memory
        wasmMem32[0] = 0x00000000
        wasmMem32[1] = 0x00000000

        plot_time.wCount   = 0
        plot_time.isActive = false
      }

    default:
  }
}
```

### Sending Web Worker Messages

We already have a JavaScript function called `draw_fractal` that previously called the WebAssembly `mj_plot` directly.  Now that the main thread has delegated this task to the worker threads, we need to adapt this function to send an `exec` message to each of the worker threads.

The only additional consideration is that we must now take into account the fact that plotting a fractal image might be slow.  Given that we are attempting to plot a new Julia Set every time the mouse pointer moves, it is perfectly possible that multiple `mousemove` events might be triggered before the first Julia Set has been plotted.  Therefore, we must avoid triggering a new image calculation before the previous one has finished.  This is the purpose of `plot_time.isActive` flag.

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// As long as a calculation is not currently running, send a message to every worker to start drawing a new fractal image
const draw_fractal = (p_name, p_zx, p_zy) => {
  if (!plot_time.isActive) {
    plot_time.wCount   = 0
    plot_time.isActive = true
    plot_time.start    = performance.now()

    // Invoke all the workers
    worker_list.map((w, idx) => {
      $id(`w${idx}_cell1`).style.backgroundColor = GREEN
      w.postMessage(gen_worker_msg('exec', idx, p_name, p_zx, p_zy))
    })
  }
}
```

Notice that we record the start time just before sending the `exec` message to each worker thread; however, when this loop finishes, we do ***not*** record the end time.  This is because we are asking another thread to perform an asynchronous task, and just because we have sent all the messages, does not mean that the worker threads have finished.

We will only know that a worker thread has finished when we receive its `exec_complete` message.  Only after all the worker threads have finished, do we record the end time.  This functionality is found in the `worker_msg_handler` function shown above.
