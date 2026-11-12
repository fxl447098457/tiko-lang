# User-Defined Types and Layout

Part I worked with values one at a time: a number, a string, an array of numbers. Real data comes in
groups — a point has an x and a y, a reading has a station and a temperature — and a program that
keeps the parts in separate variables keeps them in step by hand, which means sometimes out of step.

A `type` puts the parts under one name. This chapter covers what that gives you, and then what it
costs in memory, because a type is also a decision about where bytes go. That second half is what
lets tiko talk to file formats, network protocols and C libraries without translation.

Chapter 12 turns these types into objects with methods. Everything here still applies then; it is
the foundation, not a beginner's version.

## Grouping values

```tiko
{{#include ../examples/ch10/pointrect.tiko}}
```

```text
{{#include ../examples/ch10/pointrect.out}}
```

A `type` lists its fields, each with a name and a type. Fields are reached with a dot, and a type
can contain another type, so `r.topLeft.x` reads the way the data is shaped.

A field may carry an initialiser — `size as Point = ( 10, 20 )` — and every variable of the type
starts with it. Fields without one start at zero, or empty for a string, exactly as variables do. A
value in parentheses, `( 640, 480 )`, fills a type's fields in declaration order.

**Parentheses, not braces.** Braces are how an *array* is filled (Chapter 8), and a type is not an
array:

```tiko
{{#include ../examples/ch10/bracesudt.tiko}}
```

```
bracesudt.tiko(9,20): error TKO0845: 'bad' is not an array, so it cannot take a '{ ... }' initializer
     |
   9 | dim as Point bad = { 3, 4 }         '' refused
     |                    ^
```

fbc refuses it in the same place, with its error 63. Braces are for arrays, parentheses for types.

```admonish note
`name` is a reserved word — the `name` statement renames a file — so it cannot name a variable or
a procedure. A **field** may still be called `name`, and `b.name` reads it: a field's name is only
read after `.` or `->`. Appendix A lists the reserved words and the few that cannot name a field.
```

## A type is a value

```tiko
{{#include ../examples/ch10/copying.tiko}}
```

```text
{{#include ../examples/ch10/copying.out}}
```

Assigning one variable of a type to another copies **every field**, including the text: changing
`b.owner` afterwards leaves `a.owner` alone. The two are independent values, the way two `int32`s
are, and nothing is shared.

Comparison is a different matter:

```tiko
{{#include ../examples/ch10/noequal.tiko}}
```

```text
noequal.tiko(8,6): error TKO0720: no operator = compares this type
     |
   8 | if a = b then print "equal"     '' refused: what would equal mean?
     |      ^
```

The compiler will not guess what equality means for your type — whether two accounts with the same
owner are equal, or only ones with the same balance too. Chapter 13 shows how to say.

## Passing and returning

Chapter 7's table said that a type you define is passed by reference when no keyword is given. Here
is the measurement:

```tiko
{{#include ../examples/ch10/passing.tiko}}
```

```text
{{#include ../examples/ch10/passing.out}}
```

With no keyword, the procedure wrote straight into the caller's `Point`. With `byval` it worked on
a copy. A function can return a type, and `Shifted` returns its modified copy while the original
stays put.

The rule from Chapter 7 holds with more force here, because a type can be large: **write `byref`
or `byval` on every parameter**. `byref ... as const` is the right shape for a type you only read —
no copy, and the compiler stops you writing to it.

## Where the bytes go

```tiko
{{#include ../examples/ch10/layout.tiko}}
```

```text
{{#include ../examples/ch10/layout.out}}
```

`sizeof` is a type's size in bytes, and `offsetof( T, field )` is where a field starts. Read the
first three lines together.

`Loose` holds 6 bytes of data and takes 12. Each field is placed at a multiple of its own size, so
the `int32` after a one-byte field starts at offset 4, leaving three unused bytes — and the whole
type is rounded up to a multiple of its largest field so that an array of them keeps every element
aligned. That padding is not waste for its own sake: the processor reads aligned values in one step
and misaligned ones in two, or not at all.

`Ordered` has the same fields, largest first, and takes 8. **Ordering fields from largest to
smallest is the cheapest optimisation in this book** — no code changes, and every array of the type
gets smaller. Exercise 2 puts a number on it.

`field = 1` turns alignment off: `Packed` is 6 bytes with no gaps. Reach for it when the layout is
dictated from outside — a file format, a network header, a C struct declared with packing — and not
otherwise, because the misaligned reads it creates are slower.

