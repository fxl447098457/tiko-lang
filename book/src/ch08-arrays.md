# Arrays

An array is many values of one type under one name, reached by number. It is the oldest data
structure there is and still the one to reach for first: the elements sit next to each other in
memory, so walking an array is the fastest thing a processor does.

tiko's arrays carry their bounds with them — not a length, but a first and last index, which the
compiler and the runtime both know. That one decision explains most of what follows.

## Bounds, not length

```tiko
{{#include ../examples/ch08/bounds.tiko}}
```

```text
{{#include ../examples/ch08/bounds.out}}
```

`lbound( a )` and `ubound( a )` are the first and last valid index. Every loop over an array in
this book is written between them, and never between `0` and some remembered count.

```admonish danger title="Pitfall"
**`dim as int32 a( 10 )` declares eleven elements, not ten.** A single number is the *upper bound*,
and the lower bound defaults to 0 — so the valid indices are 0 through 10.

Anyone arriving from C, Java, Python or Rust will read that line as "ten elements" and write a
loop from 0 to 9, quietly ignoring the last one. The reverse mistake is worse: read it as "indices
0 to 9" in a language where the eleventh exists, and a bug hides in the element nobody looks at.

**Write both bounds.** `dim as int32 a( 0 to 9 )` says exactly what it means, in the same number of
keystrokes, and it cannot be misread.
```

Elements start at zero — or empty, for a string — so there is no such thing as an uninitialised
array element. An initialiser in braces fills them in order.

A lower bound other than 0 is worth using when the index means something. `band( 0 to 9 )` in the
histogram below is indexed by tens, and `temperature( 1900 to 2000 )` indexed by year needs no
arithmetic at the point of use, which is where arithmetic goes wrong.

## Arrays that change size

```tiko
{{#include ../examples/ch08/dynamic.tiko}}
```

```text
{{#include ../examples/ch08/dynamic.out}}
```

`dim as int32 a( )` declares an array with no room yet. Its `ubound` is **below** its `lbound`,
which is how an empty array reads — and why `for i = lbound( a ) to ubound( a )` over an empty
array runs zero times instead of needing a guard.

`redim` gives it a size. `redim preserve` gives it a size **and keeps what was there**, growing
with zeros and shrinking by truncation.

```admonish danger title="Pitfall"
**`redim` without `preserve` discards every element.** It is not a resize; it is a fresh array at
the same name.

That is easy to accept when you read it here and easy to miss in code, because nothing about
`redim a( 1 to 5 )` looks destructive, and the array is still there afterwards — just full of
zeros. The listing above shows `10 20 30` becoming `0 0 0 0 0`.

Reach for `redim preserve` by default, and use plain `redim` only when you mean to start over.
```

`erase` does two different things, and which one depends on the array:

```tiko
{{#include ../examples/ch08/erasefixed.tiko}}
```

```text
{{#include ../examples/ch08/erasefixed.out}}
```

On a **dynamic** array, `erase` frees the storage and leaves it empty. On a **fixed** array there
is nothing to free, so it resets the elements and the bounds stay. One keyword, two meanings,
neither surprising once you know which array you are holding.

## An array indexed by what it counts

```tiko
{{#include ../examples/ch08/histogram.tiko}}
```

```text
{{#include ../examples/ch08/histogram.out}}
```

This is the shape worth recognising: the index *is* the data. `band( score \ 10 )` needs no search
and no comparison chain — the value computes its own slot, and counting is one addition.

The bounds document the meaning. `band( 0 to 9 )` says there are ten bands of ten; the clamp says
what happens to a perfect score. Both are visible at the declaration rather than implied by a loop
somewhere below.

## More than one subscript

```tiko
{{#include ../examples/ch08/matrix.tiko}}
```

```text
{{#include ../examples/ch08/matrix.out}}
```

Dimensions are separated by commas, and `lbound`/`ubound` take the dimension number as a second
argument: `ubound( m, 2 )` is the last column index. An array may have up to eight dimensions.

The last line of that output is the one to keep. Reading the same storage as a flat run of `int32`
gives `0 1 2 3 4 5` — the order the elements were written, row by row. **The last subscript varies
fastest.** A row is contiguous; a column is strided.

