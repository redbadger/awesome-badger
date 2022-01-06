---
layout: post
title:  "Understanding JavaScript: Objects and Arrays"
date:   2020-05-07 12:00:00 +0000
user: chriswhealy
author: Chris Whealy
excerpt: In this blog, we take a look at the fact that JavaScript Objects can be accessed as if they were arrays, and the fact that all JavaScript Arrays are in fact Objects.
---

# In JavaScript, Everything is an Object

Well, everything that is, except for primitive values such a numbers and Booleans etc

But even things like functions are special objects with an additional *executable part*...

So, what's an object?

An object is two things basically:

1. It is an unordered collection of name/value pairs, and
1. It is a container for a set of methods and properties inherited from a parent object known as a prototype (we'll discuss prototypical inheritance in another blog)

Here's the simplest way to create an object...

```javascript
// Create an empty object
var person1 = {}
```

### Creating Object Properties

We can now bind any value we like to any object property we like.  However, depending on what names we want to assign to these properties, we might need to write the coding using one of two different syntaxes.

If the property name does not need to contain any characters that have reserved meanings such as `-` or `+` or `@`, then you can use the refinement operator `.` (that's the fancy technical name for the dot in between the object name and the property name):

```javascript
// Create an empty object
var person1 = {}

person1.firstName = "Harry"
person1.lastName  = "Hawk"
person1.hobbies   = ["swimming","cycling"]

person1.listHobbies = function() {
  return this.hobbies.join(" ");
}
```

### But Objects Also Have Array-like Properties...

But what if you need to have a property whose name contains a reserved character?  In this case, you can use the array syntax.  This is possible because all JavaScript objects can be treated as if they are arrays containing ***named*** elements (not numbered elements).

```javascript
// Create an empty object
var person2 = {}

person2["first-name"] = "Harry"
person2["last-name"]  = "Hawk"
person2["hobbies"]    = ["swimming","cycling"]

person2["listHobbies"] = function() {
  return this.hobbies.join(" ")
}
```

Notice that the `person2` object now contains two properties (`first-name` and `last-name`) whose names contain the reserved minus "`-`" character.  Due to the presence of this reserved character in the name, it is now impossible to refer to these properties using the refinement operator (`.`).  Any attempt to do so would create a syntax error:

```javascript
> console.log(person2.last-name)
Uncaught ReferenceError: name is not defined
```

But by switching to the array syntax, this now becomes perfectly valid JavaScript:

```javascript
> console.log(person2["last-name"])
Hawk
```

### Deleting Object Properties

A property can be removed from an object using the `delete` keyword; but here, you must be careful not to confuse object properties with variables:

```javascript
// Declare a global variable.  This is not a property of the global object
var aGlobalVariable = "I'm a global variable"

// Declare a property belonging to the global object (notice that the 'var' keyword is missing)
aGlobalProperty     = "I'm a global property"

// Delete can only operate on properties, not variables, so delete here returns false
delete aGlobalVariable    // false
aGlobalVariable           // "I'm a global variable" (this value still exists!)

// The property is deleted because it belongs to the global object - delete therefore returns true
delete aGlobalProperty    // true
aGlobalProperty           // undefined (this property no longer exists in the global object)
```


## JavaScript Arrays Are Also Objects...

JavaScript arrays are in fact just JavaScript objects&mdash;but with a special twist

> ***IMPORTANMT***
>
> JavaScript Array elements are simply object properties whose names are the ***string representation*** of the element's index number

```javascript
// Create an array
var listOfThings = ["ball","cup","pen","car"]

// Array elements can now be accessed either by their numeric index,
// or by the string representation of the numeric index
listOfThings[1]         // "cup"
listOfThings["1"]       // "cup"

// But attempts to use the refinement operator (dot notation) make no sense
listOfThings.1          // Uncaught SyntaxError: Unexpected number
listOfThings."1"        // Uncaught SyntaxError: Unexpected string
```

So, here we can see that the element at index `1` can be referenced using either the integer `1` ***or*** by the string representation of that integer `"1"`.  These two references are equivalent.

***Q:***&nbsp;&nbsp;&nbsp; Ok, so what about adding new elements to the array?
***A:***&nbsp;&nbsp;&nbsp; Again, there are multiple ways of doing this.

We could simply `push` an element onto the end of the array:

```javascript
listOfThings.push("dog")           // ["ball","cup","pen","car","dog"]
```

Or we could add a new element at a specific numerical index given by an integer:

```javascript
listOfThings[5] = "tree"           // ["ball","cup","pen","car","dog","tree"]
```

Or we could add a new element at a specific numerical index given by a character string:

```javascript
listOfThings["6"] = "snorkel"      // ["ball","cup","pen","car","dog","tree","snorkel"]
```

### Don't Get Array Index Numbers Confused with Property Names!

Here's another JavaScript gotcha...

Since an array is a special object whose element names are simply the string representation of numbers, you might think that you could add an element to the array using a named property like this:

```javascript
var listOfThings = ["ball","cup","pen","car"]
listOfThings.length                          // 4

// Create an "array element" using a non-numeric property name
listOfThings["first"] = "Some value"
listOfThings["first"]                        // "Some value"
listOfThings.first                           // "Some value"

listOfThings.length                          // 4 - Huh?
listOfThings = ["ball","cup","pen","car"]    // But didn't we just add a new array element?
```

The problem here is that we have added a new property called `first` to the `listOfThings` ***object***, but that property is not recognised as being an element of the ***array*** because its name is not the string representation of a number.

In fact, all the above coding did was add a new property to the object, not a new element to the array.

So, the mistake here was to confuse the properties of object `listOfItems` with the elements of array `listOfItems`.

> IMPORTANT
>
> The elements of an Array object are nothing more than a specially named subset of that object's properties

### What the Array `.length` Property Does Not Mean...

The `.length` property of an array does not always return the expected value.  For instance:

```javascript
// Create an empty array
var someArray = []

someArray.length   // 0     Ok, that's fine

// Add a new element at some arbitrary index
someArray[4] = "Surprise!"

someArray.length   // 5  Uh!?

someArray          // [undefined, undefined, undefined, undefined, "Surprise!"]
```

The `.length` property will always return a value 1 higher than the value of the current highest index – irrespective of whether any of the intervening elements exist or not!
