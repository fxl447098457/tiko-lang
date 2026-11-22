[Home](Home) › **Literals**

# Literals

Non-variable compile-time string, numeric values and boolean values.

 Literals are numbers, strings of characters or boolean truths specified directly in the source code. Literal values may be used by assigning them to a variable or constant, passing them to a procedure, or using them in an expression.

 Numeric literals come in two forms - integer and floating-point.

Integer Literals

*Decimal*
 Decimal digits ( `0 1 2 3 4 5 6 7 8 9` ).
 *Note: to get negative values, a "`-`" sign ([`Operator - (Negate)`](Operator-Negate)) can be placed before a numeric literal*

```freebasic
Dim x As Integer = 123456

Dim b As Byte = -128
```

 *Hexadecimal*
 "`&H`", followed by hexadecimal digits ( `0 1 2 3 4 5 6 7 8 9 A B C D E F` ).

```freebasic
Dim x As Integer = &h1E240

Dim b As Byte = &H80
```

 *Octal*
 "`&O`" (or "`&`"), followed by octal digits ( `0 1 2 3 4 5 6 7` )

```freebasic
Dim x As Integer = &O361100

Dim b As Byte = &O200
```

 *Binary*
 "`&B`", followed by binary digits ( `0 1` )

```freebasic
Dim x As Integer = &B11110001001000000

Dim b As Byte = &B10000000
```

Integer size suffixes

If an integer literal suffix is not given, the number field size required to hold the literal is automatically calculated. Specifying a size suffix guarantees that the compiler will consider a number as a specific integer size.

 Integer literals ending with:

- "`%`", are considered as signed 32/64 (depending on platform) bit integers. ([`Integer`](Integer))
- "`L`", "`&`", are considered as signed 32 bit long integers. ([`Long`](Long))
- "`U`", are considered as unsigned 32/64 (depending on platform) bit integers. ([`UInteger`](Uinteger))
- "`UL`", are considered as unsigned 32 bit integers. ([`ULong`](Ulong))
- "`LL`", are considered as signed 64 bit integers. ([`LongInt`](Longint))
- "`ULL`", are considered as unsigned 64 bit integers. ([`ULongInt`](Ulongint))

 **tiko:** a literal too big for 64 bits needs no suffix: it is 128-bit by itself. A decimal literal is [`Int128`](Category-Fixed-Width-Types#128-bit-integers) up to 2^127 - 1 and `UInt128` above; a `&H`, `&O` or `&B` literal past 64 bits is `Int128`. A literal with an `LL` or `ULL` suffix stays 64 bits, and past that it is truncated with warning `TKO0205`.

Negative (-) and positive (+) signs that prefix a numeric literal, are not part of the numeric literal. expressions (like "`-1L`") are parsed as the negate operator applied to the value represented by the positive literal ("`1L`"), which may involve implicit type conversions. Same behavior when an explicit "`+`" sign precedes the integer literal.

 The prefixes, suffixes, and hexadecimal letter digits are all case-insensitive.

```freebasic
Dim a As Long = 123L

Dim b As UInteger = &h1234u

Dim c As LongInt = 76543LL

Dim d As ULongInt = &b1010101ULL
```

Floating Point Literals

Floating point numbers are specified in decimal digits, may be positive or negative, have a fractional portion, and optionally an exponent. The format of a floating point literal is as follows (without space or parenthesis added):

 `number[.[fraction]][(D|E)[+|-][exponent]][suffix]`
 *or*
 `.fraction[(D|E)[+|-][exponent]][suffix]`

 By default, floating point numbers that do not have either an exponent or a suffix are considered as a double precision floating point value, except in the *[-lang qb](Compiler-Option-Lang)* dialect, where numbers of 7 digits or fewer are considered to be single precision.

```freebasic
Dim a As Double = 123.456

Dim b As Double = -123.0
```

 The letter "`D`" or "`E`", placed after the number/fraction part, allows the number to be given an exponent. The exponent may be specified as either positive or negative with a plus ("`+`") or minus ("`-`") sign. Exponents that do not have a sign are positive.  
 An exponent value is not required after the letter (or even after the sign), so the letter can be used on its own just to specify the type. "`D`" specifies a double-precision floating-point number. "`E`" specifies a floating-point number using the default precision. When the letter is used on its own in combination with a suffix (see below) the type denoted by the suffix overrules the type specified by the letter.

```freebasic
Dim a As Double = -123.0d

Dim b As Double = -123e

Dim c As Double = 743.1e+13

Dim d As Double = 743.1D-13

Dim e As Double = 743.1E13

Dim f As Single = 743D!
```

 A suffix of "`!`" or "`F`" on a number specifies a single precision (32 bit total) floating point value. A suffix of "`#`" or "`D`" specifies a double precision float.  
 Note that the letter suffixes and exponent specifiers are all case-insensitive.

```freebasic
Dim a As Single = 3.1!

Dim b As Single = -123.456e-7f

Dim c As Double = 0#

Dim d As Double = 3.141592653589e3#
```

String Literals

String literals are a sequence of characters contained between two double quotes. The sequence of characters escaped or non-escaped.

 Double quotes can be specified in the string literal by using two double quotes together.

```freebasic
Print "Hello World!"

Print "That's right!"

Print "See the ""word"" contained in double quotes."
```

 String literals can contain escape sequences if the string literal is prefixed by the [`! Operator`](Operator-Escaped-String-Literal) (Escaped String Literal). See [Escape Sequences](Escape-Sequences) for a list of accepted escape sequences.  
 `Print !"Hello\nWorld!"`

 By default, string literals are non-escaped unless `Option Escape` was used in the source in which case all string literals following are by default escaped.

 A string may be explicitly specified as non-escaped when prefixed by the [`$ Operator`](Operator-Escaped-String-Literal) (Non-Escaped String Literal).  
 `Print $"C:\temp"`

 **tiko:** a string that spans several lines is written as a [block string](Category-Block-Strings): `"""` at the end of a line opens it, and a line starting with `"""` closes it.

 Besides ASCII files with Unicode escape sequences (`\u`), FreeBASIC can parse UTF-8, UTF-16LE, UTF-16BE, UTF-32LE and UTF-32BE source files as long as they were saved with Byte Order Mark (BOM), allowing unicode characters directly in the string literal.
 **Note:** The most reliable cross-platform code is obtained by encoding without BOM in ASCII/UTF-8 characters.

 String literals in an ASCII file are treated as [`ZString`](Zstring), while string literals in a Unicode file are treated as [`WString`](Wstring) (regardless of the string literal's value).

Boolean Literals

The boolean type has two values, represented by literals [`True`](True) and [`False`](False).

```freebasic
Dim a As Boolean = False

Dim b As Boolean = True
```

See also

- [`TypeOf`](Typeof)
- [`#define`](Define)
- [`Const`](Const)
- [`Standard Data Types`](Standard-Data-Types)
- [`Table with variable types overview, limits and suffixes`](Standard-Data-Type-Limits)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
