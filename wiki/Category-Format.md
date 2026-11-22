[Home](Home) › [All Categories](Categories) › **Format**

# Format

```freebasic
#import "std/strings"

dim as ustring who = "Quinn"
print strings.Format( "Hello, {}!", who )              ' Hello, Quinn!
print strings.Format( "{1} before {0}", "b", "a" )      ' a before b
print strings.Format( "[{:>8}]", 42 )                   ' [      42]
print strings.Format( "{:#010x}", 255 )                 ' 0x000000ff
print strings.Format( "{:*^9}", "hi" )                  ' ***hi****
print strings.Format( "{:.3f} {:e}", 3.14159, 1234.5 )  ' 3.142 1.234500e+03
```

`strings.Format` builds text from a **format string** and a list of values: each `{}` in the format string is replaced by the next value, formatted by the **spec** written inside the braces. The format strings, the spec language and the output are C++20's `std::format`, so a format string written for one works in the other.

A format string written as a literal is **checked when the program is compiled**: a `{}` with no value to fill it, or `{:x}` given a string, is a compile error with a caret on the character at fault.

## Why It Exists

`print` and `&` join values with each value's default text, and nothing else. A width, an alignment, a fixed number of decimals, hexadecimal, a sign -- each is a separate function call, and the layout of a line disappears into them:

```freebasic
dim as int32 n = 7
dim as float64 secs = 1.2345
print "item " & right( "    " & n, 4 ) & ": " & str( cint( secs * 100 ) / 100 ) & "s"
print strings.Format( "item {:>4}: {:.2f}s", n, secs )
```

The second line says what the output looks like. `Format` also takes a **typed** list of any length, so every value is checked, and it never reads a value as a type it is not.

## The Format String

```text
replacement-field  ::=  '{' [arg-id] [':' format-spec] '}'
format-spec        ::=  [[fill] align] [sign] ['#'] ['0'] [width] ['.' precision] [type]
width, precision   ::=  digits | '{' [arg-id] '}'
```

**`{}` takes the next value, `{n}` value `n`**, counting from 0. A format string uses one style or the other: `"{} {0}"` is an error. A value may be used more than once with `{n}`, and values left over are not an error.

**`{{` and `}}`** are literal braces.

**The spec**, after `:`, is these fields, each optional, in this order:

| Field | Meaning |
|---|---|
| fill, align | `<` left, `>` right, `^` centre, padded with the fill character (a space by default) up to the width. Centring puts the odd character on the right. Numbers align right by default, everything else left. |
| sign | `+` a sign on every number, `-` only on negatives (the default), a space for a space before positives. |
| `#` | The alternate form: `0x`, `0b` or `0` before a hexadecimal, binary or octal number; a decimal point always written for a float. |
| `0` | Pad a number with zeros after its sign and prefix: `{:+06}` is `+00042`. Ignored when an alignment is written. |
| width | The minimum width, in code points. |
| precision | For a float, the digits after the point (`f`, `e`, `a`) or the significant digits (`g`, and no type). For a string, the most code points taken from it. |
| type | How the value is presented -- see below. |

A width or precision can come from a value: `{:{}}` takes the width from the next value, `{:.{}f}` the precision, and `{0:{1}}` names them. That value must be an integer.

## Values And Their Types

| Value | Types | Default |
|---|---|---|
| integers of every width, `int128` and `uint128` included, enums | `d` decimal, `b` `B` binary, `o` octal, `x` `X` hexadecimal, `c` the character with that code | `d` |
| `single`, `double` | `f` `F` fixed, `e` `E` exponent, `g` `G` general, `a` `A` hexadecimal float | the shortest text that reads back as the same value |
| `boolean` | `s`, or any integer type for `1` / `0` | `true` / `false` |
| `ustring`, `string`, `wstring`, literals, `zstring ptr` | `s`, `?` (quoted, with escapes) | `s` |
| any pointer | `p` `P`: `0x` and hexadecimal | `p` |

