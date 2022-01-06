# Inside JavaScript: Understanding Type Coercion

| Previous | | Next |
|---|---|---|
| [Type Coercion: The Sensible Bits](../2/) | [Up](/2020/05/05/understanding-javascript-type-coercion.html) | [Type Coercion: The Unusual Bits](../4/)


# Type Coercion: The Mostly Sensible Bits

## A Value's "Truthiness" or "Falsiness"

Let's take this snippet of JavaScript code and see what it gives us:

```javascript
// Create an object whose properties hold a value of each data type
var datatypes = {
  "true"        : true
, "false"       : false
, "zero"        : 0
, "one"         : 1
, "null"        : null
, "undefined"   : undefined
, "NaN"         : NaN
, "emptyString" : ""
, "function"    : function() {}
, "emptyObject" : {}
, "emptyArray"  : []
}

// Loop around each property in the object coercing its value to Boolean,
// then writing it to the console
for (var i in datatypes) {
  console.log(`datatypes["${i}"] = ${!!datatypes[i]}`);
}
```

The double NOT `!!` is a trick that coerces a value to its Boolean equivalent.

```javascript
datatypes["true"] = true            // As expected
datatypes["false"] = false          // Again, as expected
datatypes["zero"] = false           // Yup, I know about this one
datatypes["one"] = true             // And this one
datatypes["null"] = false           // Yeah, that makes sense
datatypes["undefined"] = false      // Makes sense too
datatypes["NaN"] = false            // Ok, I'll go with that
datatypes["emptyString"] = false    // Thinking about it, that maskes sense too
datatypes["function"] = true        // Uh, ok (but why?)
datatypes["emptyObject"] = true     // Seriously!?
datatypes["emptyArray"] = true      // Now that's just silly!
```

Any value that coerces to `true` is said to be ***truthy***<br>
Any value that coerces to `false` is said to be ***falsey***

So, not surprisingly, values like `0`, `null` and `undefined` all coerce to `false` and are therefore said to be ***falsey***.  In fact, with a little explanation, most of these type coercions give the result you might expect.  The general principle here is that any value that can be thought of as being *"empty"* will coerce to `false`, and any value that can be thought of as *"containing something"* will coerce to `true`.

***Q:***&nbsp;&nbsp;&nbsp; Ok, so why would `function` coerce to `true`?<br>
***A:***&nbsp;&nbsp;&nbsp; Because a function is a special type of *executable object*, so even if the function does nothing (as in our example above), it is never truly empty.

Perhaps less intuitively, even though they might be empty in the sense of *"having zero properties"*, all JavaScript Objects are ***truthy***.

The real screwball here is the Array.  JavaScript treats an `Array` simply as an `Object`; so even though that Array might contain zero elements, as far as Boolean coercion is concerned, it is treated as an object, and all objects are truthy &mdash; but more of this later...


## The Slightly Silly `typeof` operator

Most of the time, the JavaScript `typeof` operator gives you back a reasonably useful description of a variable's datatype.  For example:

```javascript
// Declare some variables to have various data types
var aNumber    = 123
var aString    = "Nothing to see here, move along"
var anObject   = { aProperty : 0 }
var aFunction  = function() { }

// What does JavaScript think these data types are?
typeof aNumber       // 'number'
typeof aString       // 'string'
typeof anObject      // 'object'
typeof aFunction     // 'function'
```

Ok, fair enough, no surprises here.

But what about these?

```javascript
// Declare some more variables
var notANumber = NaN
var anArray    = [1,2,3,4,5]
var nullValue  = null

// What does JavaScript think the data types are?
typeof notANumber    // 'number'   Say what?
typeof anArray       // 'object'   Well, I guess...
typeof nullValue     // 'object'   But that's just wrong!
```

Having `typeof` return `number` for something that is explicitly ***not a number*** isn't quite as weird as you might think; but you'll have to read the ECMAScript specification to discover why&mdash;specifically sections [4.3.24](https://www.ecma-international.org/ecma-262/6.0/#sec-terms-and-definitions-nan) and [7.1.3](https://www.ecma-international.org/ecma-262/6.0/#sec-tonumber).

While it's annoying to get `object` back when asking what the `typeof` an `Array` is; this is in fact an accurate, albeit quite unhelpful answer.

However, telling me that `null` is an object is totally misleading!

## A Sensible Version of the `typeof` Operator

Many widely used libraries provide their own functionality to replace JavaScript's built-in `typeof` operator.  For instance, jQuery provides the `type` function that gives back accurate answers:

```javascript
var anArray   = [1,2,3,4,5]
var nullValue = null

// jQuery provides a robust fix for JavaScript's only-sometimes-helpful typeof operator
jQuery.type(anArray)        // 'array'
jQuery.type(nullValue)      // 'null'

// Or the nice predicate function
jQuery.isArray(anArray)     // true
```

However, if you're not using any such library, it’s easy enough to create your own version of `typeof` that will always give you an accurate answer:

```javascript
const typeOf = x => Object.prototype.toString.apply(x).slice(8).slice(0, -1)
```

> ***Explanation***
>
> The above code works as follows:
>
> `const typeOf = x => ...`
>
> We declare a constant called `typeOf` that, using the arrow syntax, is of type `function`.  This function takes a single argument `x` that represents the thing whose datatype we wish to discover.
>
> `const typeOf = x => Object.prototype.toString()...`
>
> As with all JavaScript obects, the universal object `Object` inherits its properties from a `prototype` that contains (among other things) a function called `toString`.
>
> The `toString` function returns the string representation of whatever object it belongs to; however, if we directly called `Object.prototype.toString()`, it would return the string representation of `Object.prototype`&mdash;which is not what we want.  So we call the `apply` function belonging to function `toString` and supply the argument `x` received by our `typeOf` function.  This is how we can effectively call `x.toString()` without needing to know exactly what `x` is.
>
> `const typeOf = x => Object.prototype.toString().apply(x)...`
>
> We now have the full string representation of the object in question.
>
> However, this string contains extra characters we're not interested in, so the last thing to do is chop off the first 8 characters using `slice(8)`, then chop off the last character using `slice(0,-1)`.


On its own, this function will return a character string containing the actual datatype of whatever value it is passed.  In fact, running this function without passing any argument returns the accurate value `Undefined`.

This function can then easily be used as the foundation to create simple predicate functions:

```javascript
// Return the actual datatype of the argument
const typeOf = x => Object.prototype.toString.apply(x).slice(8).slice(0, -1)

// Partial function that creates a function to check for a specific data type
const isOfType = t => x => typeOf(x) === t

// Primitive type identifiers
const isNull      = isOfType("Null")
const isUndefined = isOfType("Undefined")
const isNumber    = isOfType("Number")
const isBigInt    = isOfType("BigInt")
const isSymbol    = isOfType("Symbol")
const isArray     = isOfType("Array")
const isMap       = isOfType("Map")
const isSet       = isOfType("Set")
const isString    = isOfType("String")
const isFn        = isOfType("Function")
const isGenFn     = isOfType("GeneratorFunction")
const isJsObject  = isOfType("Object")
```

If you're running JavaScript in NodeJS, there are two special system objects that return their name rather than their type when you use this `typeOf` function: `process` and `global`.  Hence it is worthwhile creating two more predicate functions:

```javascript
// The NodeJS objects 'global' and 'process' return their own names when asked their type
// even though they are just regular objects
const isNodeJsProcess = isOfType("process")
const isNodeJsGlobal  = isOfType("global")
```
