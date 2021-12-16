| Previous | | Next
|---|---|---
| [6: Zooming In](../../06%20Zoom%20Image/) | [Up](../../) | 
| [7.2 Schematic Overview](../02/) | [7: WebAssembly and Web Workers](../) | [7.4 Adapt the Main Thread Coding](../04/)

### 7.3 Create the Web Worker

The coding for a Web Worker needs to be in a separate file from the main thread coding.  so we will create a file called `worker.js`.

In order for a worker to interact with a main thread, you must follow these minimal requirements:

1. Create an asynchronous event handler method called `onmessage`
1. `onmessage` will be passed an object containing a property called `data`

```javascript
onmessage = async ({ data }) => {
}
```

Beyond this, you can implement almost any other coding you like within the worker.

Here, the coding for our Web Worker will be quite straight forward.  It is simply handles messages received from the main thread.

1. [Define the Message Structure](./01/)
1. [Implement the `onmessage` Event Handler](./02/)
