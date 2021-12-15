let my_worker_id
let wasmObj

let times = {
  init : { start : 0, end : 0 },
  exec : { start : 0, end : 0 },
}

const gen_msg_exec_complete = (worker_id, name, times) => ({
  status  : 'exec_complete',
  payload : {
    worker_id : worker_id,
    fractal   : name,
    times     : times,
  }
})

const draw_fractal = (fractal, max_iters) => {
  let start = performance.now()
  wasmObj.instance.exports.mj_plot(
    fractal.width,        fractal.height,
    fractal.origin_x,     fractal.origin_y,
    fractal.mandel_x,     fractal.mandel_y,
    fractal.zoom,         max_iters,
    fractal.isMandelbrot, fractal.imgOffset
  )

  return { "start" : start, "end": performance.now() }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * Worker inbound message handler
 */
onmessage = async ({ data }) => {
  const { action, payload } = data
  let { host_fns, worker_id, fractal, max_iters } = payload

  switch(action) {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Create WebAssembly module instance and draw initial Mandelbrot Set
    case 'init':
      my_worker_id = worker_id

      times.init.start = performance.now()
      wasmObj = await WebAssembly.instantiateStreaming(fetch('./mj_plot.wasm'), host_fns)
      times.init.end = performance.now()

      // Only generate the colour palette if I am worker 0
      if (worker_id === 0) {
        wasmObj.instance.exports.gen_palette(max_iters)
      }

      // Draw initial Mandelbrot Set
      times.init = draw_fractal(fractal, max_iters)
      postMessage(gen_msg_exec_complete(worker_id, "mandel", times))

      break

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // max_iters has changed
    case 'refresh_colour_palette':
      wasmObj.instance.exports.gen_palette(max_iters)
      break

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Draw a fractal image
    case 'exec':
      times.exec = draw_fractal(fractal, max_iters)
      postMessage(gen_msg_exec_complete(my_worker_id, fractal.name, times))

    default:
  }
}
