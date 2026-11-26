# Control Flow, Scope and defer

Programs choose and repeat. tiko's constructs for both will look familiar, and the reason they
get a chapter is the third thing here: `defer`, which arranges for something to happen on the way
out of a block — and which has one rule that catches everybody once.

## Choosing

```tiko
{{#include ../examples/ch06/branching.tiko}}
```

```text
{{#include ../examples/ch06/branching.out}}
```

`if` / `elseif` / `else` / `end if` needs no parentheses around the condition. A complete `if` can
sit on one line, and then it takes no `end if` — useful for a guard, and confusing if you try to
extend it later, so keep those short.

`select case` compares one value against many possibilities, and the cases are more expressive
than a C `switch`:

| Case | Matches |
|---|---|
| `case 5` | one value |
| `case 0, 1, 2` | any in a list |
| `case 60 to 89` | a range, ends included |
| `case is < 0` | an open comparison |
| `case else` | everything remaining |

Cases are tested in order and the first match wins; there is no fall-through and nothing to
`break` out of.

```admonish note
`select case as const` compiles to a jump table, which is faster for a dense set of integer
cases — and it accepts only constant values, so `case is < 0` inside one is `TKO0419`.
```

```admonish note
**`select case true` runs the first case whose test is true.** `case ( n mod 3 ) = 0` works
there: the comparison's −1 or 0 is converted to the `boolean` subject, as every case value is.
When each branch asks a different question, though, `if` / `elseif` is usually the clearer shape.
```

## Matching

`select case` has one weakness that grows with a program: nothing checks that every case is
handled. Add a member to an enum and every `select case` that forgot it still compiles. `match`
compares one value against **patterns**, and it does not compile until every value the subject
can have is handled:

```tiko
{{#include ../examples/ch06/matching.tiko}}
```

```text
{{#include ../examples/ch06/matching.out}}
```

`match` has two forms. As a **statement** its arms are `case` lines, and each arm's body can be
as long as you like. Used as a **value** — after `=`, `return`, `print`, as an argument — its arms
are `pattern => value`, one line each, and the whole `match` is the value of the arm that matched.
The first matching arm wins and there is no fall-through, as in `select case`.

Remove `case Green` from `Drive` and the program no longer compiles:

```tiko
{{#include ../examples/ch06/unhandled.tiko}}
```

```text
error TKO1250: 'match' is not exhaustive: green is not handled
```

The check knows the members of a named enum, the two values of a `boolean`, and every combination
of a tuple's elements — the `( isAdmin, isOwner )` match above lists all four cases between its
three arms. For an integer, a float or a string no list of values can be complete, so a `match` on
one needs an `else` arm, as the `code` match has.

Patterns can also take a value apart:

```tiko
{{#include ../examples/ch06/patterns.tiko}}
```

```text
{{#include ../examples/ch06/patterns.out}}
```

| Pattern | Matches | Binds |
|---|---|---|
| `5`, `"quit"`, `Light.Red` | that value | — |
| `0, 1, 2` | any in a list (top level only) | — |
| `60 to 89` | a range, ends included | — |
| `is < 0` | an open comparison | — |
| `any` / `else` | anything; `else` only as the last arm | — |
| `( p, q )` | a tuple, element by element | what the elements bind |
| `Point( x, 0 )` | a `Point`, field by field in declaration order | `x` |
| `c as Circle` | a `Shape ptr` that points at a `Circle` | `c`, a `Circle ptr` |
| `starts "load " file` | a string beginning with `"load "` | `file`, the rest |

**A bare name means two different things.** At the top of a pattern it is a *value*, exactly as
in `select case`: `case Red` compares. Inside a tuple or a UDT pattern it *binds*: `Point( x, y )`
makes `x` and `y` names for the fields, usable in the arm's body. To compare a field against a
named constant there, qualify the name or use a guard.

**A guard** — `pattern if condition` — lets an arm match only when its condition also holds, and
a failed guard moves on to the next arm. Because a guard can fail, a guarded arm does not count
towards the exhaustiveness check: `Point( x, y ) if x = y` is followed by an unguarded
`Point( x, y )` that catches the rest.

```admonish note
`match` works on a **copy** of its subject, taken once before the first arm is tried, and the names
a pattern binds refer to that copy. Used as a value, the copy is taken before the statement that
contains the `match` runs — which only matters if the subject is a call with side effects.
```

```admonish note
`match` is a contextual keyword: it is one only when a subject follows it, the next line is an arm
and an `end match` closes it. A variable or a procedure called `match` keeps working.
```

## Repeating

```tiko
{{#include ../examples/ch06/loops.tiko}}
```

```text
{{#include ../examples/ch06/loops.out}}
```

`for … next` counts, and `step` sets the stride — negative to count down. Declaring the counter in
the loop, `for i as int32 = 1 to 3`, keeps it out of the surrounding scope, which is what you want
almost always.

