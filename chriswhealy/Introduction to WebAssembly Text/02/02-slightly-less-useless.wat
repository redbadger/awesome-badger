(module
  (func               ;; Declare a function that can be called from
    (export "answer") ;; outside the WASM module using the name "answer"
    (result i32)      ;; that returns a 32-bit integer
    (i32.const 42)    ;; Push 42 onto the stack then exit the function
  )                   ;; Any value left on the stack becomes the return value
)
