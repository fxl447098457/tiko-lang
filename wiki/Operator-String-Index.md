[Home](Home) › [Operators](Category-Operators) › **Operator [] (String Index)**

# Operator [] (String Index)

Returns a reference to the numeric value of a character in a string

## Syntax

```freebasic
Declare Operator [] ( ByRef lhs As String, ByRef rhs As Integer ) ByRef As UByte
Declare Operator [] ( ByRef lhs As ZString, ByRef rhs As Integer ) ByRef As UByte
Declare Operator [] ( ByRef lhs As WString, ByRef rhs As Integer ) ByRef As T
```

## Parameters

- `lhs`
- `rhs`
- `T`

## Description

This operator returns a reference to the numeric value of a specific character in a string:

a [`UByte`](Ubyte) (containing the ASCII value of the character).

a numeric type depending on platform, for example [`UShort`](Ushort) for Windows or [`ULong`](Ulong) for Linux and macOS (containing the numeric value of the character).

This operator must not be used in case of empty string because reference is undefined (inducing runtime error).  
 Otherwise, the user must ensure that the index does not exceed the range "\[0, `Len(lhs) - 1`\]". Outside this range, results are undefined.

 Unlike 'return by value' (where only a copy is returned), 'return by reference' allows you to also modify the referenced variable.  
 'Return by reference' is implemented under the hood as a pointer implicitly dereferenced:

**-** In case of a [`String`](String) or a [`ZString`](Zstring) `'s'`:

`s[n]` is equivalent to `*CPtr(Ubyte Ptr, StrPtr(s) + n)`

**-** In case of a [`WString`](Wstring) `'s'`:

`s[n]` is equivalent to `*CPtr(T Ptr, StrPtr(s) + n)`

**Note:** The fact that this operator returns a reference greatly differentiates it from `Asc( str [, position ] )` which allows to return the numeric representation of a character, but not to modify it.

## Remarks

### Usage

```freebasic
result = lhs [ rhs ]

or

lhs [ rhs ] = value
```

### Differences from QB

- New to FreeBASIC

### See also

- [String Operators](String-Operators)

## Examples

```freebasic
Dim a As String = "Hello, world!"

Dim i As Integer

For i = 0 To Len(a) - 1

    Print Chr(a[i]) & " ";

Next i

Print

Print

For i = 1 To 4

    a[i] = a[i] - 32  ' converting lowercase alphabetic characters to uppercase

Next i

For i = 7 To 11

    a[i] = a[i] - 32  ' converting lowercase alphabetic characters to uppercase

Next i

Print a
```

 Will print:

```freebasic
H e l l o ,   w o r l d !

HELLO, WORLD!

```

---

**Category:** [Operators](Category-Operators)  
**Kind:** operator

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
