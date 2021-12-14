| Previous | | Next
|---|---|---
| [6: Zooming In](../../06%20Zoom%20Image/) | [Up](../../) | 
| | [7: WebAssembly and Web Workers](../) | [7.2 Schematic Overview](../02/) 

### 7.1: JavaScript Web Workers

A Web Worker is a persistent unit of JavaScript coding that executes in a background thread.  This immediately has several important consequences:

1. Web Worker threads behave both in parallel with, and asynchronously from each other
1. Since a worker runs in its own thread, each has its own global context isolated from the global context of the main JavaScript
1. Information is typically exchanged between threads by means of message passing.
1. The messages sent between threads are of an entirely arbitrary structure and may contain any data suitable for your needs
1. The code within a worker thread can perform *almost* any task you require.  The most important exception here is that a worker thread has no access to the browser's DOM.  Therefore, if a worker performs a task that require a change in the UI, this information must be passed in a message back to the main thread.  The main thread then updates the UI.



