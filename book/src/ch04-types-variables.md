# Types, Variables and Constants

Every value in a tiko program has a type, fixed when the program is compiled and never changing
afterwards. That is what lets the compiler catch a whole class of mistake before you run anything,
and it is why a tiko program runs at the speed it does: the machine code knows exactly what it is
working with.

This chapter is the vocabulary the rest of the book assumes — how to write values, how to name
them, and what happens when one type becomes another.

## Writing the program

A few rules apply everywhere, and they are quickly stated.

**Case does not matter to the compiler.** `Count`, `count` and `COUNT` are one name. It matters
very much to readers, so the book follows one convention throughout: keywords lowercase, and types
and procedures in PascalCase.

**Comments start with `''` and run to the end of the line.** A block comment is `/'` … `'/`, and
those nest.

**One statement per line**, with no terminator to forget. A line can be continued with a trailing
`_`, and two short statements can share a line with `:` between them — the book uses that only for
setup lines that read better together.

## Writing values

```tiko
{{#include ../examples/ch04/literals.tiko}}
```

```text
{{#include ../examples/ch04/literals.out}}
```

Numbers can be written in hexadecimal, octal or binary with `&h`, `&o` and `&b`. A suffix pins a
literal's type where it matters — `1LL` is 64-bit.

Strings come in three spellings, and the difference is what a backslash means:

| Written | `\t` is |
|---|---|
| `"plain"` | two characters, a backslash and a `t` |
| `!"escaped"` | a tab |
| `$"raw"` | two characters, explicitly |

`true` and `false` are ordinary values of type `boolean`.

## Numbers that state their width

tiko's numeric types say how big they are:

```tiko
{{#include ../examples/ch04/widths.tiko}}
```

```text
{{#include ../examples/ch04/widths.out}}
```

`int8`, `int16`, `int32`, `int64` and the `uint` forms cover the integers; `float32` and `float64`
cover the rest. **Use these.** A reader never has to ask how wide `int32` is, and the answer is
the same on every target.

`int128` and `uint128` go past 64 bits, for values a 64-bit integer cannot hold: the product of
two `int64`s, a 128-bit hash or identifier. They are C's `__int128` and `unsigned __int128`, and
every integer operator, `print`, `str` and `hex` works on them at full width:

```tiko
{{#include ../examples/ch04/wide.tiko}}
```

```text
{{#include ../examples/ch04/wide.out}}
```

The first line is the trap. `big * big` is an `int64` expression, so it wraps *before* it is
stored; storing it in an `int128` widens the wrong answer. Make one operand 128-bit first and the
whole product is. A literal too large for 64 bits needs no suffix: it is 128-bit already.

Two types deliberately have no fixed-width name:

- **`integer`** is pointer-sized — 8 bytes on the 64-bit targets. Reach for it when a value has to
  match the machine's word, such as an index into something that could be huge.
- **`uinteger`** is its unsigned twin.

You will also meet the older names in existing code: `byte`, `short`, `long`, `longint`, `single`,
`double`, and their unsigned forms. They are what the fixed-width names are made of — `int32` *is*
`long` — so the two mix freely. `int128` and `uint128` are the exception: no older name exists for
them, so they are types of tiko's own.

```admonish danger title="Pitfall"
**`long` is 32 bits.** It is the one name most likely to mislead a C or Java programmer, who will
read it as 64. The fixed-width spellings exist partly to make that impossible to get wrong: write
`int64` when you mean 64 bits.
```

The fixed-width names, the 128-bit pair included, are predeclared by the compiler rather than
reserved words, which has a visible consequence:

```tiko
{{#include ../examples/ch04/shadow.tiko}}
```

```text
{{#include ../examples/ch04/shadow.out}}
```

A program can declare a variable called `int32` and it wins inside its scope. That is not an
oversight: existing headers already declare names like `INT32`, and making them keywords would
have broken every one of them.

## Naming values

```tiko
{{#include ../examples/ch04/declare.tiko}}
```

```text
{{#include ../examples/ch04/declare.out}}
```

`dim as T name` declares a variable of a stated type. `var name = value` declares one and takes
the type from the value. The book's rule: **`var` when the type is obvious from the line, `dim as`
when it is not.**

Other forms in that listing:

