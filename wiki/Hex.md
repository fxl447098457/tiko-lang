[Home](Home) › [String Functions](Category-String-Functions) › **Hex**

# Hex

Returns a number as hexadecimal text.

## Syntax

```freebasic
Declare Function Hex ( ByVal number As UByte ) As String
Declare Function Hex ( ByVal number As UShort ) As String
Declare Function Hex ( ByVal number As ULong ) As String
Declare Function Hex ( ByVal number As ULongInt ) As String
Declare Function Hex ( ByVal number As Const Any Ptr ) As String
Declare Function Hex ( ByVal number As UByte, ByVal digits As Long ) As String
Declare Function Hex ( ByVal number As UShort, ByVal digits As Long ) As String
Declare Function Hex ( ByVal number As ULong, ByVal digits As Long ) As String
```

## Parameters

- `number`
- `digits`

## Description

Returns the unsigned hexadecimal string representation of the integer `number`. Hexadecimal digits range from 0-9, or A-F.

 If you specify `digits` > 0, the result string will be exactly that length. It will be truncated or padded with zeros on the left, if necessary.

 The length of the string will not go longer than the maximum number of digits required for the type of `number` (8 for a [`Long`](Long), 16 for a `LongInt)`.

 If you want to do the opposite, i.e. convert a hexadecimal string back into a number, the easiest way to do it is to prepend the string with `"&H"`, and convert it to an integer type, using a function like [`CInt`](Cint), similarly to a normal numeric string. E.g. `CInt("&HFF")`

## Return Value

A [String](String) containing the unsigned hexadecimal representation of `number`.

 **tiko:** `Hex` also takes an [`Int128` or `UInt128`](Category-Fixed-Width-Types#128-bit-integers), at full width: up to 32 digits, so `Hex( cast( Int128, -1 ) )` is 32 `F`s.

## Remarks

### Usage

`result = Hex[$]( number [, digits ] )`

### Dialect Differences

- The string type suffix "$" is required in the *[-lang qb](Compiler-Option-Lang)* dialect.
  The string type suffix "$" is optional in the *[-lang fblite](Compiler-Option-Lang)* dialect.  
  The string type suffix "$" is ignored in the *[-lang fb](Compiler-Option-Lang)* dialect, warn only with the *[-w suffix](Compiler-Option-W)* compile option (or *[-w pedantic](Compiler-Option-W)* compile option).

### Differences from QB

- In QBASIC, there was no way to specify the number of digits returned.
- The size of the string returned was limited to 32 bits, or 8 hexadecimal digits.

### See also

- [`Bin`](Bin)
- [`Oct`](Oct)
- [`ValInt`](Valint)
- [`ValLng`](Vallng)

## Examples

```freebasic
'54321 is D431 in hex

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
