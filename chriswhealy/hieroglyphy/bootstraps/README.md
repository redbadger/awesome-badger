# Pulling Ourselves Up By Our Bootstraps

| Previous | [Top](/chriswhealy/hieroglyphy) | Next
|---|---|---
| [But Why Would You Even Do This?](/chriswhealy/hieroglyphy/but-why/) | Pulling Ourselves Up By Our Bootstraps | [Pulling Some Strings]](/chriswhealy/hieroglyphy/strings/)

## Encoding The Basic Data Types

Using only the characters in our close-to-minimal alphabet, we can immediately represent two basic JavaScript data types:

* `[]` The empty list, and
* `{}` The empty object

By performing different combinations of type coercion on these simple values, we can derive the primitive Boolean values of `true` and `false`; from which we can then derive the integer values `0` and `1`.

## Primitive Values

By performing numeric coercion on an empty list, we obtain integer `0`

![Coerce Integer Zero](/chriswhealy/hieroglyphy/img/coerce_0.png)

By performing Boolean coercion on an empty list, we obtain the Boolean primitive `false`

![Coerce Boolean False](/chriswhealy/hieroglyphy/img/coerce_false.png)

If we then perform Boolean negation on `![]` we obtain `true`

![Coerce Boolean True](/chriswhealy/hieroglyphy/img/coerce_true.png)

Finally, we can derive integer `1` by performing numeric coercion on `!![]`

![Coerce Integer One](/chriswhealy/hieroglyphy/img/coerce_1.png)

## Natural Numbers

We have seen above that when a Boolean value appears in an arithmetic expression, `false` is coerced to `0` and `true` is coerced to `1`.  Knowing this we can derive the natural counting numbers.

Since `2` is `1 + 1`, we can rewrite `1 + 1` as `true + true` and still get `2`.

Further, we know from above that `true` can be encoded as `!![]`; therefore `1 + 1` can be rewritten as:

![Coerce Integer Two](/chriswhealy/hieroglyphy/img/coerce_2.png)

So now we can generate the first 10 counting numbers:

```javascript
+[]                                                           // 0
+!![]                                                         // 1
!![] + !![]                                                   // 2
!![] + !![] + !![]                                            // 3
!![] + !![] + !![] + !![]                                     // 4
!![] + !![] + !![] + !![] + !![]                              // 5
!![] + !![] + !![] + !![] + !![] + !![]                       // 6
!![] + !![] + !![] + !![] + !![] + !![] + !![]                // 7
!![] + !![] + !![] + !![] + !![] + !![] + !![] + !![]         // 8
!![] + !![] + !![] + !![] + !![] + !![] + !![] + !![] + !![]  // 9
```