That is not a detail of the implementation you are free to ignore, because it decides how fast the
loop runs. Iterating with the last subscript innermost walks memory forwards and every cache line
that is fetched gets used. Swapping the loops reads one element per cache line, and on a large
array that is the difference between fast and slow, with identical source.

## Filling an array with braces

```tiko
{{#include ../examples/ch08/braces.tiko}}
```

```text
{{#include ../examples/ch08/braces.out}}
```

A brace list gives the elements in index order, from `lbound` up. An array with more than one
dimension takes one level of braces per dimension, in the order the last section described: the
first inner list is row 0, so `{ { 1, 2, 3 }, { 4, 5, 6 } }` puts `4 5 6` in row 1.

`...` as the upper bound lets the list decide the size. `squares( 1 to ... )` has four elements
because four values were given, so adding a fifth value cannot leave the bounds behind.

Braces are for arrays, and only at the declaration. A single value takes `=` and the value. A brace
list on anything that is not an array is refused:

```tiko
{{#include ../examples/ch08/bracescalar.tiko}}
```

```
bracescalar.tiko(4,22): error TKO0845: 'total' is not an array, so it cannot take a '{ ... }' initializer
     |
   4 | dim as int32 total = { 0 }          '' refused
     |                      ^
```

A brace list is not a value either, so it cannot be assigned later:

```tiko
{{#include ../examples/ch08/bracelater.tiko}}
```

```
bracelater.tiko(5,10): error TKO0846: a '{ ... }' list can only initialize an array, and nothing here is one
     |
   5 | scores = { 0, 0, 0 }                '' refused
     |          ^
```

To refill an array, loop over it, or assign the elements one at a time. A container from the
standard library is the one other thing a brace list can fill; Chapter 17 shows how.

fbc refuses both lines too, with its errors 63 and 73.

## Passing an array to a procedure

```tiko
{{#include ../examples/ch08/params.tiko}}
```

```text
{{#include ../examples/ch08/params.out}}
```

A parameter is written `a( ) as int32` and the argument is written `a( )` — the empty parentheses
are required at both ends. An array is always passed by reference; there is no copy, and writes
inside the procedure are writes to the caller's array.

The bounds travel with it. `FillWith` was given an array indexed 5 to 8 and saw exactly that, which
is why a procedure that works from `lbound` and `ubound` works on any array of the right type
without being told anything else.

A multi-dimensional parameter states its **rank** with commas and nothing more: `m( , ) as int32`
takes any two-dimensional `int32` array. Rank is fixed at compile time; bounds are not.

## Returning an array

A function that builds a table has to give it to its caller somehow, and the old answers are both
awkward. The caller can create the array first and let the function fill it in, which means the
caller must know the size before the function has decided it. Or the array can be wrapped in a
container just to cross one `return`. tiko lets a function return the array itself: write `( )`
after the result type.

```tiko
{{#include ../examples/ch08/returning.tiko}}
```

```text
{{#include ../examples/ch08/returning.out}}
```

The result is an ordinary dynamic array. It is what `dim a( )` makes, it is indexed the same way,
and a parameter written `a( )` accepts it. It is not a container. Only an empty `( )` means an
array: `as int32( 3 )` is refused (`TKO0836`), where it used to be quietly read as a plain `int32`.

`return` takes three things:

- **A brace list.** The array is sized to the list, indexed from 0, and filled. A list inside a
  list is refused (`TKO0839`); write it flat. Any element type works, and each element is built
  once.
- **A local array**, as `Squares` does. It is **moved**, not copied: the function's own variable
  is left empty and the caller receives the array it built, bounds included. `sq` runs from 1 to
  5 because `Squares` said so.
- **A call that returns an array**, handed straight through.

`function = value` takes the same three and carries on afterwards, as it does for any result. A
function that never sets one returns an empty array: `ubound` is −1 and a loop over it runs zero
times.

The caller owns what comes back. `var p = FirstPrimes( )` takes the array itself. `m = Squares( 3 )`
frees what `m` held and moves the new array in. `ShowSum( Squares( 4 ) )` and `for each` over a call
use the array and free it when the statement ends, and a result nobody uses is freed there too. Two
calls never share a buffer, so there is nothing to release by hand.

