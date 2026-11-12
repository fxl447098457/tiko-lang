[Home](Home) › [String Functions](Category-String-Functions) › **Asc**

# Asc

Returns the character code at a position in a string.

## Syntax

```freebasic
Declare Function Asc ( ByRef str As Const String, ByVal position As Integer = 1 ) As ULong
Declare Function Asc ( ByVal str As Const ZString Ptr, ByVal position As Integer = 1 ) As ULong
Declare Function Asc ( ByVal str As Const WString Ptr, ByVal position As Integer = 1 ) As ULong
```

## Parameters

- `str`
- `position`

## Description

If `str` is a [`String`](String) or a [`ZString`](Zstring), the [`UByte`](Ubyte) value at that `position` is returned. This will be a 7-bit ASCII code, or even a 8-bit character value from some code-page, depending on the string data stored in `str`.

 If `str` is a [`WString`](Wstring), the [`UShort`](Ushort) (Windows) or [`ULong`](Ulong) (Linux and macOS) value at that `position` is returned. This will be a 16bit value on Windows (WStrings use UTF16 there), or a 32bit value on Linux and macOS (WStrings use UTF32 there).

 The function returns zero (`0`) if the string is a zero length string, `position` is less than one (`1`), or `position` is greater than the number of characters in `str`.

 [`Chr`](Chr) performs the opposite function for ASCII strings, while [`WChr`](Wchr) is the opposite for Unicode strings, returning a string containing the character represented by the code passed as an argument.

## Return Value

The raw character value stored at `position` in `str`.  
 If both `str` and `position` can be evaluated at compile time (like `Asc("a")` or `Asc(chr(97))` or `Asc("abc", 2)` ...), the value is returned in a [`UInteger`](Uinteger) result, otherwise in a [`ULong`](Ulong) result.

## Remarks

### Usage

`result = Asc( str [, position ] )`

### Platform Differences

- DOS does not support the wide-character string version of `Asc`.

### Differences from QB

- The optional `position` argument is new to FreeBASIC.
- QB does not support the wide-character string version of `Asc`

### See also

- [`Chr`](Chr)
- [`Str`](Str)
- [`Val`](Val)

## Examples

```freebasic
Print "the ascii code of 'a' is:"; Asc("a")

Print "the ascii code of 'b' is:"; Asc("abc", 2)
```

will produce the output:

```freebasic
the ascii code of 'a' is: 97
the ascii code of 'b' is: 98
```

Unicode example (Note to documentation editors: don't put inside %%(qbasic) markers or the Russian text will disappear!)

```freebasic
dim a as wstring * 12

a = "Привет, мир"

print "the Unicode of the second char of " & a & " is: " & asc(a, 2)
```

---

**Category:** [String Functions](Category-String-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
