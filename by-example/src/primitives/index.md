# Primitives

tiko's built-in scalar types put their size in their name: `int8` to `int64`
for signed integers, `uint8` to `uint64` for unsigned ones, `float32` and
`float64` for floating point. `boolean` holds `true` or `false`, and
`ustring` holds text.

```tiko
{{#include ../../examples/primitives/scalars.tiko}}
```

**Output**

```text
{{#include ../../examples/primitives/scalars.out}}
```

`sizeof` gives the size of a value's type in bytes. Each width is the same on
every target, so an `int32` is four bytes on Windows, on Linux and on macOS alike.

| Type | Bytes | Holds |
|---|---|---|
| `int8` `int16` `int32` `int64` | 1 2 4 8 | signed whole numbers |
| `uint8` `uint16` `uint32` `uint64` | 1 2 4 8 | whole numbers from 0 up |
| `float32` `float64` | 4 8 | floating point, about 7 and 16 digits |
| `boolean` | 1 | `true` or `false` |
| `ustring` | | text of any length |

Two more integer types, `integer` and `uinteger`, are as wide as an address
on the target; [Sizes](../types/sizes.md) shows them. A `ustring` is text, not
a scalar: `len( label )` counts its characters, and
[Strings](../strings/index.md) covers it properly.

The pages in this section cover how to write values
([literals](literals.md)), what you can do with them
([operators](operators.md)), and two ways to group them:
[tuples](tuples.md) and fixed-size [arrays](arrays.md).

### Activities

1. Add an `int16` set to -32768 and a `uint16` set to 65535 to the table.
2. Add a row for `integer` and compare its size with `int64`.
