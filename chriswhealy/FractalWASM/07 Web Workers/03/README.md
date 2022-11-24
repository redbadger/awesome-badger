# Plotting Fractals in WebAssembly

| Previous | [Top](/chriswhealy/plotting-fractals-in-webassembly) | Next
|---|---|---
| [6: Zooming In](/chriswhealy/FractalWASM/06%20Zoom%20Image/) | [7: WebAssembly and Web Workers](/chriswhealy/FractalWASM/07%20Web%20Workers/)  |
| [7.2 Schematic Overview](/chriswhealy/FractalWASM/07%20Web%20Workers/02/) | 7.3 Create Web Workers | [7.4 Adapt the Main Thread Coding](/chriswhealy/FractalWASM/07%20Web%20Workers/04/)
| | | [7.3.1: Define the Message Structure](/chriswhealy/FractalWASM/07%20Web%20Workers/03/01/)

### 7.3 Create Web Workers

The coding for a Web Worker needs to be in a separate file from the main thread, so we will create a file called `worker.js`.

In order for a worker to react to messages from the main thread, you must follow these minimal requirements:

1. Create an asynchronous event handler function called `onmessage`
1. In order to process a message, extract the `data` property of the argument passed to the `onmessage` event handler, then take whatever action is appropriate for that given message
1. Typically, the worker will send some sort of completion message back to the main thread.
   The worker does this by calling its `postMessage` method and sending whatever data is needed as a response.

```javascript
onmessage = async ({ data }) => {
  // Do something with the contents of data

  // Report the success/failure of this action to your parent process
  // This could either be the main thread or some other Web Worker
  postMessage(/* some sort of message data */)
}
```

Beyond this, you can implement almost any other coding you like within the worker.

Here, the coding for our Web Worker will be quite straight forward.
It is simply handles messages received from the main thread.

1. [Define the Message Structure](./01/)
1. [Implement the `onmessage` Event Handler](./02/)