```admonish danger title="Pitfall"
**`field =` packs the inside of a type, not the outside.** `Packed` has no gaps between its own
fields, but put it inside `Holder` and it still starts at offset 4, with three bytes of padding in
front of it — because `Holder` aligns its members normally.

When a whole structure must match a byte-exact format, **every type in it needs its own
`field = 1`**. `PackedHolder` has one, and its `p` lands at offset 1. Missing one level is the
classic way to produce a header that is right in isolation and wrong in the file.
```

### Seeing the layout

The compiler will print the layout it chose. From the directory holding the listing:

```bash
tiko --dump-udt layout.tiko
```

```text
loose size 12 align 4
  loose off a 0
  loose off b 4
  loose off c 8
ordered size 8 align 4
  ordered off b 0
  ordered off a 4
  ordered off c 5
packed size 6 align 4
  packed off a 0
  packed off b 1
  packed off c 5
holder size 12 align 4
  holder off tag 0
  holder off p 4
packedholder size 7 align 4
  packedholder off tag 0
  packedholder off p 1
object size 8 align 8
  object off vptr 0
udts: 6
```

Names appear in lower case, because tiko's names are not case-sensitive. The `align` column is the
alignment a type asks for **when it is placed inside another** — which is why `packed` still says 4,
and why the pitfall above happens. `object` is the built-in base type Chapter 14 introduces; it is
listed whether or not you use it.

`--dump-udt` stops after printing, without building anything. This output was captured at the pin
and is identical on every target.

## Several views of the same bytes

```tiko
{{#include ../examples/ch10/unions.tiko}}
```

```text
{{#include ../examples/ch10/unions.out}}
```

A `union` is declared like a type, but its fields all start at offset 0: they are different
interpretations of one block of memory, and the union is as large as its largest field. Writing
`asFloat` and reading `asInt` shows the IEEE 754 bit pattern of 1.0, which is the classic use — and
also the only kind of use where reading a different field than the one last written is meaningful.

An **anonymous union** inside a type gives one slot two meanings. `Value` stores either an `int64`
or a `float64` in the same eight bytes, and the `isFloat` field beside it records which one is
current. That pairing is the whole discipline of a union: **something must say which field is
live**, because the union cannot.

## Fields narrower than a byte

```tiko
{{#include ../examples/ch10/packetheader.tiko}}
```

```text
{{#include ../examples/ch10/packetheader.out}}
```

`version : 4 as uint32` declares a **bitfield**: a field four bits wide, carved out of a `uint32`.
Consecutive bitfields share their containing integer, so four of them describe the first 32 bits of
an IPv4 header in exactly 4 bytes.

Reading the whole word back shows the allocation order: `&h05DC0054` has `version` (4) in the
**lowest** four bits and `length` (1500, `&h5DC`) in the highest sixteen. The first field declared
takes the least significant bits. That is the order the targets in this book use, and the order C
compilers use on them — but it is not the order a network protocol transmits, which is why a real
header parser reads bytes and shifts rather than overlaying a bitfield type on the wire.

`--dump-udt` reports bitfields at the byte offset of their container, so it cannot show bit
positions; the listing measures them by reading the word back.

```admonish danger title="Pitfall"
**A value too large for a bitfield is truncated, silently.** `version` is four bits, so it holds 0
to 15, and assigning 17 stores 17's low four bits — 1. No warning, no runtime error, even under
`-exx`.

Check the range before you store, wherever the value comes from outside.
```

## Naming a type once

```tiko
{{#include ../examples/ch10/withblock.tiko}}
```

```text
{{#include ../examples/ch10/withblock.out}}
```

Inside `with s … end with`, a field written with a leading dot belongs to `s`. It is shorthand for
filling in a type with many fields, and it reads well for exactly that. Inside a long block it
reads less well, because the reader has to remember which variable the dots refer to.

`type Dimensions as Settings` makes a second name for an existing type. It is the same type, not a
new one — a `Dimensions` and a `Settings` can be assigned to each other freely. Aliases are for
giving a type a name that fits the context, or a shorter one, and Chapter 17 relies on them to name
instantiated generics.

## Types that refer to each other

```tiko
{{#include ../examples/ch10/linked.tiko}}
```

```text
{{#include ../examples/ch10/linked.out}}
```

A type can hold a **pointer** to its own kind, which is how linked structures are built. It cannot
hold a value of its own kind — that would be infinitely large — but a pointer is 8 bytes on every
target this book uses, so the compiler needs nothing more. Chapter 11 covers pointers properly; here they are only the arrows
between records.

