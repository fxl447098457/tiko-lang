[Home](Home) › [String Functions](Category-String-Functions) › **WOct**

# WOct

Returns a number as octal wide-string text.

## Syntax

```freebasic
Declare Function WOct ( ByVal number As UByte ) As WString
Declare Function WOct ( ByVal number As UShort ) As WString
Declare Function WOct ( ByVal number As ULong ) As WString
Declare Function WOct ( ByVal number As ULongInt ) As WString
Declare Function WOct ( ByVal number As Const Any Ptr ) As WString
Declare Function WOct ( ByVal number As UByte, ByVal digits As Long ) As WString
Declare Function WOct ( ByVal number As UShort, ByVal digits As Long ) As WString
Declare Function WOct ( ByVal number As ULong, ByVal digits As Long ) As WString
```

## Parameters

- `number`
- `digits`

## Description

Returns the octal [`WString`](Wstring) (Unicode) representation of `number`. Octal digits range from `0` to `7`.

 If you specify `digits` > `0`, the result string will be exactly that length. It will be truncated or padded with zeros on the left, if necessary.

 The length of the returned string will not be longer than the maximum number of digits required for the type of `number` (3 characters for [`Byte`](Byte), 6 for [`Short`](Short), 11 for [`Long`](Long), and 22 for [`LongInt`](Longint))

## Return Value

The Unicode octal representation of the number, truncated or padded with zeros (`"0"`) to fit the number of digits, if specified.

 **tiko:** `WOct` also takes an [`Int128` or `UInt128`](Category-Fixed-Width-Types#128-bit-integers), at full width: up to 43 digits.

## Remarks

### Usage

`result = WOct( number [, digits ] )`

### Dialect Differences

- Not available in the *[-lang qb](Compiler-Option-Lang)* dialect unless referenced with the alias `__Woct`.

### Platform Differences

- Unicode strings are not supported in the DOS port of FreeBASIC.

### Differences from QB

- In QBASIC Unicode was not supported.

### See also

- [`WBin`](Wbin)
- [`WHex`](Whex)

## Examples

```freebasic
Print WOct(54321)

Print WOct(54321, 4)

Print WOct(54321, 8)
```

 will produce the output:

```freebasic
152061
2061
00152061
```

---

**Category:** [String Functions](Category-String-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
