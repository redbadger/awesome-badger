# Inside JavaScript: Understanding Type Coercion

| Previous | | Next |
|---|---|---|
| | [Up](/chriswhealy/understanding-javascript-type-coercion) | [Type Coercion: The Sensible Bits](../2/)

## So, How Hard Do You Hit the Keyboard?

As far as the storage of information is concerned, programming languages can be divided into two broad categories:

* Languages that use ***Strong Typing***, and
* Languages that use ***Weak Typing***

True, there are many more subtleties involved here than simply these two generic categories; but this is a good starting point for understanding.[^1]

When people less familiar with programming hear that a language uses "strong typing", they can be forgiven for thinking that something like this is going on:

![Strong Typing?](/assets/chriswhealy/Strong%20Typing.jpg)

The terms ***strong*** or ***weak*** typing have nothing to do with how hard you hit the keys on the keyboard; instead these terms refer to what sort of value the program expects to find when it looks inside a variable:

* ***Strongly Typed***

    A strongly typed language is one in which you must declare what type of data will be stored in a variable ***before*** you assign a value.
    In other words, you must state upfront that a particular variable will contain an integer or string.

    The compiler is then able to trap any statements that attempt to assign a value of some other datatype.
    C, C++, Java and Rust are examples of language that use strong, compile-time type enforcement rules.

    The purpose of strong typing is to eliminate nasty surprises at runtime.
    For instance, your program will most likely do something unexpected (and probably bad) if, when you read a variable, you expect to find a floating point number, but instead find a printable string.

* ***Weakly Typed***

    A weakly typed language is one that doesn't care about such compile-time details &ndash; usually because these languages tend not to be compiled.

    Weakly typed languages are generally scripting languages that execute interpretively.
    JavaScript, Ruby and Python are examples of interpreted scripting languages, and they all use weak type enforcement.

    Weakly typed languages allow you to assign any value to any variable, and also to interpret the value in a variable as if it were of some other data type.
    On the one hand, this provides the programmer with a huge amount of coding flexibility; but it comes at the cost of having to live with the possibility of experiencing runtime errors due to data of the wrong type being present in a variable.

## What Does It Mean to "Coerce" Something?

> ***Coerce***: Verb
>
> To compel by force, intimidation, or authority, especially without regard for individual desire or volition

So, in the context of a programming language, who or what is being coerced?

There are two main situations in which coercion takes place:

1. The value stored in a variable might automatically be converted (or coerced) to some other datatype
1. The meaning of an operator might be coerced to perform a different operation than the one originally intended.

   For example in JavaScript, under certain circumstances, the arithmetic `+` operator will stop adding up numbers and start performing string concatenation instead!

The point here is that this conversion happens both ***automatically*** and ***silently***.
If you're not aware that such situations can occur, then you might find your code behaving in weird and unexpected ways!

Type coercion exists as a direct consequence of weak type enforcement.
In weakly typed languages, you are allowed to treat the data stored in a variable as if it were of some other type.
(Some strongly typed languages also allow this behaviour.)

---

[^1]: For a more detailed description of type enforcement in programming languages, a good place to start is the Wikipedia article on [Strong and weak typing](https://en.wikipedia.org/wiki/Strong_and_weak_typing)
