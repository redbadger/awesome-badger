# Plotting Fractals in WebAssembly

| Previous | | Next
|---|---|---
| [6: Zooming In](../../06%20Zoom%20Image/) | [Top](/2021/12/07/plotting-fractals-in-webassembly.html) |
| [7.2 Schematic Overview](../02/) | [7: WebAssembly and Web Workers](../) | [7.4 Adapt the Main Thread Coding](../04/)

### 7.3 Create the Web Worker

The coding for a Web Worker needs to be in a separate file from the main thread, so we will create a file called `worker.js`.

In order for a worker to react to messages from the main thread, you must follow these minimal requirements:

1. Create an asynchronous event handler method called `onmessage`
1. In order to process a message, extract the `data` property of the message passed to the `onmessage` event handler, then take whatever action is appropriate for that given message
1. Typically, the worker will send some sort of completion message back to the main thread.  The worker does this by calling its `postMessage` method and sending whatever data is needed as a response.

```javascript
onmessage = async ({ data }) => {
  // Do something with the contents of data

  postMessage(/* some sort of message data */)
}
```

Beyond this, you can implement almost any other coding you like within the worker.

Here, the coding for our Web Worker will be quite straight forward.  It is simply handles messages received from the main thread.

1. [Define the Message Structure](./01/)
1. [Implement the `onmessage` Event Handler](./02/)
