# match

`match` compares one value against **patterns**. It looks like `select case`,
with one difference that matters as a program grows: it does not compile until
every value the subject can have is handled. Used as a value, it gives the
value of the arm that matched:

```tiko
{{#include ../../examples/flow/match.tiko}}
```

**Output**

```text
{{#include ../../examples/flow/match.out}}
```

| Form | Arms | Example |
|---|---|---|
| statement | `case pattern`, then a body of any length | `match temps(i)` above |
| value | `pattern => value`, one line each | `return match s` above |

Arms are tried from the top, the first match wins, and there is no
fall-through. `else` catches everything left and must be the last arm.

**Every case must be handled.** `Colour` lists all four suits, so it needs no
`else`. Forget one and the program does not compile:

```tiko
{{#include ../../examples/flow/matchmissing.tiko}}
```

```text
error TKO1250: 'match' is not exhaustive: spades is not handled
```

The compiler knows the members of an enum and the two values of a `boolean`.
For an integer or a string no list can be complete, so a `match` on one needs
an `else`, as the temperature `match` has.

## Taking a value apart

Inside a pattern, a UDT's fields and a tuple's elements can be matched one by
one, and a plain name **binds** the part it stands for. An `if` after the
pattern is a **guard**: the arm matches only when it also holds.

```tiko
{{#include ../../examples/flow/matchparts.tiko}}
```

**Output**

```text
{{#include ../../examples/flow/matchparts.out}}
```

| Pattern | Matches | Binds |
|---|---|---|
| `200`, `"quit"`, `Suit.Hearts` | that value | — |
| `1, 2, 3` | any value in the list | — |
| `0 to 15` | a range, both ends included | — |
| `is < 0` | any value the comparison accepts | — |
| `any` | anything | — |
| `( p, q )` | a tuple, element by element | what its elements bind |
| `Point( x, 0 )` | a `Point`, field by field in declaration order | `x` |
| `c as Circle` | a base pointer that points at a `Circle` | `c`, a `Circle ptr` |
| `starts "load " rest` | a string beginning with `"load "` | `rest`, the remainder |

The tuple `match` checks all four combinations of two booleans. It uses
`cbool( a = 1 )`: a comparison yields an integer, not a `boolean`, and a tuple
of integers has no complete list of values, so without `cbool` the compiler
would ask for an `else`.

A bare name at the top of a pattern is a *value*, as in `select case`
(`case Red`); inside a tuple or UDT pattern it *binds*. A guarded arm does not
count towards the exhaustiveness check, which is why `Point( x, y ) if x = y`
is followed by more arms.

```admonish note
`match` is a contextual keyword: a variable or procedure named `match` keeps
working.
```

### Activities

1. Add a fifth suit, `Jokers`, to the enum and compile. Then add it to
   `Colour`.
2. Remove the `else` arm from the point `match`. The compiler says
   `point( any, any )` is not handled. Why can it not name one particular
   point, the way it named `spades`?