`inf` and `nan` print as `inf`, `-inf` and `nan` (upper case under `F`, `E`, `G` and `A`). A `zstring ptr` is formatted as its text, and as its address under `p`; a null one is an error as text.

```freebasic
#import "std/strings"

print strings.Format( "{:b} {:o} {:X} {:c}", 10, 8, 255, 65 )   ' 1010 10 FF A
print strings.Format( "{} {:.1f} {:g}", 0.1, 2.25, 1e20 )       ' 0.1 2.2 1e+20
print strings.Format( "{} {:d}", true, true )                    ' true 1
print strings.Format( "{:?}", !"tab\there" )                    ' "tab\there"
print strings.Format( "{:.3}", "abcdef" )                        ' abc
```

`{:.1f}` of 2.25 is `2.2`: rounding is to the nearest value the double can hold, ties to even, as C++ does.

## Errors

A format string that does not parse, uses a value that is not there, or gives a value a type it cannot take is a **bug in the program**.

**Written as a literal, the compiler refuses it.** Each refusal has its own id, the caret on the character at fault:

```text
app.tiko(6,30): error TKO0851: format string: no argument 1 (1 given)
     |
   6 | print strings.Format( "{} of {}", 3 )
     |                              ^
app.tiko(7,26): error TKO0854: format string: 'x' is no presentation type for text
     |
   7 | print strings.Format( "{:x}", who )
     |                          ^
```

| Id | Refusal |
|---|---|
| `TKO0847` | a `{` with no `}` |
| `TKO0848` | a `}` that closes nothing and is not `}}` |
| `TKO0849` | an argument id that is not a number, or has a leading zero |
| `TKO0850` | `{}` and `{n}` in one format string |
| `TKO0851` | an argument id past the last value |
| `TKO0852` | a spec that does not parse |
| `TKO0853` | `{` or `}` as the fill character |
| `TKO0854` | a type the value cannot take |
| `TKO0855` | a sign, `#` or `0` the value or type cannot take |
| `TKO0856` | a precision on a value that takes none |
| `TKO0857` | a `{}` width or precision whose value is not an integer |
| `TKO0858` | `L` -- locale formatting is not supported |

The check needs the format string's text and the values' types, so it does not apply to a format string held in a variable, to a list passed as an array, or to a value that is itself a `strings.FormatArg`. An escaped literal (`!"..."`) is checked like any other, the caret on the escape that produced the character at fault -- except one whose escapes make bytes that are not UTF-8, which is left for run time.

**Otherwise `Format` refuses it when it runs**: the reason and the offset go to stderr, then run-time error 1 stops the program. An `on error` handler can still take it.

```text
strings.Format: no argument 2 (2 given) at offset 12 in "x={} y={} z={}"
```

Some refusals depend on a **value** and can only be found then: `{:c}` of a number that is no Unicode code point, a width or precision that is negative, a null `zstring ptr` formatted as text.

### Format Strings That Are Data

A format string read from a file, a translation or a user setting is data, and a bad one is not a bug. `TryFormat` returns the text or the reason, and never stops the program:

```freebasic
#import "std/strings"
#import "std/outcome"

dim as ustring template = "{} of {}"
dim as outcome.Result( of ustring, strings.FormatError ) r = strings.TryFormat( template, 3 )
if r.IsOk( ) then
    print r.Value( )
else
    print "refused at offset "; r.Failure( ).offset; ": "; r.Failure( ).message
end if
```

`FormatError` is `code`, a `strings.FormatErrorCode` (`FE_UNMATCHED_OPEN`, `FE_MISSING_ARG`, `FE_BAD_TYPE`, ...), `offset`, from 0 in UTF-16 units of the format string, and `message`. `TryFormat` takes a plain `ustring`, so even a literal passed to it is left for run time.

## The Other Entry Points

```freebasic
#import "std/strings"

dim as ustring line_ = "total: "
strings.FormatTo( line_, "{:>6.2f}", 12.5 )          ' appends: "total:  12.50"
print line_
print strings.FormattedSize( "{:>10}", "x" )         ' 10
```

