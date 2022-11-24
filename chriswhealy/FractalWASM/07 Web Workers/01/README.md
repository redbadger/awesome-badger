# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [6: Zooming In](../../06%20Zoom%20Image/) | [7: WebAssembly and Web Workers](../) |
| | 7.1: JavaScript Web Workers | [7.2 Schematic Overview](../02/)

### 7.1: JavaScript Web Workers

A Web Worker is a persistent unit of JavaScript coding that executes in a background thread.
This immediately has several important consequences:

1. Web Worker threads behave both in parallel with, and asynchronously from, each other.

1. Since a worker runs in its own thread, it has its own global context.
This is completely isolated from the global context of the main JavaScript thread.

1. Threads exchange information with each other typically through message passing.[^1]

1. The messages sent between threads are of an entirely arbitrary structure and may contain any data suitable for your needs.

1. The code within a worker thread can perform ***almost*** any task you require.

   The most important exception here is that a worker thread has no access to the browser's DOM.
   Therefore, if a worker wants to change the UI, it must inform the main thread that the UI needs to be updated, then send it the relevant data.

1. Workers communicate with the thread that created them by calling their builtin function `postMessage` and passing an arbitrary message object.

1. Any thread that creates a Web Worker needs to attach an event handler function to the worker's `onmessage` event in order to handle incoming messages from that worker.


---
[^1]: In our case however, message passing will only be used to initiate actions and report their completion.  The main thread will not receive the actual image data in a message, but through shared memory.
