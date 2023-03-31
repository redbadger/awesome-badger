# Tricks With Big Numbers

| Previous | [Top](/chriswhealy/hieroglyphy) | Next
|---|---|---
| [Extracting Characters From Keywords](/chriswhealy/hieroglyphy/keywords/) | Tricks With Big Numbers | [So Where Are We Now?](/chriswhealy/hieroglyphy/checkpoint2/)

Now that we have the string representation of all the digits and the letter `'e'`, we can use JavaScript's exponent notation to construct strings that represent large numbers such as <code>10<sup>100</sup></code> and <code>10<sup>1000</sup></code>:

* Form the strings `'1e100'` and `'1e1000'`
* Coercing these strings to numbers gives `1e+100` and `Infinity`
* Coercing these numbers back to strings to give `'1e+100'` and `'Infinity'`
* Extract the characters `'+'`, `'I'` and `'y'`

## Plus Sign

It might seem almost magical that the `'+'` sign can be obtained from a string containing only the characters `1e100`; however, when this string is coerced to a number then back to a string, JavaScript helpfully inserts the `'+'` for us...

```javascript
  +'1e100'          // Create the string and coerce to a number -> 1e+100
 (+'1e100')+[]      // Overload plus to convert the number back to a string -> '1e+100'
((+'1e100')+[])[2]  // Extract the character at index 2 -> '+'
```

Here's the above code with `'e'`, `1` and `0` represented in their encoded form:

```javascript
 +(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[]))                 // Coerce string '1e100' to number 1e+100
 +(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[]))+[]              // Coerce back to string '1e+100'
(+(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[]))+[])[!![]+!![]]  // Extract character at index 2 -> '+'
```

## Two More Alphabetic Characters

The number `1e+1000` is too large for JavaScript to store as a 64-bit floating point number, so instead, it simply returns the keyword `Infinity`.
This is very helpful because it contains the previously unavailable characters `'I'` and `'y'`

```javascript
 +(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[])+(+[]))           // Number Infinity
 +(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[])+(+[]))+[]        // Coerce to string 'Infinity'
(+(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[])+(+[]))+[])[+[]]  // Extract character at index 0 -> 'I'
                                                                         // Extract character at index 7 -> 'y'
(+(+!![]+(!![]+[])[+!![]+!![]+!![]]+(+!![])+(+[])+(+[])+(+[]))+[])[!![]+!![]+!![]+!![]+!![]+!![]+!![]]
```
