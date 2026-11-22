[Home](Home) › [String Functions](Category-String-Functions) › **Bin**

# Bin

Returns a number as binary text.

## Syntax

```freebasic
Declare Function Bin ( ByVal number As UByte ) As String
Declare Function Bin ( ByVal number As UShort ) As String
Declare Function Bin ( ByVal number As ULong ) As String
Declare Function Bin ( ByVal number As ULongInt ) As String
Declare Function Bin ( ByVal number As Const Any Ptr ) As String
Declare Function Bin ( ByVal number As UByte, ByVal digits As Long ) As String
Declare Function Bin ( ByVal number As UShort, ByVal digits As Long ) As String
Declare Function Bin ( ByVal number As ULong, ByVal digits As Long ) As String
```

## Parameters

- `number`
- `digits`

## Description

Returns a string representing the unsigned binary value of the integer `number`. Binary digits range from 0 to 1.

 If you specify `digits` > 0, the result string will be exactly that length. It will be truncated or padded with zeros on the left, if necessary.

 The length of the string will not go longer than the maximum number of digits required for the type of `number` (32 for a [`Long`](Long), 64 for a `LongInt)`.

 If you want to do the opposite, i.e. convert an binary string back into a number, the easiest way to do it is to prepend the string with `"&B"`, and convert it to an integer type, using a function like [`CInt`](Cint), similarly to a normal numeric string. E.g. `CInt("&B101")`

## Return Value

A string containing the unsigned binary representation of `number`.

 **tiko:** `Bin` also takes an [`Int128` or `UInt128`](Category-Fixed-Width-Types#128-bit-integers), at full width: up to 128 digits.

## Remarks

### Usage

`result = Bin[$]( number [, digits ] )`

### Dialect Differences

- Not available in the *[-lang qb](Compiler-Option-Lang)* dialect unless referenced with the alias `__Bin`.
- The string type suffix "$" is ignored in the *[-lang fblite](Compiler-Option-Lang)* dialect, always warn.
- The string type suffix "$" is ignored in the *[-lang fb](Compiler-Option-Lang)* dialect, always warn.

### Differences from QB

- New to FreeBASIC

### See also

- [`Oct`](Oct)
- [`Hex`](Hex)
- [`ValInt`](Valint)
- [`ValLng`](Vallng)

## Examples

```freebasic
Print Bin(54321)

Print Bin(54321, 5)

Print Bin(54321, 20)
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
