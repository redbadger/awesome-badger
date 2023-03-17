# Tricks With Big Numbers

| Previous | [Top](/chriswhealy/hieroglyphy) | Next
|---|---|---
| [Extracting Characters From Keywords](/chriswhealy/hieroglyphy/keywords/) | Tricks With Big Numbers | [So Where Are We Now?](/chriswhealy/hieroglyphy/checkpoint2/)

Now that we have the string representation of all the digits and the letter `'e'`, we can construct strings to represent large numbers such as <code>10<sup>100</sup></code> and <code>10<sup>1000</sup></code>.

We first form the strings `'1e100'` and `'1e1000'`, then coerce these strings to numbers which returns the numeric values `1e+100` and `Infinity` (notice that JavaScript has helpfully included a `'+'` for us).

Then, by coercing `1e+100` and `Infinity` back to strings, we can obtain the characters `'+'`, `'I'` and `'y'`.

## Plus Sign

To obtain the `'+'` sign, we first need to construct the number `1e+100`.
This can be done as follows:

```javascript
  +'1e100'          // Create the string and coerce to a number -> 1e+100
 (+'1e100')+[]      // Overload plus to convert the number back to a string -> '1e+100'
((+'1e100')+[])[2]  // Extract character at index 2 -> '+'
```

Here's the above code with encoded values substituted for `'e'`, `1` and `0`:

```javascript
 +(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[]))                 // Coerce string '1e100' to number 1e+100
 +(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[]))+[]              // Coerce back to string '1e+100'
(+(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[]))+[])[!![]+!![]]  // Extract character at index 2 -> '+'
```

## Two More Alphabetic Characters

The number `1e+1000` is too large for JavaScript to store as a 64-bit floating point number, so instead, it simply returns the word `Infinity`.
This is very helpful because it contains the previously unavailable characters `'I'` and `'y'`

```javascript
 +(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[])+(+[]))           // Number Infinity
 +(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[])+(+[]))+[]        // Coerce to string 'Infinity'
(+(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[])+(+[]))+[])[+[]]  // Extract character at index 0 -> 'I'
                                                                         // Extract character at index 7 -> 'y'
(+(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[])+(+[]))+[])[!![]+!![]+!![]+!![]+!![]+!![]+!![]]
```
