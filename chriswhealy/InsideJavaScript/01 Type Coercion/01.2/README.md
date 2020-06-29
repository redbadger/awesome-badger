# Inside JavaScript: Understanding Type Coercion

| Previous | Current | Next |
|---|---|---|
| [So, How Hard Do You Hit the Keyboard?](../01.1/README.md) | Type Coercion: The Sensible Bits | [Type Coercion: The Mostly Sensible Bits](../01.3/README.md) 


# Type Coercion: The Sensible Bits

## Transforming a String to a Number

Take this somewhat arbitrary snippet of JavaScript:

```javascript
var strValue = "-1"    // strValue is a character string
+strValue              // Returns the numeric value -1
```

But wait a minute, `strValue` is a character string, and everyone knows that character strings cannot necessarily be converted to numbers!  This is quite correct; but in this case, JavaScript looks at the operation we want to perform and tries to be helpful...

1. The unary <sup id="a1">[1](#f1)</sup> `+` operator attempts to return the numeric representation of its operand

    > ***Aside***  
    > Don't be misled by the use of the "plus" symbol for this operator.  This operator returns only the numeric value of its operand, not its ***positive*** numeric value

1. The value supplied in the variable `strValue` is the character string `"-1"`
1. The unary `+` operator now attempts to squeeze a numeric value out of the character string `"-1"`
1. Phew, we've been lucky!! String value `"-1"` converts nicely to the numeric value `-1` 

So, we can see that under the surface, JavaScript has automatically converted (or coerced) a character string into a number for us.

This is an example of where we explicitly instruct the coding to perform type coercion, because we expect to get a useful result.

But what about this situation:


```javascript
var strValue = "cat"   // strValue is a character string
+strValue              // Returns the special value NaN (Not a number)
```

![I Can Haz Integer?](../../img/I%20Can%20Haz%20Integer.png)

Sorry, not this time!

The logic of coding is exactly the same and all that has changed here is the value stored in variable `strValue` is now `"cat"`", whereas before it was `"-1"`&mdash;yet the result is completely different.

JavaScript went through exactly the same sequence of steps described above, but this time it discovered that the character string `"cat"` has no numeric representation, so we got the correct, but possibly unexpected response of `NaN`, or *"Not a Number"*.

So, type coercion does not always do either what you want or what you might expect.

## Overloading the `+` Operator

So, what would you expect to happen in this situation?

```javascript
1 + 2          // 3   Trick question :-)
```

Here, we are using `+` as the binary operator for arithmetic addition, and since both operands are numeric, everything is fine and we get the expect answer `3`.

But what happens in these situations?

```javascript
1 + "2"        // "12"
"3" + 4        // "34"
```

Buh!?

Here, we have a situation in which we are trying to perform the arithmetic operation `add` on one or more non-numeric values.

In order for an arithmetic operation to be successful, both operands must be numeric.

***Q:***&nbsp;&nbsp; Is it safe simply to assume that both operands can be converted to numbers and then added?  
***A:***&nbsp;&nbsp; It's probably foolish to try to discover the numeric value of a `"cat"`&hellip;

* It is not safe to assume that all string values have a numeric representation
* But it is safe to assume that all numbers have a string representation

So JavaScript automatically and silently does two things here:

1. It coerces the non-numeric operand into a string
1. It coerces the `+` operator to perform string concatenation instead of arithmetic addition

Operation coercion is also known as *"overloading"*.  This is where the "`+`" symbol switch operations from arithmetic addition to string concatenation depending on the data type of the arguments it receives.

Consequently, `1 + "2"` means that the numeric `1` is first converted to character `"1"`, then `"1"` and `"2"` are concatenated giving `"12"`.

The same process applies to `"3" + 4` in order to give `"34"`.

Ok, let's mix it up a little more.  What about this expression:

```javascript
1 + 2 + "3" + 4     // "334"
```

What the flagnog!

To understand what's going on here, let's break this instruction down the way JavaScript sees it:

1. Firstly, at any one time, the infix `+` operator can only operate on two arguments at any one time
1. The first part of the expression (`1 + 2`) is a perfectly valid arithmetic operation, so addition is performed and the intermediate result `3` is substituted into the expression at this point
1. Our expression now looks like this `3 + "3" + 4`
1. The first part of this expression is now `3 + "3"`, but since one of the operands is a string, JavaScript converts the numeric operand value to a string, coerces the `+` operator from arithmetic addition to string concatenation, and joins the two strings together giving another intermediate result of `"33"`
1. `"33"` is then substituted back into the original expression to give `"33" + 4`
1. The same logic about operands of mixed datatype is applied and the final result is `"334"`
1. Simples!

## Transforming a Boolean to a Number

Let's try these examples:

```javascript
var boolVal1 = true
var boolVal2 = false

+boolVal1              // Numeric 1
+boolVal2              // Numeric 0
```

Again, we go through the same sequence of logic:

1. The unary `+` operator attempts to return the numeric representation of its operand
1. The variables `boolVal1` and `boolVal2` contain the values `true` and `false` thus making them both of type `Boolean`
1. The Boolean values `true` and `false` are represented by the single bits `1` and `0` respectively, and these convert directly to the integers `1` and `0`
1. Consequently, `+true` is `1` and `+false` is `0`

Knowing then that Boolean values can be directly coerced to the integers `1` or `0`, the following statements now should make sense:

```javascript
1 + true      // 2
1 + false     // 1
```

## Transforming a Number to a Boolean

Ok, let's try some examples the other way around:

```javascript
var boolVal = false
var numVal  = 2

!boolVal        // true - no surprises here I hope
!numVal         // false - hmmmm?    
```

The logical NOT operator `!` is another unary operator that expects a Boolean operand.

In the first example, there's no problem because `false` is a Boolean value and when the NOT operator is applied, we get the expected value of `true`.

However, in the second example, `!` has been passed an integer.  So, before we can take the logical NOT of an integer, that integer must first be coerced to a Boolean value.  The rule JavaScript follows is simply this:  irrespective of their sign or magnitude, all non-zero numbers coerce to `true`.  Zero is the only number which coerces to `false`.

> ***Aside***
> 
> JavaScript code minimizers seek to reduce your source code down to the smallest possible representation.  In order to save a couple of bytes, they often use a trick that reduces the Boolean values `true` and `false` from 4 or 5 bytes, down to 2.
> 
> `!0` is used to represent `true`.  Integer `0` coerces to `false`, `!false` is `true`  
> `!1` is used to represent `false`.  Integer `1` coerces to `true`, `!true` is `false`
> 
> So, both Boolean values can now be represented using only two characters

Here's another type coercion trick that can be used if you have a loop that should stop after counting down to zero:

```javascript
var n = 5;

while (n--) {
  console.log(`Stop when n = 0. n is now ${n}`);
}
```

Here, we are relying on the fact that all non-zero integers coerce to `true`; thus as long as `n` remains greater than zero, the loop continues to run.

```javascript
Stop when n = 0. n is now 4
Stop when n = 0. n is now 3
Stop when n = 0. n is now 2
Stop when n = 0. n is now 1
Stop when n = 0. n is now 0
```

As soon as `n` becomes zero, zero coerces to `false` and the loop terminates.


| Previous | Current | Next |
|---|---|---|
| [So, How Hard Do You Hit the Keyboard?](../01.1/README.md) | Type Coercion: The Sensible Bits | [Type Coercion: The Mostly Sensible Bits](../01.3/README.md) 


---
***Endnotes***

<b id="f1">1</b>&nbsp;&nbsp; An operator is said to be *"unary"* if it requires only one operand

[↩](#a1)



