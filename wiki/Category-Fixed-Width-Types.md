[Home](Home) › [All Categories](Categories) › **Fixed-Width Types**

# Fixed-Width Types

## The names

Ten type names that say their width, each the same type as another built-in name:

| tiko | Same type as | Bytes | Range |
|---|---|---|---|
| `int8` | [Byte](Byte) | 1 | -128 to 127 |
| `uint8` | [UByte](Ubyte) | 1 | 0 to 255 |
| `int16` | [Short](Short) | 2 | -32768 to 32767 |
| `uint16` | [UShort](Ushort) | 2 | 0 to 65535 |
| `int32` | [Long](Long) | 4 | -2147483648 to 2147483647 |
| `uint32` | [ULong](Ulong) | 4 | 0 to 4294967295 |
| `int64` | [LongInt](Longint) | 8 | -9223372036854775808 to 9223372036854775807 |
| `uint64` | [ULongInt](Ulongint) | 8 | 0 to 18446744073709551615 |
| `float32` | [Single](Single) | 4 | IEEE 754 single precision |
| `float64` | [Double](Double) | 8 | IEEE 754 double precision |

The sizes are the same on every target.

## Why they exist

The names in the second column don't say how wide they are, and the same names mean different widths in C. `long` is 32 bits in tiko on every target, but in C it is 32 bits on Windows and 64 on Linux and macOS. The names above follow Go, Nim and C's `<stdint.h>` (`int32_t`), so the width is in the name.

```freebasic
dim as uint8 red = 255
dim as int64 total = 9223372036854775807
dim as float32 ratio = 1 / 3
print red; total; ratio
```

## They are the same types

Each name is a typedef, not a new type: `int32` *is* `long`. Values mix freely with no conversion, a procedure that takes `long` accepts an `int32`, and an overload on `int64` is the overload on `longint`. The names leave no trace in the ABI, so a procedure's linker symbol is the one it gets with the names they stand for:

```freebasic
namespace N
    sub F( byval a as int8, byval b as uint16, byval c as int32, _
           byval d as uint64, byval e as float32, byval g as float64 )
    end sub
end namespace
'' _ZN1N1FEatiyfd under tiko
```

## A program's own declaration wins

The names are not keywords. tiko declares them for every program, but anything the program declares with the same name at module level replaces tiko's, with no diagnostic. Some headers declare these names themselves: `win/basetsd.bi` declares `type INT32 as long`. Such code compiles:

```freebasic
type INT32 as long                      '' the same type: nothing changes
type uint8 as integer                   '' a different type: uint8 is now 8 bytes
dim shared float32 as long = 5          '' not a type: float32 is now this variable
function uint16( byval x as long ) as long
    return x + 1
end function
print sizeof( INT32 ); sizeof( uint8 ); float32; uint16( 6 )
```

This prints `4 8 5 7`. Because tiko ignores case, `INT32` and `int32` are the same name.

A name used *above* the program's declaration is fine when the declaration gives it the type tiko does, as `win/basetsd.bi` does: `dim as int32 n` and then `#include "windows.bi"` compiles, and so does a module whose interface uses `int32`, imported by a program that includes `windows.bi`, and so does an alias such as `type base_id as int32` used above it. Above a declaration of a *different* type, such as a `type uint8 as integer` written below a `dim as uint8`, the use is error `TKO0784` (`TKO0811` through an alias): the code above it would otherwise change meaning.

**The program's declaration replaces the name throughout the program**, not just in its own file. `jpeglib.bi` declares `type INT32 as clong`, which is 8 bytes on Linux x86-64. A Linux program that includes it therefore gets an 8-byte `int32`.

## What is not included

- **`integer` and `uinteger`** have no fixed-width name: they are the width of a pointer on the target.
- **`boolean`** stays as it is, and there is no `bool`. tiko ignores case, so `bool` would be `BOOL`, which `win/windef.bi` declares as a 4-byte `long`.
- **Pointers** are spelled with `ptr`: `int32 ptr`, `any ptr`.
- **Strings** keep their own names: `string`, `zstring`, `wstring` and [`ustring`](Category-UString).

---

[Home](Home) · [Keyword Index](Keyword-Index)
