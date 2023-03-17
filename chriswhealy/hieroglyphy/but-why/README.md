
# But Why Would You Even Do This?

| Previous | [Top](/chriswhealy/hieroglyphy) | Next
|---|---|---
|   | But Why Would You Even Do This? | [Pulling Ourselves Up By Our Bootstraps](/chriswhealy/hieroglyphy/bootstraps/)

This exercise is not entirely pointless because it explores the area language encoding.
There needs to be a balance whereby the number of characters used in an encoding alphabet is sufficient to provide the required degree of expressiveness and readability.

Given that most high-level programming languages use English keywords, we naturally expect the encoding alphabet to include all 26 letters of the Roman alphabet in both their upper- and lowercase forms, plus the ten digits `0` to `9` plus variety of graphics characters, mathematical operators and symbols and several styles of parenthesis.

This why a regular English keyboard allows you to enter 94 characters, and keyboards for languages that use diacritic letters often have more characters.

However, as we reduce the size of our alphabet, we will see a corresponding increase in word length.
This is simply because in order to represent a unique word using a reduced alphabet, we have to create longer letter sequences.

The coding described here takes the concept of alphabet reduction very close to its absolute minimum.

## The Encoding Alphabet

Many alphabets could be chosen here of varying sizes, but just for fun, we're going to restrict ourselves to an 8-letter alphabet consisting of `+` and `!`, and the three parenthesis pairs `()`, `{}`, and `[]`

| Symbol | Operations
|---|---
| `+`  | Arithmetic addition, Numeric coercion, String concatenation (when overloaded)
| `!`  | Boolean negation, Boolean coercion
| `[]` | Access array elements and objects properties, String coercion
| `()` | Function invocation, Expression delimiter to avoid parsing errors
| `{}` | Gets us `NaN` and the infamous string `[object Object]`

> ***FYI:***<br>
> This 8-character alphabet is close to minimal in size.
> A minimal alphabet can achieve the same result by dropping the use of curly braces `{}`.

## Methodology

Starting from just our set of 8 characters `+!{}[]()`, we proceed as follows:

* Form the simplest JavaScript objects - `[]` and `{}`
* To these objects, apply various combinations of type coercion, Boolean negation and string concatenation
* If they are not already character strings, coerce the returned values to strings
* Slice up these strings to extract individual characters from which other commands can be constructed
* Progressively build up a list of characters until every numeric, alphabetic and graphic character has been encoded

Once we have a full range of encoded characters, we are then in a position to "hieroglyphy" an input string.
The resulting (***very*** long) output can either be turned back into the original JavaScript code by running it through `eval`, or simply executed directly.
