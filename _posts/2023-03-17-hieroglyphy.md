---
layout: post
title:  "Hieroglyphy: Taking JavaScript Type Coercion to its Illogical Conclusion"
date:   2023-03-17 12:00:00 +0000
category: chriswhealy
author: Chris Whealy
excerpt: JavaScript is (in)famous for being a highly dynamic language that allows a developer to write very "flexible" code.  One language feature that makes a significant contribution to this flexibility is the idea of type coercion; that is, JavaScript will automatically (and silently) transform a value of one type into a value of a different type.<br>As you can imagine however, the more you explore the language's flexibility, the higher a price you pay in terms of code legibility.<br>Largely for the sake of amusement, this blog takes JavaScript's flexibility to the most extreme (and illogical) conclusion by providing you with an encoding library that takes a regular JavaScript program as input and returns a very long character string that is executable, functionally identical, and completely unreadable!
---

# Table of Contents

* [But Why?](/chriswhealy/hieroglyphy/but-why/)
* [Pulling Ourselves Up By Our Bootstraps](/chriswhealy/hieroglyphy/bootstraps/)
* [Pulling Some Strings](/chriswhealy/hieroglyphy/strings/)
* [What Have We Achieved So Far?](/chriswhealy/hieroglyphy/checkpoint1/)
* [Extracting Characters From Keywords](/chriswhealy/hieroglyphy/keywords/)
* [Tricks With Big Numbers](/chriswhealy/hieroglyphy/numbers/)
* [So Where Are We Now?](/chriswhealy/hieroglyphy/checkpoint2/)
* [Tricks With Functions](/chriswhealy/hieroglyphy/functions/)

# Introduction

The functionality described in this blog is neither new nor is it unique.
In this case, it is an extensive rewrite and optimisation of the original [Hieroglyphy](https://github.com/alcuadrado/hieroglyphy) by [Patricio Palladino](https://github.com/alcuadrado/).

Here is my version of [Hieroglyphy](https://github.com/ChrisWhealy/hieroglyphy).

[Other variations](https://github.com/aemkei/jsfuck) of this style of app exist that use a minimal alphabet, but in this particular case, a close-to-minimal alphabet has been chosen.

> ***WARNING***<br>
> I can think of no practical reason why you would ever want to use this library in a real life situation...
>
> 🤪
>
> But that said, the process by which it works is interesting if you really want to understand the inner workings of JavaScript's type coercion behaviour

# Overview

There has been some investigation into encoding the source code of a JavaScript program such that it uses a reduced alphabet, but remains syntactically valid and executable.
Irrespective of whether or not the encoded program remains human readable, you must still be able to `eval` or execute it.

For example:

```javascript
$ node
Welcome to Node.js v16.12.0.
Type ".help" for more information.
> eval('(+((+!![]+[])+(!![]+!![]+!![]+!![]+!![]+!![]+!![]+[])))[(!![]+[])[+[]]+([]+{})[+!![]]+([]+([]+{})[([]+{})[!![]+!![]+!![]+!![]+!![]]+([]+{})[+!![]]+([][+[]]+[])[+!![]]+(![]+[])[!![]+!![]+!![]]+(!![]+[])[+[]]+(!![]+[])[+!![]]+([][+[]]+[])[+[]]+([]+{})[!![]+!![]+!![]+!![]+!![]]+(!![]+[])[+[]]+([]+{})[+!![]]+(!![]+[])[+!![]]])[!![]+!![]+!![]+!![]+!![]+!![]+!![]+!![]+!![]]+(!![]+[])[+[]]+(!![]+[])[+!![]]+([][+[]]+[])[!![]+!![]+!![]+!![]+!![]]+([][+[]]+[])[+!![]]+([]+([]+{})[([]+{})[!![]+!![]+!![]+!![]+!![]]+([]+{})[+!![]]+([][+[]]+[])[+!![]]+(![]+[])[!![]+!![]+!![]]+(!![]+[])[+[]]+(!![]+[])[+!![]]+([][+[]]+[])[+[]]+([]+{})[!![]+!![]+!![]+!![]+!![]]+(!![]+[])[+[]]+([]+{})[+!![]]+(!![]+[])[+!![]]])[+((+!![]+[])+(!![]+!![]+!![]+!![]+[]))]](+((!![]+!![]+!![]+[])+(!![]+!![]+!![]+!![]+!![]+!![]+[])))+(!![]+[])[!![]+!![]+!![]]+(![]+[])[!![]+!![]]+(![]+[])[!![]+!![]]+([]+{})[+!![]]')
'hello'
>
```

# Room from improvement

This library is just a proof of concept; there is plenty of room for improvement:

* Ensure that all characters have been encoded using the shortest possible representation
* Allow some flexibility in the alphabet size to account for different target runtime environments
* Knowing the specific runtime would allow us to take advantage of features unique to that environment, which in turn, may yield shorter characters encodings
