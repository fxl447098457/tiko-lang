[Home](Home) › [String Functions](Category-String-Functions) › **Oct**

# Oct

Returns a number as octal text.

## Syntax

```freebasic
Declare Function Oct ( ByVal number As UByte ) As String
Declare Function Oct ( ByVal number As UShort ) As String
Declare Function Oct ( ByVal number As ULong ) As String
Declare Function Oct ( ByVal number As ULongInt ) As String
Declare Function Oct ( ByVal number As Const Any Ptr ) As String
Declare Function Oct ( ByVal number As UByte, ByVal digits As Long ) As String
Declare Function Oct ( ByVal number As UShort, ByVal digits As Long ) As String
Declare Function Oct ( ByVal number As ULong, ByVal digits As Long ) As String
```

## Parameters

- `number`
- `digits`

## Description

Returns the unsigned octal string representation of `number`. Octal digits range from 0 to 7.

 If you specify `digits` > 0, the result string will be exactly that length. It will be truncated or padded with zeros on the left, if necessary.

 The length of the returned string will not be longer than the maximum number of digits required for the type of `number` (3 characters for [`Byte`](Byte), 6 for [`Short`](Short), 11 for [`Long`](Long), and 22 for [`LongInt`](Longint))

 If you want to do the opposite, i.e. convert an octal string back into a number, the easiest way to do it is to prepend the string with `"&O"`, and convert it to an integer type, using a function like [`CInt`](Cint), similarly to a normal numeric string. E.g. `CInt("&O77")`

## Return Value

A string containing the unsigned octal representation of `number`.

 **tiko:** `Oct` also takes an [`Int128` or `UInt128`](Category-Fixed-Width-Types#128-bit-integers), at full width: up to 43 digits.

## Remarks

### Usage

`result = Oct[$]( number [, digits ] )`

### Dialect Differences

- The string type suffix "$" is required in the *[-lang qb](Compiler-Option-Lang)* dialect.
  The string type suffix "$" is optional in the *[-lang fblite](Compiler-Option-Lang)* dialect.  
  The string type suffix "$" is ignored in the *[-lang fb](Compiler-Option-Lang)* dialect, warn only with the *[-w suffix](Compiler-Option-W)* compile option (or *[-w pedantic](Compiler-Option-W)* compile option).

### Differences from QB

- In QBASIC, there was no way to specify the number of digits returned.
- The size of the string returned was limited to 32 bits, or 11 octal digits.

### See also

- [`Bin`](Bin)
- [`Hex`](Hex)
- [`ValInt`](Valint)
- [`ValLng`](Vallng)

## Examples

```freebasic
Print Oct(54321)

Print Oct(54321, 4)

Print Oct(54321, 8)
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
