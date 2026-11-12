# Unions

A `union` is declared like a record, but all its fields start at the same
address. They are different ways of reading one block of memory, and the
union is as large as its largest field.

```tiko
{{#include ../../examples/custom-types/unions.tiko}}
```

**Output**

```text
{{#include ../../examples/custom-types/unions.out}}
```

`Bits32` is four bytes, whichever field you use. Writing `asFloat` and
reading `asInt` shows the bit pattern of the `float32` value 1.0, and the
`bytes` array shows the same four bytes one at a time. The lowest address
holds the lowest byte, because every target is little-endian.

A `union ... end union` without a name, inside a `type`, gives one slot of the
record two meanings: `Value` stores either an `int64` or a `float64` in the
same eight bytes, which is why `offsetof` reports both `i` and `f` at offset
8. The `kind` field beside it says which one is current, and `Show` reads it
before touching the union.

```admonish danger title="Pitfall"
**A union does not know which field was written last.** Reading `v.f` after
writing `v.i` compiles and runs, and gives you the integer's bits read as a
float. Keep a field beside the union that records which member is live, and
check it every time.
```

### Activities

1. Store -1.0 in `u.asFloat` and work out which bit changed from 1.0.
2. Add a `KindBool` member and a `boolean` field to `Value`'s union, and
   extend `Show` to print it.
