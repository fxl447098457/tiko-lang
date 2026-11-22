# Arrays

An array holds many values of one type under one name, and you reach each one
by its index. tiko arrays carry their **bounds** with them, a first and a last
index, rather than a length. There are two kinds:

- a **fixed** array, whose bounds are written in its declaration and never
  change;
- a **dynamic** array, which starts empty and is sized while the program runs.

```tiko
{{#include ../../examples/arrays/arrays.tiko}}
```

**Output**

```text
{{#include ../../examples/arrays/arrays.out}}
```

`lbound( a )` and `ubound( a )` are the first and last valid index. A loop
written between them works for any array, whatever its bounds, so it never
needs a count remembered somewhere else. The number of elements is
`ubound( a ) - lbound( a ) + 1`.

`days( 1 to 12 )` is indexed by month, so `days( 6 )` is June with no
arithmetic. A brace list fills the elements in index order. Elements that are
never assigned are zero, or an empty string for text; there is no such thing
as an uninitialised element.

```admonish danger title="Pitfall"
A single number in the declaration is the **upper** bound, and the lower bound
is 0: `dim as int32 a( 10 )` has eleven elements, 0 to 10. Write both bounds,
`a( 0 to 9 )`, and the declaration cannot be misread.
```

`dim as ustring names( )`, with empty parentheses, declares a dynamic array.
An empty array's `ubound` is below its `lbound`, so its count is 0 and a loop
over it runs zero times. [Dynamic arrays](dynamic.md) covers `redim` and the
rest.

`a( lo to hi )` names part of an array without copying it;
[Array slices](slices.md) shows it.

### Activities

1. Print every month with 31 days by its number.
2. Declare `dim as int32 a( 5 )` and print its `lbound`, `ubound` and count.