`do … loop` carries its condition at either end, with either sense:

- `do while c … loop` — test first, may run zero times
- `do until c … loop` — the same, inverted
- `do … loop while c` and `do … loop until c` — test last, so the body always runs once

`exit for` and `exit do` leave a loop; `continue for` and `continue do` skip to the next pass.
Naming the loop kind makes nested loops readable.

An older form, `while … wend`, also exists and behaves as `do while … loop`. Existing code uses it;
new code has no reason to.

## Blocks that exist to bound a lifetime

```tiko
{{#include ../examples/ch06/scopeblock.tiko}}
```

```text
{{#include ../examples/ch06/scopeblock.out}}
```

`scope … end scope` introduces a block with no condition and no loop — just a boundary. Variables
declared inside it end there. It is how you keep a temporary from leaking into the rest of a long
procedure, and, as the next section shows, how you control exactly when a `defer` fires.

## defer

`defer` takes a statement and runs it when the enclosing block is left — however it is left:

```tiko
{{#include ../examples/ch06/deferorder.tiko}}
```

```text
{{#include ../examples/ch06/deferorder.out}}
```

Two things to read off that output. Deferred statements run in **reverse order**, so resources are
released in the opposite order to the one they were acquired in — B before A. And they run on
**every** path out, including the early `exit sub`, which is the entire point: the cleanup is
written next to the thing it cleans up, and cannot be skipped by a return you add later.

That makes `defer` the answer to the oldest bug in resource handling — the path that forgot to
close something:

```tiko
open "data.txt" for input as #1
defer close #1
```

Now the rule that catches everyone.

````admonish danger title="Pitfall"
**`defer` belongs to the nearest enclosing block, not to the procedure.** An `if`, a loop body and
a `scope` are all blocks.

```tiko
{{#include ../examples/ch06/defertrap.tiko}}
```

```text
{{#include ../examples/ch06/defertrap.out}}
```

Read the first half: the release happens at `end if`, while the procedure is still running. A
guard written as *acquire inside an `if`, then defer* releases the resource immediately and leaves
the rest of the procedure using something already closed — and nothing in the code looks wrong.

The fix is to leave early instead of nesting: test the failure case, `exit sub`, and put the
acquire-and-defer pair in the procedure's own body. Exercise 2 shows both side by side.

In a loop body the same rule is exactly what you want — the deferred statement runs at the end of
**each** pass, as the second half of the output shows.
````

`defer` needs a block to be on the way out of, so it cannot appear at module level:

```tiko
{{#include ../examples/ch06/modulelevel.tiko}}
```

```text
modulelevel.tiko(3,1): error TKO0814: 'defer' is not allowed at module level; put it
in a procedure or a block
```

## Labels and goto

tiko has `goto` and line labels. They exist for two reasons: compatibility with older code, and
`on error goto`, which Chapter 18 covers.

Nothing in this book uses `goto` for control flow. Every loop construct above, plus `exit` and
`continue`, covers what it was for — and a `goto` that jumps across a `defer` is refused
(`TKO0827`), because the compiler cannot say what should have run on the way.

## Summary

- `if` / `elseif` / `else`; a one-line `if` takes no `end if`.
- `select case` matches values, lists, ranges and open comparisons, first match wins, no
  fall-through. `as const` builds a jump table and takes only constants.
- `match` tests a value against patterns, as a statement (`case` arms) or as a value
  (`pattern => value` arms). It refuses to compile until every case is handled, takes tuples,
  UDTs, class types and string prefixes apart, and binds what it takes out.
- **A comparison yields an integer, not a `boolean`** — wrap with `cbool` before comparing one
  against `true`.
- `for … next` with `step`; `do … loop` with the test at either end; `exit` and `continue`.
- `scope … end scope` bounds a lifetime deliberately.
- **`defer` runs on the way out of its block, in reverse order, on every path** — including the
  end of each loop pass, and including an `if` you wrapped it in.

## Exercises

1. Write FizzBuzz for 1 to 15. Which reads better here, `if`/`elseif` or `select case`, and why?
   {solution="ex06-01"}
2. Write a procedure that acquires something inside an `if` and defers its release, and a second
   that guards first and defers in the procedure body. Print from both and compare the order.
   {solution="ex06-02"}
3. Put a `defer` in a loop body that prints the loop counter. Before running it, predict how many
   times it fires and with which values.
4. Rewrite a `do … loop until` as a `do while … loop` that behaves identically, including when the
   condition is already true at the start. Which needed more care?
5. Add a fourth member, `Flashing`, to the `Light` enum in `matching.tiko` and compile. Fix the
   error the compiler reports, then write the same `Drive` with `select case` and add `Flashing`
   there instead. What does the compiler say this time?