Only an array that belongs to the function can be moved out. A parameter, a `shared` or `static`
array and a field all belong to somebody else: handing one back would leave its owner pointing at
freed memory, and the other way to do it is a copy, which tiko does not make for you yet.

```tiko
{{#include ../examples/ch08/returnparam.tiko}}
```

```text
returnparam.tiko(5,5): error TKO0840: 'a' is not a local array of this procedure, so returning it would need a copy, which is not supported yet; return a local array or a brace list
     |
   5 |     return a
     |     ^
```

To hand back a copy, build a local array element by element and return that.

The same care applies at the call. The name of a function that returns an array needs its
parentheses, so `var b = FirstPrimes` is `TKO0841` rather than a call. An array is not a number, so
`dim as int32 x = FirstPrimes( )` is `TKO0842`. And `dim a( ) as int32 = FirstPrimes( )` is
`TKO0612`, as it is for any initialised dynamic array: `var` takes the result, `dim` does not.

```admonish warning title="Status in this version"
Two limits remain. A function type cannot return an array (`as function( ) as int32( )` is
`TKO0837`), and array results of properties and operators have not been tried.
```

## Walking it

```tiko
{{#include ../examples/ch08/walking.tiko}}
```

```text
{{#include ../examples/ch08/walking.out}}
```

Three ways across, and the difference between the last two matters:

- **By index**, `for i = lbound( a ) to ubound( a )`. You have the position as well as the value,
  which you need whenever the answer depends on where you are.
- **`for each v as T in a`** hands you a **copy** of each element. Writing to `v` changes nothing —
  the listing proves it.
- **`for each byref v as T in a`** hands you the element itself, so writes land in the array.

Use `for each` when you only need the values, and `byref` when you mean to modify them. The `byref`
form also avoids copying each element, which matters when the elements are large.

`for each` will not walk a grid:

```tiko
{{#include ../examples/ch08/foreach2d.tiko}}
```

```text
foreach2d.tiko(4,1): error TKO0608: 'for each' over a multi-dimensional array has no defined order
     |
   4 | for each v as int32 in m        '' refused: which way, rows or columns?
     | ^
```

The compiler could have picked row-major and said nothing. Refusing is the better answer: an
iteration order over a grid is a decision the code should state, not one to inherit silently from
the memory layout.

## When the index is wrong

An index outside the bounds reads or writes memory that belongs to something else. Chapter 1
introduced `-exx`, which adds a check to every array access and stops the program with runtime
error 6 rather than letting it continue with nonsense.

The check covers a dynamic array as well as a fixed one. Its bounds are not in the source, so the
check reads them from the array's descriptor at run time, on every access, and a `redim` that
shrinks the array moves the limit with it:

```tiko
{{#include ../examples/ch08/exxdynamic.tiko}}
```

```text
{{#include ../examples/ch08/exxdynamic.out}}
```

The program stops with exit code 6 at the first bad write, before it can corrupt anything.

In a build without `-exx`, the check you write yourself is the one you can rely on:

```tiko
{{#include ../examples/ch08/guard.tiko}}
```

```text
{{#include ../examples/ch08/guard.out}}
```

Comparing against `lbound` and `ubound` costs two comparisons and works on every array, of every
kind, in every build. Where an index comes from outside the program — a file, an argument, a
calculation you are not certain of — that guard is not optional.

```admonish note
**One array is not assigned to another.** `a = b` between arrays is refused —
`TKO0930: a whole array cannot be assigned or swapped` — and so is `swap a, b`, because the two
may not even be the same size. To copy an array, loop over its elements.
```

## Text stored in an array

```tiko
{{#include ../examples/ch08/textarray.tiko}}
```

```text
{{#include ../examples/ch08/textarray.out}}
```

Growing an array one element at a time — `redim preserve` to `ubound + 1`, then write the new
slot — is the pattern for building a list whose length is not known in advance. It is correct, and
it is also the slow way to do it: each `redim preserve` may copy the whole array, so appending *n*
items can cost *n²* work.

For a handful of rows that does not matter. For a file of them it does, and the answer is either to
grow in chunks — double the size when it fills — or to use the container that already does exactly
that, which is the next section.

## Part of an array, without a copy

