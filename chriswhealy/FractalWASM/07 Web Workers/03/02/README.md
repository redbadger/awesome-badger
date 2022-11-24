# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [6: Zooming In](../../06%20Zoom%20Image/) | [7: WebAssembly and Web Workers](../)  |
| [7.2 Schematic Overview](../02/) | 7.3 Create Web Workers | [7.4 Adapt the Main Thread Coding](../04/)
| [7.3.1 Define the Message Structure](../01/) | 7.3.2 Implement the `onmessage` Event Handler |

### 7.3.2 Implement the `onmessage` Event Handler

In our case, the `onmessage` event handler will simply be a `switch` statement that can respond to a known set of messages.

The first thing to do is extract the `action` and `payload` properties from the `data` property of the argument object.
The easiest way to do this is by means of a destructuring assignment.

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Inbound message handler
onmessage = async ({ data }) => {
  const { action, payload } = data

  switch(action) {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Create WebAssembly module instance and draw initial Mandelbrot Set
    case 'init':
      // snip...
      break

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Draw a fractal image
    case 'exec':
      // snip...
      break

    default:
  }
}
```

#### Worker Global Variables and Helper Functions

The following global variables and helper functions are also needed:

```javascript
let my_worker_id
let wasmObj

// Record initialisation and execution times
let times = {
  init : { start : 0, end : 0 },
  exec : { start : 0, end : 0 },
}

const gen_msg_exec_complete = (worker_id, name, times) => ({
  action : 'exec_complete',
  payload : {
    worker_id : worker_id,
    fractal : name,
    times : times,
  }
})

const draw_fractal = (fractal, max_iters) => {
  let start = performance.now()

  wasmObj.instance.exports.mj_plot(
    fractal.width,         fractal.height,
    fractal.origin_x,      fractal.origin_y,
    fractal.zx,            fractal.zy,
    fractal.ppu,           max_iters,
    fractal.is_mandelbrot, fractal.img_offset
  )

  return { "start" : start, "end": performance.now() }
}
```

In order to extract the relevant values from the `data.payload` object, we need to add a further destructuring statement at the start of the `onmessage` event handler:

```javascript
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Inbound message handler
onmessage = async ({ data }) => {
  const { action, payload } = data
  let { host_fns, worker_id, fractal, max_iters } = payload

  switch(action) {
    // snip...
  }
}
```

#### Handle the `init` Message

When a worker thread receives an `init` message, the worker:

1. Remembers its `worker_id`
1. Instantiates its own copy of the WebAssembly module, passing in the reference to the block of shared memory created by the main thread
1. Calls `mj_plot` to draw the initial image of the Mandelbrot Set
1. Sends a completion message back to the main thread

```javascript
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Create WebAssembly module instance and draw initial Mandelbrot Set
  case 'init':
    my_worker_id = worker_id

    times.init.start = performance.now()
    wasmObj = await WebAssembly.instantiateStreaming(fetch('./mj_plot.wasm'), host_fns)
    times.init.end = performance.now()

    // Draw initial Mandelbrot Set
    times.init = draw_fractal(fractal, max_iters)
    postMessage(gen_msg_exec_complete(worker_id, "mb", times))

    break
```

#### Handle the `exec` Message

When a worker thread receives an `exec` message, it simply calls `mj_plot` to draw the request fractal image, then sends a completion message back to the main thread.

```javascript
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Draw a fractal image
  case 'exec':
    times.exec = draw_fractal(fractal, max_iters)
    postMessage(gen_msg_exec_complete(my_worker_id, fractal.name, times))
```
