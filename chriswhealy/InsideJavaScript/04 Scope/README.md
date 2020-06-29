# Inside JavaScript: Scope

## Target Audience

This blog is aimed at developers who are either learning JavaScript or have been working with it and would like to deepen their understanding.

# Execution Contexts

Under the surface of JavaScript, the code you write is run within an environment known as an ***execution context***.

There are three types of execution context:

1. The Global Context
1. A Function Context
1. An `eval` context

## The Global Context

As the name implies, there is only one Global Context and this acts as the root or starting point for all other executions contexts.

The Global Context contains two fundamental objects:

* A `this` object
* A `global` object

If your JavaScript code is running in a browser, then the `global` object is called `window`.

`window` or `global` is a general purpose bucket in which all data not belonging to user defined functions is stored.

## A Function Context

Every time you call a JavaScript function, a new execution context is created within which all the information used by that specific invocation of the function is stored.

## An `eval` Context

The `eval` keyword is one of those really ***BAD*** features of JavaScript that you should not even think about using, for the simple reason that this global function allows you to execute an arbitrary character string as a JavaScript program.

Hands up anyone who can see the gaping security hole here...!

The Mozilla JavaScript documentation contains a very helpful discussion on why you should [never use `eval()`!](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/eval#Never_use_eval!)

Quinsequontly, we will not be discussing the `eval` context because ***you won't be using it, will you!***

## Inside an Exection Context

Within an execution context, there are three distinct areas:

* The Lexical Environment
* The Variable Envrionment
* The `this` binding

We'll look inside these areas later...



# Storing Values

JavaScript distinguishes between values stored as a ***variables*** and values stored as ***properties***.

Both are examples of a value being bound to a name, but the scope of their storage differs.

### Creating Properties

A property is a named value that is always stored as the member of an object. For example:

```javascript
var myObject = {}
myObject.firstProperty = "Hi there!"
```

Here, an empty object called `myObject` is created, then in order to give this object a new property, we simply bind a value to the desired name `firstProperty`.

But what about this statement.  What does this do?

```javascript
foobar = "Phluff 'n' stuff"
```

Here's one of JavaScript's gotchas that trips up a lot of developers new to the language.

Two things have ***not*** been specified here:

* The `var` keyword was not used
* No object name was specified

So, what's happened?

Well, if you bind a value to a name ***without*** using the `var` keyword, then that name is automatically assumed to be an object property!

Ok, but the property of which object?

If your JavaScript code is running in a browser, then the assumed object is called `window`, but if it's running on a server in NodeJS, then the object is called `global`.

Either way, this object is the highest-level object in the hierarchy of JavaScript runtime objects.

### Declaring Variables

Whenever a declaration is preceded by the `var` keyword, then as before, a value is bound to a name, but that name exists within the scope of the current ***execution context***.  (More on exactly what an "execution context" is in a later blog).

```javascript
var barfoo = "Chicken soup";
```

Depending on where this particular statement is located in your code, the variable `barfoo` might become a property belonging to the global object, or it might become a variable within the execution context of some enclosing function.

But we won't disappear down this particular rabbit-hole quite yet...



## Default Object Methods and Properties

Whenever you create an object, in addition to that object containing the properties you have defined, it will also, automatically contains some other standard methods and properties.

Using NodeJs, let's create a completely empty object and then take a look inside it (you can also try this in the browser, and you'll get the same results).

```javascript
> var person = {
    firstName : "Harry",
    lastName  : "Hawk",
    dateOfBirth : "1976 Aug 03"
}
undefined
```

After the `person` object is declared, we type the name `person`, then a dot and then hit tab

```javascript
> person.
person.__defineGetter__      person.__defineSetter__      person.__lookupGetter__
person.__lookupSetter__      person.__proto__             person.constructor
person.hasOwnProperty        person.isPrototypeOf         person.propertyIsEnumerable
person.toLocaleString        person.toString              person.valueOf

person.dateOfBirth           person.firstName             person.lastName 
```

NodeJS helpfully lists all the methods and properties belonging to the `person` object.

The last three property names we recognise, because these are the name we explicitly declared; however, there are 12 extra names that we didn't create ourselves.

Behind the scenes, JavaScript automatically caused our `person` object to inherit this set of methods from the default object called (helpfully enough) `Object`.



















Hope that helps!

Chris W

[![Red Badger Logo - Small](./img/Red%20Badger%20Small.png)](https://red-badger.com/)





## Storing Values

JavaScript distinguishes between values stored as a ***variables*** and values stored as ***properties***.

Both are examples of a value being bound to a name, but the scope of their storage differs.

### Creating Properties

A property is a named value that is always stored as the member of an object. For example:

```javascript
var myObject = {}

myObject.firstProperty = "Hi there!"
```

Here, an empty object called `myObject` is created, then in order to give this object a new property, we simply bind a value to the desired name `firstProperty`.

But what about this statement.  What does this do?

```javascript
foobar = "Phluff 'n' stuff"
```

Here's one of JavaScript's gotchas that trips up a lot of developers new to the language.

Two things have ***not*** been specified here:

* The `var` keyword was not used
* No object name was specified

So, what's happened?

Well, if you bind a value to a name ***without*** using the `var` keyword, then that name is automatically assumed to be an object property!

Ok, but the property of which object?

If your JavaScript code is running in a browser, then the assumed object is called `window`, but if it's running on a server in NodeJS, then the object is called `global`.

Either way, this object is the highest-level object in the hierarchy of JavaScript runtime objects.

### Declaring Variables

Whenever a declaration is preceded by the `var` keyword, then as before, a value is bound to a name, but that name exists within the scope of the current ***execution context***.  (More on exactly what an "execution context" is in a later blog).

```javascript
var barfoo = "Chicken soup";
```

Depending on where this particular statement is located in your code, the variable `barfoo` might become a property belonging to the global object, or it might become a variable within the execution context of some enclosing function.

But we won't disappear down this particular rabbit-hole quite yet...



