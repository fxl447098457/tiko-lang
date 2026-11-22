[Home](Home) › [String Functions](Category-String-Functions) › **WBin**

# WBin

Returns a number as binary wide-string text.

## Syntax

```freebasic
Declare Function WBin ( ByVal number As UByte ) As WString
Declare Function WBin ( ByVal number As UShort ) As WString
Declare Function WBin ( ByVal number As ULong ) As WString
Declare Function WBin ( ByVal number As ULongInt ) As WString
Declare Function WBin ( ByVal number As Const Any Ptr ) As WString
Declare Function WBin ( ByVal number As UByte, ByVal digits As Long ) As WString
Declare Function WBin ( ByVal number As UShort, ByVal digits As Long ) As WString
Declare Function WBin ( ByVal number As ULong, ByVal digits As Long ) As WString
```

## Parameters

- `number`
- `digits`

## Description

Returns a [`WString`](Wstring) (Unicode) representing the binary value of the integer `number`. Binary digits range from `0` to `1`.

 If you specify `digits` > `0`, the result wstring will be exactly that length. It will be truncated or padded with zeros on the left, if necessary.

 The length of the returned string will not be longer than the maximum number of digits required for the type of `expression` (32 for a [`Long`](Long), 64 for floating point or [`LongInt`](Longint))

## Return Value

Returns a binary [`WString`](Wstring) representation of `number`, truncated or padded with zeros (`"0"`) to fit the number of digits, if specified.

 **tiko:** `WBin` also takes an [`Int128` or `UInt128`](Category-Fixed-Width-Types#128-bit-integers), at full width: up to 128 digits.

## Remarks

### Usage

`result = WBin( number [, digits] )`

### Platform Differences

- Unicode strings are not supported in the DOS port of FreeBASIC.

### Dialect Differences

- Not available in the *[-lang qb](Compiler-Option-Lang)* dialect unless referenced with the alias `__Wbin`.

### Differences from QB

- New to FreeBASIC

### See also

- [`Bin`](Bin)
- [`WHex`](Whex)
- [`WOct`](Woct)

## Examples

```freebasic
Print WBin(54321)

Print WBin(54321, 5)

Print WBin(54321, 20)
```

 will produce the output:

```freebasic
1101010000110001
10001
00001101010000110001
```

---

**Category:** [String Functions](Category-String-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