- `dim as int32 x, y, z` declares several at once.
- `= any` leaves a variable uninitialised, holding whatever was in that memory. It is a
  deliberate, visible choice, not the default.
- `const` names a value that cannot be assigned to. Its type comes from the value unless you state
  one.
- `enum` names a set of related constants; values follow on from the last one given, so `Blue` is
  11.

**Every variable must be declared.** There are no implicit variables, which means a typo is caught
rather than silently becoming a second variable:

```tiko
{{#include ../examples/ch04/implicit.tiko}}
```

```text
implicit.tiko(5,1): error TKO0743: 'totl' is not declared
     |
   5 | totl = total + 1      '' a typo, not a new variable
     | ^
```

```admonish note
A type-suffix sigil does not give a variable a type: `dim count%` is error `TKO0320`. Next to an
explicit type, as in `dim as int32 count%`, the suffix is ignored, with warning `TKO0206`: the
type comes from `as int32`. Write `dim as int32 count`. Chapter 32 covers code that still relies
on suffixes.
```

## One type becoming another

Assigning a value of one numeric type to another converts it, and conversions between integer
types are the obvious ones: the value is kept when it fits and wraps when it does not.

Converting a float to an integer is where tiko surprises people who come from C:

```tiko
{{#include ../examples/ch04/rounding.tiko}}
```

```text
{{#include ../examples/ch04/rounding.out}}
```

```admonish danger title="Pitfall"
**It rounds. C truncates.** `cint( 2.6 )` is 3, not 2 — and a plain assignment into an integer
variable rounds in exactly the same way.

And a half goes to the *even* neighbour: `cint( 2.5 )` is 2 while `cint( 3.5 )` is 4. That is
C's `lrint( )`, not its `round( )`, which takes halves away from zero and gives 3 and 4 — the
answer most people expect.

When you want C's behaviour, say so: **`fix( )` truncates towards zero**. `int( )` is a third
answer again — it rounds towards minus infinity, so it and `fix( )` agree on positive numbers and
differ on negative ones.
```

The `c*` family converts explicitly: `cint`, `clng`, `clngint`, `csng`, `cdbl`, `cbool`, `cbyte`,
`cshort`, and the unsigned forms. `cast( T, value )` converts to any type you name, and `cunsg` /
`csign` reinterpret a value's sign without changing its bits.

## Asking about a type

- **`sizeof( T )`** is the size in bytes, as the listing above used.
- **`len( x )`** is the length of a string, or the size of anything else.
- **`typeof( x )`** is the type of an expression, usable where a type is expected.

`fblimits.bi` names the minimum and maximum of each type, if you would rather not write
`2147483647` and hope.

## Summary

- Types are fixed at compile time; every variable is declared, so a typo is an error.
- Prefer the width-stating names: `int8`…`int64`, `uint8`…`uint64`, `float32`, `float64`.
- `int128` and `uint128` are 128-bit integers, C's `__int128`. Widen an operand *before* the
  arithmetic, or a 64-bit result wraps first.
- `integer` and `uinteger` are pointer-sized and have no fixed-width spelling — that is the reason
  to use them.
- **`long` is 32 bits.** The older names still appear in existing code, and mix freely with the new
  ones.
- The fixed-width names are predeclared, not reserved, so a program may shadow one.
- `var` infers a type from the value; `dim as T` states it; `const` names a value; `enum` names a
  set.
- **Float to integer rounds, half to even** — `fix( )` truncates like C, `int( )` floors.
- Numbers may be written in hex, octal or binary; `!"…"` reads escapes and `$"…"` takes none.

## Exercises

1. Print the largest value each signed integer type can hold, then add one to the `int32` maximum
   and explain what you see. `std/numeric`'s `AddChecked` gives a second opinion.
   {solution="ex04-01"}
2. Build a table comparing `cint`, `int` and `fix` over 2.4, 2.5, 2.6 and their negatives. Which
   pair agrees on positive numbers but not negative ones? {solution="ex04-02"}
3. Declare a variable with `= any`, print it before assigning anything, and run the program twice.
   Is the value the same both times? Should you ever rely on it?
4. `const Pi = 3.14159` — what type does `Pi` get? Use `sizeof( typeof( Pi ) )` to find out, then
   state the type explicitly and compare.
