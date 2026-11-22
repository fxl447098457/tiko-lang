# Array slices

A procedure that works on *part* of an array used to need the whole array
and two indices beside it, or a copy of the part. A **span** names part of
an array where the elements already are: `a( lo to hi )`.

```tiko
{{#include ../../examples/arrays/slices.tiko}}
```

**Output**

```text
{{#include ../../examples/arrays/slices.out}}
```

**`temps( 3 to 5 )` uses the array's own indices**, both ends included: the
same numbers `temps( i )` takes. What comes back is a `span( of int32 )`, and
**a span counts from 0** whatever the array did: `midweek( 0 )` is
`temps( 3 )`, `lbound` is 0 and `ubound` is `len - 1`. An array takes
parentheses as a string takes brackets: `s[lo to hi]` is a string slice.

A span is a pointer and a count, never a copy, so **writing through it writes
the array**, and `for each byref` over a span reaches the array's own
elements. A span of a `const` array is `const`, and refuses writes.

**A span is the parameter for "some of an array".** `Average` neither knows
nor cares which array, or which part of it, it was given. A span passes and
returns by value, and a function may return a span of the one it was handed.

**A span goes where `name( ) as Type` is wanted.** `Warm` is an ordinary array
procedure; given `temps( 6 to 7 )` it sees a two-element array indexed 0 to 1,
and its writes land in `temps`. The element type must match exactly.

`a( 4 to 3 )` is empty, so `a( lbound( a ) to ubound( a ) )` is the whole
array even when it is empty. Any other range outside the bounds is runtime
error 6, checked every time a span is made. Only a one-dimensional array can
be sliced.

A span must not outlive its array, and the rules are the ones for
[string slices](../strings/slicelife.md). One rule is the array's own: a
dynamic array cannot be resized while a span of it is still to be used,
because `redim` may move it.

```tiko
{{#include ../../examples/arrays/slicelock.tiko}}
```

```text
slicelock.tiko(6,1): error TKO1062: 'readings' cannot be changed while slice 'head' borrows from it (last used at line 7)
     |
   6 | redim preserve readings( 0 to 99 )
     | ^
```

`redim`, `redim preserve`, `erase` and passing the array to a `name( )`
parameter all count, up to the last line that reads the span. A fixed array
never moves, so it is never locked.

### Activities

1. Write `function Largest( byval v as span( of int32 ) ) as int32` and use it
   to find the warmest day of the week and of the weekend.
2. Move `print head( 0 )` above the `redim preserve` in `slicelock.tiko` and
   run it.
3. Pass `temps( 1 to 3 )` to `Warm` twice and print `temps`. Which days
   changed?
