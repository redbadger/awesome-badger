
# But Why Would You Even Do This?

| Previous | [Top](/chriswhealy/hieroglyphy) | Next
|---|---|---
|   | But Why Would You Even Do This? | [Pulling Ourselves Up By Our Bootstraps](/chriswhealy/hieroglyphy/bootstraps/)

This exercise is not entirely pointless because it explores the area of language encoding.

When deciding on the size of an encoding alphabet, there needs to be a balance between providing sufficient characters to allow for expressiveness and readability, yet not providing every possible character simply because within your language, it has a non-zero probability of being used.

Given that most high-level programming languages use English keywords, we naturally expect the encoding alphabet to include:

| Type | Characters | Count
|---|---|--:
| The letters of the Roman alphabet | `[a..z][A..Z]`    | 52
| The digits                        | `[0..9]`          | 10
| Graphic and currency characters   | `@#%^_\` and `£$€`| 9
| Punctuation characters            | `!?:;,."'`        | 8
| Mathematical operators            | `&|+-*/=<>`       | 9
| Parenthesis Pairs                 | `(){}[]`          | 6

This why a regular English keyboard makes provision for at least 94 characters; and in languages that use diacritics, their keyboards often require more.

However, as we reduce the size of our alphabet, we will see a corresponding drop in legibility and an increase in word length.
This is simply because as the number of letters in your alphabet decreases, so the number of letters needed to represent a unique word increases.

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

As an option, I have extended the coding in [hieroglyphy.mjs](https://github.com/ChrisWhealy/hieroglyphy/blob/master/hieroglyphy.mjs) to allow you to include the digits characters `['0'..'9']` in the encoding alphabet.
This increases the alphabet size from 8 characters up to 18, but has the benefit of reducing the encoded length by approximately 40%.

> ***FYI:***<br>
> This 8-character alphabet is close to minimal in size.<br>
> A minimal alphabet drops the use of curly braces `{}`.

## Methodology

Starting from just our set of 8 characters `+!{}[]()`, we proceed as follows:

* Form the simplest JavaScript objects &mdash; `[]` and `{}`
* To these objects, apply various combinations of type coercion, Boolean negation and string concatenation
* If they are not already character strings, coerce the returned values to strings
* Slice up these strings to extract individual characters from which other keywords can then be constructed

In this manner, we can progressively build up a full alphabet of encoded characters.

Once we have a full alphabet, we are then in a position to "hieroglyphy" an input string.
The resulting (***extremely*** long) output can either be turned back into the original JavaScript code by running it through `eval`, or executed directly.
