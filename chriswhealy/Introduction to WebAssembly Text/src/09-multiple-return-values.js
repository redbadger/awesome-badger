import { readFileSync } from 'fs'

const start = async () => {
  const wasmBin = readFileSync('./09-multiple-return-values.wasm')
  const wasmObj = await WebAssembly.instantiate(wasmBin)

  console.log(`Conjugate of (5, -3i) = ${wasmObj.instance.exports.conj(5, -3)}`)
}

start()