A procedure that should work on *some* of an array has had two choices: take the whole array and
a first and last index beside it, or copy the part it wants into a new array. A **span** is the
third: it names a run of an array where the elements already are.

```tiko
{{#include ../examples/ch08/spans.tiko}}
```

```text
{{#include ../examples/ch08/spans.out}}
```

`a( 2 to 4 )` is elements 2 to 4, **both ends included, in the array's own indices** — the same
numbers `a( i )` takes. What comes back is a `span( of int32 )`, and a span counts from 0 whatever
the array did: `v( 0 )` is `a( 2 )`, `lbound( v )` is always 0 and `ubound( v )` is
`len( v ) - 1`. The parentheses are an array's, as `s[lo to hi]` uses a string's brackets.

A span is a pointer and a length, never a copy, so **writing through it writes the array**:
`v( 1 ) = 99` changed `a( 3 )`. A span of a span is a smaller view of the same elements, and
`for each byref` over a span reaches the array's own elements. A span of a `const` array is a
`const span`, and writing through it is refused.

`a( 4 to 3 )` is empty, so `a( lbound( a ) to ubound( a ) )` is the whole array even when the
array is. Anything else outside the bounds is runtime error 6 — checked whenever a span is made, in
every build — and bounds the compiler can see are wrong, past the end of a fixed array, are
`TKO1071` before the program runs. Reading `v( i )` past the end is checked under `-exx`, as any
subscript is.

Only a one-dimensional array can be sliced (`TKO1069`). Any element type works: numbers, strings,
your own types.

### Passing a span around

```tiko
{{#include ../examples/ch08/spanpass.tiko}}
```

```text
{{#include ../examples/ch08/spanpass.out}}
```

A `byval v as span( of int32 )` parameter is three words, whatever the length of the run. `Sum`
neither knows nor cares which array the elements belong to, and a function may hand back a span of
a span it was given, as `Middle` does.

**A span goes where `a( ) as int32` is wanted.** `DoubleAll` is an ordinary array procedure; given
`d( 4 to 7 )` it sees a four-element array indexed 0 to 3, and its writes land in `d`. So the
array procedures you already have work on part of an array with no change. The element type must
match exactly (`TKO0687`). One thing the procedure cannot do is `redim` what it was given — that is
runtime error 1, the same as for a fixed array — and an `erase` inside it clears those elements of
`d`.

### A span cannot outlive its array

A span points into memory it does not own, so the compiler keeps it there. The rules are the ones
Chapter 9 gives for string slices: a span lives in a local, a parameter or a result, never in a
`shared` variable, an array or a field of an ordinary type; it is not kept past the block its array
belongs to; and a function returns a span only of what its caller handed it.

The one new rule is about **moving**. `redim` and `redim preserve` may move a dynamic array to new
memory, and `erase` frees it:

```tiko
{{#include ../examples/ch08/spanlock.tiko}}
```

```text
spanlock.tiko(5,1): error TKO1062: 'd' cannot be changed while slice 'v' borrows from it (last used at line 6)
```

While a span of `d` is still to be used, `redim`, `erase` and passing `d( )` to a procedure (which
may `redim` it) are refused. Take the span again after the `redim` and the program compiles. A
fixed array never moves, so it is never locked. What one procedure cannot see — a procedure
given both the span and the array, which then `redim`s the array — is caught at run time under
`-exx`.

## The descriptor

```tiko
{{#include ../examples/ch08/descriptor.tiko}}
```

```text
{{#include ../examples/ch08/descriptor.out}}
```

An array variable is a **descriptor**: a pointer to the elements plus the bounds, the element size
and the number of dimensions. That is what travels when an array is passed, and what `lbound` reads.

`fbc-int/array.bi` exposes it. `FB.ArrayLen` is the total element count across all dimensions and
`FB.ArraySize` the total bytes; `FBC.ArrayDescriptorPtr` hands over the record itself. You will not
often need these, and when you do — writing a procedure that takes an array of any type, checking
what a `redim` actually allocated — nothing else will do.

## When to reach for something else

An array is the right answer when the index is meaningful and the size is known, or grows rarely.
It is the wrong answer when you find yourself writing the bookkeeping around it: a separate count
of how many slots are really in use, a doubling strategy, a search to find where something is.