- **`FormatTo( dest, fmt, ... )`** appends to `dest`.
- **`FormattedSize( fmt, ... )`** is the length the result would have, in UTF-16 units.

Both are checked at compile time like `Format`.

### A List Built At Run Time

`Format` takes its values as a [typed variadic](Category-Typed-Variadics) of `strings.FormatArg`: each value is converted by one of `FormatArg`'s constructors. A list whose length is known only at run time is an array of `FormatArg`, passed whole:

```freebasic
#import "std/strings"

dim as strings.FormatArg parts( 0 to 2 ) = { strings.FormatArg( "x" ), strings.FormatArg( 1 ), strings.FormatArg( 2.5 ) }
print strings.Format( "{}-{}-{}", parts( ) )     ' x-1-2.5
```

### Your Own Wrapper

A procedure of your own that takes a `strings.FormatString` and then `args() as const strings.FormatArg ...` is checked at compile time exactly like `Format`, and passes its list on whole:

```freebasic
#import "std/strings"

sub LogF( byref fmt as const strings.FormatString, args() as const strings.FormatArg ... )
    print "[log] "; strings.Format( fmt, args( ) )
end sub

LogF( "{} items in {:.1f}s", 12, 0.25 )
```

## Your Own Types

**A type that converts to text** -- with `operator cast( ) as string` or `as ustring` -- is formatted as that text, and takes the string spec:

```freebasic
#import "std/strings"

type Vec2
    as long x, y
    declare operator cast( ) as string
end type
operator Vec2.cast( ) as string
    return "(" & x & ", " & y & ")"
end operator

dim as Vec2 pt = ( 3, 4 )
print strings.Format( "[{:>10}]", pt )    ' [    (3, 4)]
```

A type that converts only to a **number** reaches every numeric constructor of `FormatArg` equally, and is `TKO0660`. Convert it yourself -- `cast( double, t )` -- or make it `Formattable`.

**A type that extends `strings.Formattable`** formats itself, with a spec language of its own:

```freebasic
#import "std/strings"

type Money extends strings.Formattable
    as longint cents
    declare function FormatWith( byref spec as const ustring, _
        byref ctx as strings.FormatContext ) as ustring override
end type

function Money.FormatWith( byref spec as const ustring, _
    byref ctx as strings.FormatContext ) as ustring
    dim as ustring t = "$" & ( cents \ 100 ) & "." & right( "0" & ( cents mod 100 ), 2 )
    if spec = "raw" then return str( cents )
    return strings.FormatStandard( t, spec, ctx )
end function

dim as Money m
m.cents = 12345
print strings.Format( "[{}] [{:>12}] [{:raw}]", m, m, m )    ' [$123.45] [     $123.45] [12345]
```

`FormatWith` receives the spec after the `:` -- `""` for `{}` -- with any `{}` width or precision already replaced by its value, and returns the field's text. `strings.FormatStandard` applies the standard string spec (fill, alignment, width, precision) to text, for a type that wants only that. A spec the type refuses is reported with `ctx.SetError( "why" )`, which `TryFormat` returns as `FE_CUSTOM` and `Format` treats as any other refused format string. The compiler checks the `{}` inside such a spec but leaves the rest to the type.

## Differences From C++

- **Width counts code points.** C++ counts an East Asian wide character as two columns; this library carries no width table, so every code point is one, and a surrogate pair is one.
- **`L` is refused.** There is no locale-dependent formatting.
- **`c` of an integer is a Unicode code point** -- `{:c}` of 233 is `é` -- where C++ takes it as a `char`.
- **The result is always a `ustring`**, and the format string is one.

## See Also

- [Typed Variadics](Category-Typed-Variadics), how `Format` takes its values
- [String Library](Category-String-Library), the rest of `std/strings`
- [Result](Category-Result), what `TryFormat` returns
