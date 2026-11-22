[Home](Home) › [Converting Data Types](Category-Converting-Data-Types) › **Str**

# Str

Returns a number or boolean as text.

## Syntax

```freebasic
Declare Function Str ( ByVal n As Byte ) As String
Declare Function Str ( ByVal n As UByte ) As String
Declare Function Str ( ByVal n As Short ) As String
Declare Function Str ( ByVal n As UShort ) As String
Declare Function Str ( ByVal n As Long ) As String
Declare Function Str ( ByVal n As ULong ) As String
Declare Function Str ( ByVal n As LongInt ) As String
Declare Function Str ( ByVal n As ULongInt ) As String
```

## Parameters

- `number`
- `string`

## Description

`Str` converts numeric variables to their string representation. Used this way it is the [`String`](String) equivalent to [`WStr`](Wstr) applied to numeric variables, and the opposite of the [`Val`](Val) function, which converts a string into a number.

 `Str` converts boolean variables to their string representation "false" / "true".

 `Str` also converts Unicode character strings to ASCII character strings. Used this way it does the opposite of [`WStr`](Wstr). If an ASCII character string is given, that string is returned unmodified.

 **tiko:** `Str` also takes an [`Int128` or `UInt128`](Category-Fixed-Width-Types#128-bit-integers), at full width: `Str( cast( UInt128, -1 ) )` is `"340282366920938463463374607431768211455"`.

## Remarks

### Usage

```freebasic
result = Str[$]( number )

or

result = Str( string )
```

### Dialect Differences

- In the *[-lang qb](Compiler-Option-Lang)* dialect, `Str` will left pad a positive number with a space.
  The string type suffix "$" is required in the *[-lang qb](Compiler-Option-Lang)* dialect.  
  The string type suffix "$" is optional in the *[-lang fblite](Compiler-Option-Lang)* dialect.  
  The string type suffix "$" is ignored in the *[-lang fb](Compiler-Option-Lang)* dialect, warn only with the *[-w suffix](Compiler-Option-W)* compile option (or *[-w pedantic](Compiler-Option-W)* compile option).

### Platform Differences

- DOS version/target of FreeBASIC does not support the wide-character string version of `Str`.

### Differences from QB

- QB does not support the wide-character string version of `Str`.

### See also

- [`Val`](Val)
- [`CBool`](Cbool)
- [`Chr`](Chr)
- [`Asc`](Asc)

## Examples

```freebasic
Dim a As Integer

Dim b As String

a = 8421

b = Str(a)

Print a, b
```

---

**Category:** [Converting Data Types](Category-Converting-Data-Types)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
