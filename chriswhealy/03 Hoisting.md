# Inside JavaScript: Variable Hoisting

## Target Audience

This blog is aimed at developers who are either learning JavaScript or have been working with it for a while and would like to deepen their understanding.

# Variable Scope

## Global Scope

When you declare a variable in JavaScript, essentially you are giving a name to a particular value.  So, for instance, we could have the following block of code that assigns the value `"dog"` to the name `myPet` and then writes that value to the console:

```javascript
var myPet = "dog"
console.log(`My pet is a ${myPet}`)
```

If you start NodeJS, or the developer tools in your browser and then paste in the above coding snippet, it all works and is frankly quite boring...

```console
> var myPet = "dog"
undefined
> console.log(`My pet is a ${myPet}`)
My pet is a dog
undefined
```

However, there's more going on under the surface here.  Any variable you declare exists within something called a ***scope***.  Where a scope defines the range of that variable's visibility.

By pasting this into a browser console, you have executed that coding inside the browser's ***Global Context***.  The Global Context is the root, or outermost in any JavaScript runtime environment &mdash; if a variable doesn't exist in at least the Global Context, then it doesn't exist anywhere (at least not as far as standard JavaScript is concerned).

A consequence of this is that the variable `myPet` has now become a part of something called the `VariableEnvironment` that lives within JavaScript's Global Context.

So, you can now access this value either directly by name, or by using the name of the global object within which that variable now exists.  In NodeJS:

```javascript
> global.myPet
'dog'
```

Or in a browser:

```javascript
> window.myPet
  "dog"
> globalThis.myPet
  "dog"
> this.myPet
  "dog"
```

All three ways of accessing the value identified by the named `myPet` are equivalent.

## Function Scope

So, let's take the above snippet of code and simply move it inside a function:

```javascript
function describePet() {
  var myPet = "dog"
  console.log(`My pet is a ${myPet}`)
}
```

If we paste this code into NodeJS, we get

```console
> function describePet() {
...   var myPet = "dog"
...   console.log(`My pet is a ${myPet}`)
... }
undefined
> describePet()
My pet is a dog
undefined
```

Again, no surprises there.

But what happens if we swap the lines of code around inside function `describePet()` and then run the function again?

```javascript
function describePet() {
  console.log(`My pet is a ${myPet}`)
  var myPet = "dog"
}
```

In this case, we're trying to print the value of the variable `myPet` before it has been declared; so, shouldn't that give us some sort of runtime error like `Uncaught ReferenceError: myPet is not defined`?

Nope...

```console
> describePet()
My pet is a undefined
```

This result is quite different&mdash;in fact, this is not a runtime error; the JavaScript runtime has simply said *"Yes, I know about variable `myPet`, but I don't yet have any value for it"*.  So, it simply prints the value `undefined`.

Well, that's odd&mdash;yes, that's ***variable hoisting***.

## Variable Hoisting

When JavaScript executes a function, the runtime creates a new environment called an ***execution scope*** within which to run that function.  Among other things, the execution scope contains a `VariableEnvironment` that holds all the name/value pairs of variables declared by the function.

So, when the JavaScript runtime starts to execute a function, one of the first things it does is to scan the the function's source code looking for variable declarations.  Any variable name it finds immediately has a reference created for it in the function's execution scope; however, no value will be assigned to the variable until execution reaches the point in the source code where a value is explicitly assigned.

So, in effect, your code is run ***as if*** you wrote this:

```javascript
function describePet() {
  var myPet
  console.log(`My pet is a ${myPet}`)
  myPet = "dog"
}
```

Notice that at runtime, execution behaves as if the declaration has been moved or ***hoisted*** to the top of the function's source code.  This effectively means that the names of all the variables declared within a function are created first, then the function's source code is executed&mdash;but variables are not assigned values until an explicit assignment statement is reached.


## Early Activation

Variable hoisting is an example of ***partial*** early activation.

So far, we have only looked at what happens to variables declared using the `var` keyword inside a function.  But what happens if we declare another function inside a function?

Let's change our `describePet` function so that the call to `console.log()` is inside our own little function called `write`.

Knowing that the variable declaration of `myPet` is going to be hoisted to the top of the function, we can now expect the value of `myPet` to be `undefined` until we execute the statement that actually assigns the value.

However, what happens if we try to execute a function before we reach the point in the source code where that function is declared?

```javascript
function describePet() {
  write(myPet)

  var myPet = "dog"
  function write(str) {
    console.log(`My pet is a ${str}`)
  }
}
```

If we execute this function, what happens when we reach the call to function `write()`?

