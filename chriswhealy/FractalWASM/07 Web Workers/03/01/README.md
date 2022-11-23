# Plotting Fractals in WebAssembly

| Previous | | Next
|---|---|---
| [6: Zooming In](../../../06%20Zoom%20Image/) | [Top](/chriswhealy/plotting-fractals-in-webassembly) |
| [7.2 Schematic Overview](../../02/) | [7: WebAssembly and Web Workers](../) | [7.4 Adapt the Main Thread Coding](../../04/)
| | [7.3: Create Web Workers](../) | [7.3.2 Implement the `onmessage` Event Handler](../02/)

### 7.3.1 Define the Message Structure

We know that the `onmessage` event handler is passed an object containing a `data` property.
We now need to decide what structure to expect within this `data` property.

In our case, the main thread will send requests to the worker threads to perform various actions.
In order to complete these actions, there must be a further set of values specific to each action.
Therefore, in the above message, we will make the `data` property into an object having the following two properties:

```javascript
{ data: {
    action : <String>,
    payload : <Object>,
  },
}
```

#### Message Actions

The following table describes the communication protocol between the main thread and the worker threads.  As you can see, it's quite straight-forward.[^1]

| From | To | Action | Behaviour
|---|---|---|---
| Main thread | Worker | `init` | The worker creates its own instance of the WebAssembly module, invokes the `mj_plot` function to create the initial Mandelbrot Set image, then sends a completion message back to the main thread
| Main thread | Worker | `exec` | The worker plots the requested fractal image then sends a completion message back to the main thread
| Worker | Main Thread | `exec_complete` | The main thread counts the number of completion messages it has received.  When all workers have finished, the completed fractal image is displayed on the screen

#### Message Payload

The message payload needs to contain the sum of all properties needed by all the actions listed above.

| Payload Property | Required by Action | Description
|---|---|---
| `host_fns` | `init` | The object containing references to any host resources imported into WebAssembly
| `worker_id` | `init` | The worker thread's unique id
| `fractal` | `init`, `exec` | The details of the fractal image to be plotted
| `max_iters` | `init`, `exec` | Escape-time iteration limit

So we can now add some further properties to the structure of the `data.payload` message property:

```javascript
{ data: {
    action : <String>,
    payload {
      host_fns : <Object>,
      worker_id : <i32>,
      fractal : <Object>,
      max_iters : <i32>,
    },
  },
}
```

#### Details of the Fractal Image

Since the call to the WebAssembly function `mj_plot` has been moved from the main JavaScript thread into a worker thread, we must ensure that all the argument values needed for calling this function have been supplied within the message property `data.payload.fractal`.

```javascript
{ data: {
    action : <String>,
    payload {
      host_fns : <Object>,
      worker_id : <Int>,
      fractal : {
        width : <i32>,
        height : <i32>,
        origin_x : <f64>,
        origin_y : <f64>,
        zx : <f64>,
        zy : <f64>,
        ppu : <i32>,
        max_iters : <i32>,
        is_mandelbrot : <i32>,
        image_offset : <i32>,
      },
      max_iters : <i32>,
    },
  },
}
```

---
[^1]: Relax!  We're not writing production code here, so our message protocol does not need to include any form of error reporting.
