# Literal Types

A literal has a type too, chosen from how it is written. Usually you never
notice, because a literal converts to whatever type it is assigned to. It
matters when the literal is used on its own: in arithmetic, as an argument to
an overloaded procedure, or as the value a `var` copies.

```tiko
{{#include ../../examples/types/literals.tiko}}
```

**Output**

```text
{{#include ../../examples/types/literals.out}}
```

`TypeOf_` has one overload per type. The compiler calls the overload whose
parameter type matches the argument exactly, so the text it returns names the
literal's type.

A plain whole number is an `integer`, as wide as an address: 8 bytes on both
64-bit targets. A number with a point or an exponent is a `float64`. A suffix
asks for a different type; the [Literals](../primitives/literals.md) page
lists them.

```admonish danger title="Pitfall"
**A decimal literal from 2147483648 to 4294967295 is unsigned.** It does not
fit in 32 signed bits, but does fit in 32 unsigned ones, so it gets the type
`uinteger`. Arithmetic with an unsigned operand is unsigned, so
`3000000000 - 3000000001` wraps round to 18446744073709551615 instead of
giving -1. A suffix fixes it: with `LL` on both literals the subtraction is
done in `int64`. Literals above 4294967295 are `integer` again, and the
same happens one size up: 9223372036854775808 to 18446744073709551615 is
`uinteger`.
```

Past 64 bits a literal is 128-bit, with no suffix, and the rule repeats a
third time: a decimal literal is `int128` up to 2^127 - 1 and `uint128` above.

### Activities

1. Add an `int16` overload and call it with `cshort( 1 )`. Which overload
   does a plain `1` pick now?
2. Print `TypeOf_( 2147483647 )` and `TypeOf_( 2147483648 )`.
