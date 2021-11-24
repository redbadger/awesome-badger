import { readFileSync } from 'fs'

const start = async () => {
  const wasmBin = readFileSync('./02-slightly-less-useless.wasm')
  const wasmObj = await WebAssembly.instantiate(wasmBin)

  console.log(`Answer = ${wasmObj.instance.exports.answer()}`)
}

start()
