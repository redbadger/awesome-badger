# Character Cache: First Checkpoint

| Previous | [Top](/chriswhealy/hieroglyphy) | Next
|---|---|---
| [Pulling Some Strings](/chriswhealy/hieroglyphy/strings/) | What Have We Achieved So Far? | [Extracting Characters From Keywords](/chriswhealy/hieroglyphy/keywords/)

So far, we are able to encode the 10 digit characters `0` to `9`, so we will place them into a character cache that so far contains:

| Character | Derived From | Encoding
|---|---|---
| `'0'` | `(0).toString()`                                 | `+[]+[]`
| `'1'` | `(1).toString()`                                 | `+!![]+[]`
| `'2'` | `(1 + 1).toString()`                             | `!![]+!![]+[]`
| `'3'` | `(1 + 1 + 1).toString()`                         | `!![]+!![]+!![]+[]`
| `'4'` | `(1 + 1 + 1 + 1).toString()`                     | `!![]+!![]+!![]+!![]+[]`
| `'5'` | `(1 + 1 + 1 + 1 + 1).toString()`                 | `!![]+!![]+!![]+!![]+!![]+[]`
| `'6'` | `(1 + 1 + 1 + 1 + 1 + 1).toString()`             | `!![]+!![]+!![]+!![]+!![]+!![]+[]`
| `'7'` | `(1 + 1 + 1 + 1 + 1 + 1 + 1).toString()`         | `!![]+!![]+!![]+!![]+!![]+!![]+!![]+[]`
| `'8'` | `(1 + 1 + 1 + 1 + 1 + 1 + 1 + 1).toString()`     | `!![]+!![]+!![]+!![]+!![]+!![]+!![]+!![]+[]`
| `'9'` | `(1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1).toString()` | `!![]+!![]+!![]+!![]+!![]+!![]+!![]+!![]+!![]+[]`

That's a start, but now we need to find a way to encode the letters of the alphabet.