Two types that point at *each other* are a different problem. Whichever is written first mentions
the other before it is declared, and the compiler refuses that with
`TKO0784: the type 'child' is used above its declaration`. A **forward alias** —
`type ChildFwd as Child` — names the type before it exists, and a pointer to it can be used straight
away.

A forward alias that is never completed is an **opaque type**:

```tiko
{{#include ../examples/ch10/opaque.tiko}}
```

```text
opaque.tiko(5,8): error TKO0810: 'handleimpl' is an incomplete type: nothing declares it, so only a pointer to it may be used here
     |
   5 | dim as Handle whole                '' a value is not: how big is it?
     |        ^
```

That refusal is the feature. A library can hand out `Handle ptr` values while keeping the contents
of `HandleImpl` to itself, and callers cannot depend on what they cannot see. Chapter 29 meets the
same pattern from C's side.

## Arrays of records

```tiko
{{#include ../examples/ch10/udtarray.tiko}}
```

```text
{{#include ../examples/ch10/udtarray.out}}
```

An array of a type works like any array, and Chapter 8's advice carries over: index when the
position matters, `for each byref` when it does not. For records, `byref` is more than a style
choice, because the alternative copies every field — text included — on every pass.

`MakeReading` builds one record per call, which keeps each line of setup readable. Chapter 12 turns
that function into a **constructor**, which is where it belongs.

```admonish note
**A record that holds text is not built with `type( ... )`.** `log_( 2 ) = type( "south", 18.0 )`
over a `Reading` holding a `ustring` is refused — `TKO0929: type( ... ) cannot build a 'reading'` —
because only a constructor can fill a var-len string. Build such records through a function like
`MakeReading`, or — from Chapter 12 — with a constructor, which `type( ... )` then calls.
```

## What it costs

- **A type costs exactly its `sizeof`.** There is no hidden header and no per-object allocation
  until Chapter 12 adds virtual methods, and even then it is one pointer.
- **Padding is real memory.** Ordering fields largest first is free and can save a third.
- **`field = 1` trades speed for exactness.** Use it where a format demands it, nowhere else.
- **Assignment copies everything**, and a `ustring` field is a separate allocation copied each
  time. Pass large types `byref`.
- **A union costs its largest member**, and the field that says which member is live.

## Summary

- `type` groups named fields; a field may have an initialiser, and may itself be a type.
  `( a, b )` fills fields in order. **Braces are for arrays** — `{ a, b }` on a type is `TKO0845`
- **Assignment copies the whole value**, text included. **`=` does not compare types** —
  `TKO0720` — until Chapter 13 defines it.
- **With no keyword, a type is passed `byref`.** `byval` copies; a function may return a type.
- `sizeof` and `offsetof` measure layout. Fields align to their own size, and the type rounds up to
  its largest field — **order fields largest first**.
- `field = n` caps alignment — **for the inside of that type only**; nested types need their own.
- `tiko --dump-udt file.tiko` prints the layout the compiler chose.
- A `union` overlays its fields at offset 0; something beside it must record which one is live.
- **Bitfields** pack narrow fields into an integer, first field in the lowest bits, and **truncate
  an oversized value silently**.
- `with` shortens repeated access; `type A as B` is an alias for the same type.
- A type may point at itself; **types that point at each other need a forward alias**, and an
  alias never completed is an opaque type usable only through a pointer.
- Arrays of types: index for position, `for each` otherwise — **`for each byref` for records**, which
  the by-value form would copy field by field.
- **`type( ... )` cannot build a record holding text** (`TKO0929`); build it through a function or a
  constructor.

## Exercises

1. Declare a 16-byte record header — magic, version, flags, length, checksum — that must match a
   published binary format exactly, and have the program verify every offset against the spec
   instead of trusting it. {solution="ex10-01"}
2. Take a type with six fields of mixed sizes declared carelessly, reorder them largest first, and
   print both sizes and what a million of each would cost. {solution="ex10-02"}
3. Put a `field = 1` type inside an ordinary one and print the offset of the inner type. Then fix
   the outer type so the whole thing has no padding. How many `field =` did it take?
4. Write a `union` holding a `float64` and an array of eight `uint8`, store −0.0 and 0.0, and print
   the bytes of each. Which byte differs, and why does `=` on the two floats still say they are
   equal?
5. Build a three-element linked list of `Node`s and write a procedure that prints it given only the
   first node's address. What should the procedure do if it is handed `0`?
