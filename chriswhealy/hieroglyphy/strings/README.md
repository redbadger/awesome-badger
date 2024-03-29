# Pulling Some Strings

| Previous | [Top](/chriswhealy/hieroglyphy) | Next
|---|---|---
| [Pulling Ourselves Up By Our Bootstraps](/chriswhealy/hieroglyphy/bootstraps/) | Pulling Some Strings | [What Have We Achieved So Far?](/chriswhealy/hieroglyphy/checkpoint1/)

If all the operands supplied to the plus `+` operator are either numeric, or can safely be interpreted as numbers, then `+` performs arithmetic addition as expected.
Hence, these two statements are equivalent:

```javascript
   1 + 2 = 3
true + 2 = 3
```

However, if plus `+` is passed any non-numeric operands, then the operator is said to be "overloaded" and its behaviour switches from arithmetic addition to string concatenation.
The reason for this switch of behaviour is that JavaScript must perform type conversion that is guaranteed never to fail:

* It is potentially unsafe to assume that a string represents a number &mdash; after all, what is the numeric value of `'cat'`?
* It is always safe to assume that a number can be represented a string

So `1 + '2' = '12'` and `'cat' + 3 = 'cat3'`

How does this fact help us here?

From the list of natural numbers shown earlier, we can see that the encoded representation of integer `9` is 44 characters long, and this total will only grow larger as we attempt to represent larger numbers.

Using this naïve scheme of repeatedly adding one, the number `17` would be represented as the sum of seventeen `true`s &mdash; that's 84 characters (without any whitespace):

```javascript
// This scales very badly...
!![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![]   // 17
```

However, we can create a much shorter representation by:

* Encoding each digit of integer `17` to the strings `'1'` and `'7'`
* Concatenating the string representations
* Coerce the string back to a number

Given that our minimal alphabet consists only of the characters `+!(){}[]`, how do we coerce a value to a string?

The answer comes from realising that when coerced to a string, an empty list `[]` becomes an empty string `''`.
Knowing this, we can overload the plus `+` operator by concatenating our numeric value to an empty list:

![Coerce String One](/chriswhealy/hieroglyphy/img/coerce_str_1.png)

So simply by adding `+[]` to the end of each digit, we can obtain that digit's string representation:

```javascript
+[] + []                                                           // 0 + [] -> '0'
+!![] + []                                                         // 1 + [] -> '1'
!![] + !![] + []                                                   // 2 + [] -> '2'
!![] + !![] + !![] + []                                            // 3 + [] -> '3'
!![] + !![] + !![] + !![] + []                                     // 4 + [] -> '4'
!![] + !![] + !![] + !![] + !![] + []                              // 5 + [] -> '5'
!![] + !![] + !![] + !![] + !![] + !![] + []                       // 6 + [] -> '6'
!![] + !![] + !![] + !![] + !![] + !![] + !![] + []                // 7 + [] -> '7'
!![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + []         // 8 + [] -> '8'
!![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + []  // 9 + [] -> '9'
```