```console
> function describePet() {
...   write(myPet)
... 
...   var myPet = "dog"
...   function write(str) {
...     console.log(`My pet is a ${str}`)
...   }
... }
undefined
> describePet()
My pet is a undefined
undefined
```

Hang on!  Why does this even work?

If hoisting causes the name of the variable `myPet` to become known, but without a value, then shouldn't the function `write` also be known but have no value (I.E. not become executable until we reach the actual declaration)?

No.  This is the difference between ***early activation*** and ***partial*** early activation.

Variables within functions declared using the `var` keyword are only partially activated when the function starts.  But inner functions declared using either the `function` or the `var` keywords will be fully activated, and you can call them before execution reaches the point in the source code where the function is defined.

We can easily correct the coding above by moving the declaration of `myPet` before the call to `write`.

```javascript
function describePet() {
  var myPet = "dog"
  write(myPet)

  function write(str) {
    console.log(`My pet is a ${str}`)
  }
}
```

Now, even though we are calling function `write` before it has been declared, JavaScript's early activation feature allows this coding to work without any problems:


```console
> function describePet() {
...   var myPet = "dog"
...   write(myPet)
... 
...   function write(str) {
...     console.log(`My pet is a ${str}`)
...   }
... }
undefined
> describePet()
My pet is a dog
undefined
```

## So, Are All Declarations in Functions Activated Early?

In a word, no.

In ES6, we now have the `const` and `let` keywords, and ***neither*** of these declarations are activated early.

Let's make a simple change to a previous version of our coding.  We will simply exchange the `var` keyword for the `let` keyword:

```javascript
function describePet() {
  write(myPet)

  let myPet = "dog"
  function write(str) {
    console.log(`My pet is a ${str}`)
  }
}
```

Now when we run the coding:

```console
> function describePet() {
...   write(myPet)
... 
...   let myPet = "dog"
...   function write(str) {
...     console.log(`My pet is a ${str}`)
...   }
... }
undefined
> describePet()
Uncaught ReferenceError: Cannot access 'myPet' before initialization
    at describePet (repl:2:9)
```

OUCH!!

Early activation does not apply to values declared using the `let` or `const` keywords, so at the point in time where we try to call function `write`, the function `write` is known due to early activation of functions, but the name `myPet` is completely unknown.  Hence the `ReferenceError`.


## So, Is Anything Else Not Activated Early?

Only JavaScript classes&mdash;but there's a good reason for this restriction.

```javascript
function badClass() {
  var c = new MyEmptyClass()

  class MyEmptyClass {}
  
  return c
}
```

If we try to call function `badClass()`, it will explode in the same way as the previous example:

```console
> function badClass() {
...   var c = new MyEmptyClass()
... 
...   class MyEmptyClass {}
...
...   return c
... }
undefined
> badClass()
Uncaught ReferenceError: Cannot access 'MyEmptyClass' before initialization
    at badClass (repl:2:11)
```

Think about the following situation.  When you declare a class, your new class can act as an extension to some other class.  For instance:

```javascript
class DayOfTheWeek {}
class Monday extends DayOfTheWeek {}
```

This is all fine.  But there is an important case in which the name of the class to be extended can be calculated dynamically.  This means that instead of simply saying:

```javascript
class MyNewClass extends SomeOtherClass {}
```

It is perfectly valid to say this instead:

```javascript
class MyNewClass extends dynamicallyChooseClassToExtend() {}
```

In this case, before we know which class `MyNewClass` will extend, we must first call function `dynamicallyChooseClassToExtend()`.  This function then returns the name of the class that is to be extended.

Ok, all that's fair enough, but what would now happen if we allowed class definitions to be hoisted to the top of the execution scope?


```javascript
const identity = obj => obj

class MyEmptyClass extends identity(Object) {}
```

Now we have a potential issue because `extends` won't know which class needs to be extended until after the call to `identity(Object)` has been executed.

Consider what would happen in this example if class declarations could be hoisted.

The definition of class `MyEmptyClass` has been hoisted to the top of the function's scope, but in order to discover which class needs to be extended, we must execute function `identity`.  However, if the class  definition now exists at a location ***before*** function `identity` is declared, we're knackered because variables declared with `const` or `let` are not hoisted.

This could get very ugly, very quickly...

So, to avoid such horrible complications, JavaScript classes are not activated early.

There are certain other subtleties with function declarations and early activation, but I think this is enough to be getting on with for the moment.

Hope that helps

Chris W

[![Red Badger Logo - Small](./img/Red%20Badger%20Small.png)](https://red-badger.com/)


