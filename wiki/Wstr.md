[Home](Home) › [Converting Data Types](Category-Converting-Data-Types) › **WStr**

# WStr

Returns a number as a wide string.

## Syntax

```freebasic
Declare Function WStr ( ByVal n As Byte ) As WString
Declare Function WStr ( ByVal n As UByte ) As WString
Declare Function WStr ( ByVal n As Short ) As WString
Declare Function WStr ( ByVal n As UShort ) As WString
Declare Function WStr ( ByVal n As Long ) As WString
Declare Function WStr ( ByVal n As ULong ) As WString
Declare Function WStr ( ByVal n As LongInt ) As WString
Declare Function WStr ( ByVal n As ULongInt ) As WString
```

## Parameters

- `number`
- `string`

## Description

`WStr` converts numeric variables to their wide-character string representation. It is the wide-character equivalent to [`Str`](Str).

 `WStr` also converts ASCII character strings to Unicode character strings. If a wide-character string is given, that string is returned unmodified.

## Return Value

Returns the wide-character representation of the numeric or string expression.

 **tiko:** `WStr` also takes an [`Int128` or `UInt128`](Category-Fixed-Width-Types#128-bit-integers), at full width.

## Remarks

### Usage

```freebasic
result = WStr( number )

or

result = WStr( string )
```

### Platform Differences

- DOS does not support `WStr`.

### Dialect Differences

- Not available in the *[-lang qb](Compiler-Option-Lang)* dialect unless referenced with the alias `__Wstr`.

### Differences from QB

- New to FreeBASIC

### See also

- [`Str`](Str)
- [`WString`](Wstring)

## Examples

```freebasic
#if defined( __FB_WIN32__ )

#include "windows.bi"

#endif

Dim zs As ZString * 20

Dim ws As WString * 20

zs = "Hello World"

ws = WStr(zs)

#if defined( __FB_WIN32__ )

MessageBox(null, ws, WStr("Unicode 'Hello World'"), MB_OK Or MB_ICONINFORMATION)

#else

Print ws

Print WStr("Unicode 'Hello World'")

#endif
```

---

**Category:** [Converting Data Types](Category-Converting-Data-Types)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
