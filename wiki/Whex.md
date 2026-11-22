[Home](Home) › [String Functions](Category-String-Functions) › **WHex**

# WHex

Returns a number as hexadecimal wide-string text.

## Syntax

```freebasic
Declare Function WHex ( ByVal number As UByte ) As WString
Declare Function WHex ( ByVal number As UShort ) As WString
Declare Function WHex ( ByVal number As ULong ) As WString
Declare Function WHex ( ByVal number As ULongInt ) As WString
Declare Function WHex ( ByVal number As Const Any Ptr ) As WString
Declare Function WHex ( ByVal number As UByte, ByVal digits As Long ) As WString
Declare Function WHex ( ByVal number As UShort, ByVal digits As Long ) As WString
Declare Function WHex ( ByVal number As ULong, ByVal digits As Long ) As WString
```

## Parameters

- `number`
- `digits`

## Description

Hexadecimal digits range from `0`-`9`, or `A`-`F`.

 If you specify `digits` > `0`, the resulting [`WString`](Wstring) will be exactly that length. It will be truncated or padded with zeros on the left, if necessary.

 The length of the wstring will not go longer than the maximum number of digits required for the type of `expression` (8 for a [`Long`](Long), 16 for floating point or [`LongInt`](Longint))

## Return Value

Returns a hexadecimal [`WString`](Wstring) representation of `number`, truncated or padded with zeros (`"0"`) to fit the number of digits, if specified.

 **tiko:** `WHex` also takes an [`Int128` or `UInt128`](Category-Fixed-Width-Types#128-bit-integers), at full width: up to 32 digits.

## Remarks

### Usage

`result = WHex( number [, digits ] )`

### Platform Differences

- Unicode strings are not supported in the DOS port of FreeBASIC.

### Dialect Differences

- Not available in the *[-lang qb](Compiler-Option-Lang)* dialect unless referenced with the alias `__Whex`.

### Differences from QB

- New to FreeBASIC.

### See also

- [`Hex`](Hex)
- [`WBin`](Wbin)
- [`WOct`](Woct)

## Examples

```freebasic
Print Hex(54321)

Print Hex(54321, 2)

Print Hex(54321, 5)
```

 will produce the output:

```freebasic
D431
31
0D431
```

---

**Category:** [String Functions](Category-String-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
