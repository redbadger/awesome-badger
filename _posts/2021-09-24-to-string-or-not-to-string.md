---
layout: post
title:  "toString || !toString"
date:   2021-09-24 12:00:00 +0000
redirect_from: /chriswhealy/toStringOrNotToString/
category: chriswhealy
author: Chris Whealy
excerpt: toString, or not toString?<br>That is the question&mdash;<br>Whether 'tis nobler in the mind to suffer the slings and arrows of outrageous type coercion...
---

> toString, or not toString? That is the question&mdash;<br>
> Whether 'tis nobler in the mind to suffer<br>
> the slings and arrows of outrageous type coercion,<br>
> Or to take up arms against a sea of troublesome JavaScript behaviours,<br>
> and by opposing end them? To Git, to blame&mdash;<br>
> No more&mdash;and by a pull request to say we end<br>
> The heartache and the weekend support calls<br>
> That programmers are heir to&mdash;’tis a consummation<br>
> Devoutly to be wished!...

(with apologies to the Bard)

## Disclosure

This little blog post was developed out of [a tweet](https://twitter.com/mbostock/status/1441227623082840067) by [Mike Bostock](https://bost.ocks.org/mike/) (of [D3](https://d3js.org/) and [Observable](https://observablehq.com/) fame) about inconsistent JavaScript behaviour.

## Why is `toString` the Question?

Let's say you have created some custom object and you know that at some point, you will need the string representation of that object.

Ok, fine.  Let's give the object an explicit `toString` function:

```javascript
let someObj = { toString: () => "Blah" }
```

So if we now put that object into a [template literal](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals), everything behaves as expected:

```javascript
`${someObj}`    // 'Blah'
```

Ok, that's fine.

Another way to perform string conversion is to [overload the + operator](/chriswhealy/InsideJavaScript/Type Coercion/2/#overloading-the--operator).

```javascript
someObj + ""    // 'Blah'
```

Fair enough; but this is JavaScript, so we should expect some inconsistencies...

## And Now, Without the `toString` Function

Let's say that our custom object no longer has a `toString` function, but instead, has a `valueOf` function.

```javascript
let someObj = { valueOf: () => "Surprise!" }
```

Again, let's try our two approaches for performing string conversion.
First, let's use a template literal:

```javascript
`${someObj}`    // '[object Object]'  Uhhh, what!?
```

Hmmm, that didn't work.
Let's try overloading the `+` operator:

```javascript
someObj + ""    // 'Surprise!'  OK, that's better
```

The problem here is that the template literal specifically calls an object's `toString` function, but if that function is missing, it simply gives up and prints `[object Object]`.

The overloaded `+` operator on the other hand, appears to see that the object does not contain a `toString` function, and instead of giving up, calls the next best function &ndash; `valueOf` (then converts whatever value it receives into a string).

Ok, so template literals and the overloaded `+` operator both perform string conversion, but according to different rules...

## Choosing Between `toString` and `valueOf`

Let's now take the perfectly reasonable step of giving our custom object both a `toString` function ***and*** a `valueOf` function...

```javascript
let someObj = { toString: () => "Blah", valueOf: () => "Surprise!" }
`${someObj}`   // 'Blah'         Yup, that's what we want
someObj + ""   // 'Surprise!'    Huh?! Why wasn't toString() called?
```

![Think](/assets/chriswhealy/Think.png)

## Strange, but Consistent

So, although its a bit weird, we have established a pattern for how string conversion is performed when using either template literals or the overloaded `+` operator:

### Template literals

Does the object have a `toString` function?

  * Yes, call it.
  * No, give up and return `[object Object]`

### The overloaded `+` operator

During string conversion, the overloaded `+` operator prioritises the `valueOf` function over the `toString` function (and no, I can't explain why), so:

Does the object have a `valueOf` function?

* Yes, call it
* No, does the object have a `toString` function?
   * Yes, call it
   * No, give up and return `[object Object]`

Strange, but there you have it.

## Consistently Inconsistent

Let's apply what we've learnt about string conversion to the good old `Date` object:

```javascript
date = new Date()
date.valueOf()      // 1632481716606
date.toString()     // 'Fri Sep 24 2021 12:08:36 GMT+0100 (British Summer Time)'
```

Yup, that's all pretty normal.

So based on the above pattern of behaviour, converting the `date` object to a string using a template literal will cause the `toString` function to be called:

```javascript
`${date}`           // 'Fri Sep 24 2021 12:08:36 GMT+0100 (British Summer Time)'
```

Nice!

And converting the `date` object to a string by overloading the `+` operator will cause the `valueOf` function to be called:

```javascript
date + ""           // 'Fri Sep 24 2021 12:08:36 GMT+0100 (British Summer Time)'
```

![WAT](/assets/chriswhealy/wat.jpeg)
