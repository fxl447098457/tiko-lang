# Literals

A literal is a value written straight into the source. Integers can be
written in four bases, floating-point numbers with a point or an exponent,
and a suffix can pin a literal to a particular type.

```tiko
{{#include ../../examples/primitives/literals.tiko}}
```

**Output**

```text
{{#include ../../examples/primitives/literals.out}}
```

| Prefix | Base | Example |
|---|---|---|
| none | 10 | `255` |
| `&h` | 16 | `&hFF` |
| `&o` | 8 | `&o377` |
| `&b` | 2 | `&b11111111` |

A literal with a point or an exponent (`1.5`, `2.5e3`, `.25`) is floating
point. tiko has no digit separator: `1_000_000` is error `TKO0420: expected
the end of the statement`.

A plain whole-number literal is an `integer`, which is 8 bytes on the 64-bit
targets; a plain floating-point literal is a `float64`. The suffixes change
that:

| Suffix | Type |
|---|---|
| `L` | `int32` |
| `LL` | `int64` |
| `U` | `uinteger` |
| `UL` | `uint32` |
| `ULL` | `uint64` |
| `F` | `float32` |
| `D` | `float64` |

A whole-number literal too big for 64 bits needs no suffix: it is 128-bit by
itself. A decimal one is `int128` up to 2^127 - 1 and `uint128` above; a
`&h`, `&o` or `&b` one past 64 bits is `int128`. A suffix does not widen:
`LL` and `ULL` stay 64 bits, and a literal too big for them draws warning
`TKO0205` and a wrong value.

[Literal types](../types/literals.md) shows how to see the type a literal
gets, including one case that surprises people.

`true` and `false` are values of type `boolean`. Text goes in double quotes;
with a `!` in front, backslash escapes such as `\t` are read, so the last line
prints a real tab. [Strings](../strings/index.md) has the full set.

### Activities

1. Print `&h7FFFFFFF` and `&b10000000` and check the values by hand.
2. Print `cbool( &o17 = &b1111 )` and work out why the answer is what it is.
