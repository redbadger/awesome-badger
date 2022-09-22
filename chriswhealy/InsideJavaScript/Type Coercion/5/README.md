# Inside JavaScript: Understanding Type Coercion

| Previous | | Next |
|---|---|---|
| [Type Coercion: The Unusual Bits](../4/) | [Up](/chriswhealy/understanding-javascript-type-coercion) |

# Type Coercion: The Very Silly Bits...

Ok, now it's time to switch your brain into [lateral thinking](https://en.wikipedia.org/wiki/Lateral_thinking) mode because we're going to take this situation to its illogical conclusion...

### Coercing an Empty Object

***Q:***&nbsp;&nbsp; What do you get if you coerce an empty object `{}` to a string?<br>
***A:***&nbsp;&nbsp; The accurate, but generally unhelpful answer of `"[object Object]"`

So, if we coerce (or overload) the `+` operator to perform string concatenation instead of arithmetic addition, what will we get?

```javascript
1 + {}      // "1{object Object}"
```

Ok, that kinda makes sense...

But what about:

```javascript
!{}         // false of course...
```

Well, given that JavaScript arbitrarily coerces all objects to `true`, I suppose it makes sense because the logical NOT of `true` is `false`...

### Coercing an Empty Array

***Q:***&nbsp;&nbsp; What do you get if you coerce an empty array `[]` to a string?<br>
***A:***&nbsp;&nbsp; Empty string `""` of course

So, this makes perfect sense...

```javascript
1 + []      // "1"
```

But since an `Array` is just an object and all objects are coerced to `true`, we shouldn't be surprised to see this:

```javascript
![]         // false
```

***Q:***&nbsp;&nbsp; What do you get if you try to coerce an empty array `[]` to a number?<br>
***A:***&nbsp;&nbsp; Well, that depends on what the first element of the array contains...


```javascript
+[]         // 0    The array is empty, so element zero is undefined and undefined coerces to 0
+[""]       // 0    Element zero is the empty string which coerces to false, and false coerces to 0
+["2"]      // 2    Element zero contains a numeric string, so this converts successfully
+["Hi"]     // NaN  Element zero is a string with no valid numeric representation
+[1,"2"]    // NaN  Because it just does alright!!
```

![WAT](/assets/chriswhealy/wat.jpeg)

With apologies to [Gary Bernhardt](https://www.destroyallsoftware.com/talks/wat)


Of course, an empty array referenced by an empty array inside an empty array is clearly `undefined`:

```javascript
[][[]]      // undefined
```

Finally! Something that makes sense...

### And Now let's Coerce Things Back to Boolean, or Number or String

So, we could derive the Boolean values in a backwards kind of way:

```javascript
![]         // false
!![]        // true
!+[]        // true
```

Hey, why not use Boolean truthiness to coerce these values back to numbers?

```javascript
 ![] + !![]                // 1 because this is really (false + true)
!![] + !![]                // 2 because this is really (true + true)
!![] + !![] + !![]         // 3 because this is really (true + true + true)
!![] + !![] + !![] + !![]  // 4 because this is really (true + true + true + true)
```

But then since empty array coerces to the empty string, we can convert these numbers into strings by overloading the `+` operator!

```javascript
 ![] + !![] + []               // "1"
!![] + !![] + []               // "2"
!![] + !![] + !![] + []        // "3"
!![] + !![] + !![] + !![] + [] // "4"

![] + []                       // "false"
!+[] + []                      // "true"

[][[]]+[]                      // "undefined"
```

Come on, keep up!

This bizarre behaviour is the basis for the [Hieroglyphy](https://github.com/alcuadrado/hieroglyphy) app, possibly the strangest app in all of GitHub land.

This app takes any block of browser-based JavaScript and transforms it into equally valid, executable JavaScript but composed of only the characters `()[]{}+!`.

![Very silly!](/assets/chriswhealy/very_silly.png)
