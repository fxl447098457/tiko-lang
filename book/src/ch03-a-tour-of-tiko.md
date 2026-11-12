# A Tour of tiko

The last chapter got a compiler working. This one writes something with it — a program that reads
a file, counts the words in it, and reports the three most common. It is small enough to hold in
your head and big enough to need most of what the language is made of: the standard library,
strings, a hash map, iteration, sorting, a lambda, and errors that are values rather than
surprises.

Nothing here is explained completely. The point is to see the shape of a tiko program before
taking it apart, and every idea below is picked up properly in a later chapter. Read it the way
you would read someone else's code: get the sense of it, and let the details wait.

The file we are counting is three lines:

```text
{{#include ../examples/ch03/words.txt}}
```

## Reaching the standard library

tiko's library comes in modules, and a program says which ones it wants:

```tiko
{{#include ../examples/ch03/step1.tiko}}
```

```text
{{#include ../examples/ch03/step1.out}}
```

`#import "std/fs"` makes the filesystem module available under the name `fs`, and every name it
provides is reached through that prefix — `fs.ReadAllText`. That prefix is not decoration; it is
how a reader of your code knows where a function came from.

The interesting part is what `ReadAllText` gives back. Not a string: a **`Result`**, which is
either the text or the reason there is no text. There is no exception to catch and no error code
to remember to check, because the value itself will not hand over its contents until you have
asked whether it has any:

- `loaded.IsOk( )` — did it work?
- `loaded.Value( )` — the text, once you know it worked.

A program that forgets to check does not silently read nonsense; it fails to compile in the shape
you would have wanted. Chapter 18 is about designing with `Result`.

```admonish note
`var` declares a variable and takes its type from the value, the way `dim as ustring text = …`
would if you wrote the type out. Use `var` when the type is obvious from the line, and the full
form when it is not.
```

## Splitting the text into words

```tiko
{{#include ../examples/ch03/step2.tiko}}
```

```text
{{#include ../examples/ch03/step2.out}}
```

Two library calls do the work. `strings.Replace` flattens the newlines into spaces, and
`strings.Split` cuts the result on spaces and hands back an array. `words.Count` is how many it
found.

`strings.Replace` runs twice because a text file can end its lines two ways: Windows writes CR LF
(`!"\r\n"`), Linux and macOS write LF alone. The first call turns every CR LF into a plain LF, so
the second sees one kind of line ending whichever system wrote the file. Skip the first call and a
CR stays stuck to the last word of every line, and the console prints that CR as a return to the
start of the line.

`for each w in words` walks the array without an index, without a bound, and without the
off-by-one that an index loop invites. The loop variable's type comes from the array, so `w` is a
`ustring` — tiko's string type, which holds text rather than bytes and is the same on every
platform.

The `if len( w ) > 0` is there because splitting on a single space leaves empty pieces wherever
two spaces met. Real text is untidy; the program says so rather than pretending.

## Counting

```tiko
{{#include ../examples/ch03/step3.tiko}}
```

```text
{{#include ../examples/ch03/step3.out}}
```

`containers.Map( of ustring, int32 )` is a hash map from text to a number. The `( of … )` is
tiko's generics syntax: this is not a map of "anything", it is a map whose keys are `ustring` and
whose values are `int32`, checked as thoroughly as if you had written the type by hand. Chapter 17
is about writing your own.

`counts[ LCase( w ) ] += 1` does the whole count. Indexing a map with a key that is not there
inserts it with a zero value, so the `+= 1` works the first time a word appears as well as the
fifth. `LCase` folds the case, so *The* and *the* are one word.

## Ranking, with a lambda

A map has no order, so the last step copies the counts into an array and sorts it:

```tiko
{{#include ../examples/ch03/wordcount.tiko:rank}}
```

`for each entry in counts` walks the map, and each `entry` carries a `Key` and a `Value`.

`containers.SortBy` takes the array and a **lambda** — a function written where it is used, with
no name. This one answers a single question: does `a` come before `b`? Sorting by descending count
is `a.count > b.count`, and changing the ranking means changing that one line. Chapter 20 is about
lambdas, including the ones that capture variables from around them.

The `_` at the end of the `SortBy` line continues the statement onto the next line. tiko has no
statement terminator, so a line break ends a statement unless you say otherwise.

## Reporting

```tiko
{{#include ../examples/ch03/wordcount.tiko:report}}
```

`print using` formats output against a picture: `\    \` is a text field of that width, and `#` is
a digit. It is the one piece of this program that will look unfamiliar to most readers, and it is
worth the surprise — lining up columns with string concatenation is miserable.

## The whole program

```tiko
{{#include ../examples/ch03/wordcount.tiko:all}}
```

```text
{{#include ../examples/ch03/wordcount.out}}
```

Forty lines, no memory management, no build file, and one command to build it:

```bash
tiko wordcount.tiko -o wordcount
./wordcount
```

The result is a native executable that depends on nothing you have to ship beside it.

```admonish danger title="Pitfall"
`read` is not available as a variable name — it belongs to the `data`/`read` statement pair that
tiko keeps for compatibility. The compiler says `TKO0600: 'read' is already declared in this
scope`, which is accurate but startling when you were not thinking about `data` at all.

The same applies to other short, tempting names: `str`, `left`, `mid`, `window`, `log`. When a
name is refused for no reason you can see, that is usually why — pick another.
```

## What you have seen

Each of these has a chapter of its own:

| In this program | Chapter |
|---|---|
| `#import` and the `std` modules | 14 |
| `Result`, and errors as values | 17 |
| `ustring` and the string library | 8 |
| `Map`, `Array`, `SortBy` | 22 |
| `for each` | 18 |
| generics, the `( of … )` syntax | 16 |
| lambdas | 19 |
| `print using` and console output | 23 |

## Summary

- A program reaches the library with `#import "std/…"`, and uses the module's name as a prefix.
- Fallible calls return a `Result`: ask `IsOk( )`, then take `Value( )`.
- `var` infers a variable's type; `dim as T` states it.
- `for each` walks an array without an index; the loop variable's type comes from the elements.
- `Map( of K, V )` is a checked hash map, and indexing a missing key inserts it.
- A lambda is a function written where it is used — `SortBy` takes one to decide the order.
- One command compiles and links a native executable.

## Exercises

1. Report the longest word in the file as well as the most common ones. {solution="ex03-01"}
2. List the words that appear exactly once, in alphabetical order. `OrderedMap` keeps its keys
   sorted, where `Map` does not. {solution="ex03-02"}
3. Make the program take the file name from the command line, falling back to `words.txt` when
   none is given. Chapter 1 showed `command( 1 )`.
4. The ranking prints three words. Make it print the top three *counts*, so that words tied for
   third all appear.
