# Inside JavaScript: Understanding Type Coercion

| Previous | | Next |
|---|---|---|
| [Type Coercion: The Mostly Sensible Bits](../3/) | [Up](/chriswhealy/understanding-javascript-type-coercion) | [Type Coercion: The Very Silly Bits](../5/)

## Unusual Tricks With Logical Operators

In most languages, logical operators have a built-in optimisation feature called *"early bailout"*.
The purpose of this is to save execution time because, under certain circumstances, the overall outcome of the logical operation can be reliably known ***before*** all the operands have been tested.

### Bailing Out Early from Logical AND (`&&`)

When testing a Boolean AND `&&` condition, we cannot know if the overall outcome is `true` until ***all*** operands have been evaluated.
The flip side however is that as soon as an operand evaluates to `false`, then it is impossible for the overall outcome to be `true`.

Consequently, evaluation can terminate or *"bail out"* early as soon as the first `false` value is encountered.

### Bailing Out Early from Logical OR (`||`)

Similarly, when testing a Boolean OR `||` condition, we cannot know if the overall outcome is `false` until ***all*** operands have been evaluated.
The flip side however is that as soon as an operand evaluates to `true`, then it is impossible for the overall outcome to be `false`.

Consequently, evaluation can terminate or *"bail out"* early as soon as the first `true` value is encountered.

### Logical Operators Are Expressions

In JavaScript, the Boolean operators AND and OR are expressions: this means that they will return a value.

| Operator | If `true` is returned, this is&hellip; | If `false` is returned, this is&hellip;
|---|---|---
| AND `&&` | The value of the ***last*** operand to be evaluated | The ***first*** operand that evaluates to `false`
| OR <code>&vert;&vert;</code> | The ***first*** operand that evaluates to `true` | The value of the ***last*** operand to be evaluated

Knowing this, we can simplify certain parts of our code.

## Default Values for Function Arguments

Irrespective of how many arguments a JavaScript function is defined to have, when that function is called, the runtime does not care about how many arguments are ***actually*** passed.

For instance, a function might be declared to accept three arguments, but at runtime we could pass it two, or four, or none&mdash;JavaScript really doesn't care and no checks are made!

This means that it is risky to write coding within a function that assumes a particular argument will ***always*** contain a value.
That argument value might not have been supplied by the caller&mdash;in which case our coding might go horribly wrong&hellip;

So, we need a simple way to check whether we've been passed a value, and if not, assign some default value.

There's a trick we can use here that works only because the OR operator is an expression.  We know that:

1. OR always returns the value of the ***last*** tested operand
1. OR stops testing (bails out early) as soon as it encounters a truthy operand.

This behaviour is what allows us to implement *"default argument value"* logic.

Consider this code snippet:

```javascript
var person = function(fName, lName, dob) {
  return {
    "firstName"   : fName || "Not specified",
    "lastName"    : lName || "Not specified",
    "dateOfBirth" : dob   || "Not specified",
  }
}

var p1 = person("Harry", "Hawk", "12.08.76")
```

***Q:***&nbsp;&nbsp;&nbsp; What values would we expect the properties of object `p1` to have?<br>
***A:***&nbsp;&nbsp;&nbsp; Well, that depends on what values are supplied when the `person` function is called

```javascript
> p1 = person("Harry", "Hawk", "12.08.76")
{ firstName: 'Harry', lastName: 'Hawk', dateOfBirth: '12.08.76' }
```

Ok, that's reasonable enough because we supplied all the required arguments to function `person`.

But what about the case when no values are supplied?

```javascript
> p2 = person()
{
  firstName: 'Not specified',
  lastName: 'Not specified',
  dateOfBirth: 'Not specified'
}
```

Here, our *default argument value* logic kicks in.
Whenever a JavaScript function expects a runtime argument, but is not passed anything, the argument takes on the value `undefined`.

So, based on the above explanation, we now understand how and why this code snippet works:

```javascript
"firstName"   : fName || "Not specified"
```

The `person` function expects to receive an argument call `fName`, so if a runtime argument is supplied for `fName`:

1. The caller supplies a value for the `fName` argument&mdash;and we are counting on that value being truthy
1. The OR operator stops testing as soon as it encounters a truthy operand
1. The OR operator returns the value of the last operand it tested

Hence, the argument value supplied in `fName` is assigned to the object property `firstName`

However, if no argument value is supplied for `fName`:

1. The caller does not supply a value for `fName`, so it automatically becomes `undefined`&mdash; which is falsey
1. The OR operator stops testing as soon as it encounters a truthy operand
1. The OR operator returns the value of the last operand it tests

Hence, the default value `"Not specified"` is assigned to the object property `firstName`

## WARNING! We Have Made a Dangerous Assumption!

The logic used above assumes that any legitimate argument value passed to this function ***will never*** be falsey.

So what happens if falsey values such as `0`, or `false` or `null` are legitimate as argument values?

Unfortunately, in such cases this trick will no longer work.
This is because after these legitimate falsey values have been coerced to Boolean, we will not be able to tell the difference between a `false` that came from a missing value and a `false` that came from a legitimate value.