That bookkeeping is what `containers.Array( of T )` already contains, along with `Map`, `Set` and
the rest of the containers in Chapter 24. The rule is the ordinary one: use the raw array while it
is simpler, and stop as soon as it is not.

## What it costs

- **Indexing is an address calculation**, not a search. Cost does not depend on which element.
- **`redim preserve` may copy everything.** Growing one at a time is quadratic; grow in chunks.
- **Row-major order is a performance fact**, not trivia — put the last subscript in the inner loop.
- **`-exx` costs a comparison per access.** It is worth it while you are writing the program;
  measure before you decide it is not worth it afterwards.
- **`for each byref` avoids copying each element**, which is free to write and matters for large
  ones.
- **Returning an array moves it.** The cost is one descriptor, a fixed few hundred bytes, whatever
  the length of the array; the elements are never copied.

## Summary

- An array carries **bounds**, not a length: `lbound` and `ubound` are the first and last index.
- **`a( 10 )` is eleven elements**, indexed 0 to 10. Write both bounds.
- Elements are zero-initialised; an initialiser in braces fills them in order, one level of braces
  per dimension, and `1 to ...` lets the list set the size.
- **Braces initialize arrays and nothing else**: not a single value (`TKO0845`), and not an
  assignment after the declaration (`TKO0846`).
- `dim a( )` is empty, with `ubound` below `lbound`, so loops over it run zero times.
- **`redim` discards the contents; `redim preserve` keeps them.** `erase` frees a dynamic array and
  zeroes a fixed one.
- Dimensions are comma-separated, `ubound( m, 2 )` names one, and **the last subscript varies
  fastest**.
- Arrays pass by reference as `a( )`, carrying their bounds; a rank-2 parameter is written `m( , )`.
- A function returns an array with `as int32( )`. `return` takes a brace list, a **local** array
  (moved, never copied) or another call, and the caller owns the result: `var` takes it, `m = f( )`
  replaces what `m` held. A parameter or `shared` array cannot be returned (`TKO0840`).
- `for each` gives copies, `for each byref` gives the elements, and neither will walk a
  multi-dimensional array (`TKO0608`).
- **`-exx` checks every subscript, fixed or dynamic**, against the bounds the array has at that
  moment. Without it, compare against `lbound` and
  `ubound` yourself when the index is not obviously safe.
- **An array is not assigned or swapped whole** (`TKO0930`); copy it element by element.
- **`a( lo to hi )` is a span**, `span( of T )`: part of a one-dimensional array, no copy, in the
  array's indices; the span itself counts from 0. Writes go through to the array, a span passes
  where `a( )` is wanted, and while one is in use its dynamic array cannot be `redim`med or
  `erase`d (`TKO1062`).
- The array variable is a descriptor; `fbc-int/array.bi` exposes `FB.ArrayLen`, `FB.ArraySize` and
  the record itself.
- **Stop using a raw array when you start writing bookkeeping around it** — a live count, a doubling
  strategy, a search. `containers.Array( of T )` and the containers in Chapter 24 already contain
  it, and growing one element at a time with `redim preserve` is quadratic.

## Exercises

1. Write `Reverse`, which reverses an array in place and works whatever its bounds — test it on
   arrays indexed from 1, from 0 and from −2, and on an empty one. Use no literal 0 and no literal
   length. {solution="ex08-01"}
2. Transpose a two-dimensional array into a second array whose dimensions are the original's,
   swapped. Where do the new bounds come from? {solution="ex08-02"}
3. Predict how many elements `dim as int32 a( 5 )` has before running anything, then print
   `lbound`, `ubound` and the count. Rewrite the declaration so the answer is obvious.
4. Take the `redim` line in `dynamic.tiko`, add `preserve`, and say in one sentence what each
   version is for.
5. Build a 200 × 200 array and sum it twice: once with the last subscript innermost, once with the
   loops swapped. Both give the same total. Which do you expect to be faster, and why?
6. Write `Evens( byval n as int32 )`, returning the first `n` even numbers as an array indexed from
   1, and `Doubled( a( ) as int32 )`, returning a new array of the same bounds with every element
   doubled. Take `var e = Evens( 4 )` and print `Doubled( e( ) )` with `for each`. Why can `Doubled`
   not simply `return a`?
