[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › **Strings**

# Strings

Converts case by locale, translates between code pages, formats sizes and splits fields.

Text in `sys/win` is UTF-16: a `ustring`, a `wstring` or a literal. A `string` here is a buffer
of **bytes** in some 8-bit encoding: the ANSI code page of the machine (Windows-1252 in Western
Europe and the Americas), the OEM code page the console uses (437 or 850), UTF-8, or another code
page you name. The conversion functions move text between the two, and the code page says how
the bytes are to be read.

Code page numbers: 0 (`CP_ACP`) is the ANSI code page, 1 (`CP_OEMCP`) the OEM code page, 65001
(`CP_UTF8`) UTF-8; others are listed on Microsoft Learn under code page identifiers.

## Importing

```freebasic
#import "sys/win"
using win
```

## Example

A console program that upper-cases a Turkish word by the Turkish rules, round-trips text through
UTF-8, formats a file size and splits a line of fields:

```freebasic
#import "sys/win"
using win

print UpperCase( "istanbul", "tr-TR" )        ' İSTANBUL
dim bytes as string = WideToUtf8( "café" )
print len( bytes ); " UTF-8 bytes"            ' 5
print Utf8ToWide( bytes )                      ' café
print FormatByteSize( 1234567 )                ' 1.17 MB
dim fields as ustring = "Smith;John;42"
for i as long = 1 to ParseCount( fields, ";" )
    print i; ": "; ParseStr( fields, i, ";" )
next
```

## Functions

| Function | Does |
| --- | --- |
| [UpperCase](#uppercase) | Returns a string in upper case, by the rules of a locale. |
| [LowerCase](#lowercase) | Returns a string in lower case, by the rules of a locale. |
| [Ucode](#ucode) | Converts bytes in a code page to Unicode. |
| [Acode](#acode) | Converts Unicode to bytes in a code page. |
| [WideToUtf8](#widetoutf8) | Converts Unicode to UTF-8 bytes. |
| [Utf8ToWide](#utf8towide) | Converts UTF-8 bytes to Unicode. |
| [WideToOem](#widetooem) | Converts Unicode to bytes in the OEM code page. |
| [OemToWide](#oemtowide) | Converts bytes in the OEM code page to Unicode. |
| [FormatByteSize](#formatbytesize) | Formats a size in bytes as bytes, KB, MB or GB. |
| [FormatKBSize](#formatkbsize) | Formats a size in bytes as kilobytes. |
| [StrFromTimeInterval](#strfromtimeinterval) | Formats a time in milliseconds as hours, minutes and seconds. |
| [ParseCount](#parsecount) | Counts the delimited fields in a string. |
| [ParseStr](#parsestr) | Returns one delimited field of a string. |

## Reference

### UpperCase

```freebasic
function UpperCase( byval pwszStr as wstring ptr, byval pwszLocaleName as wstring ptr = LOCALE_NAME_USER_DEFAULT, byval dwMapFlags as DWORD = 0 ) as ustring
```

Returns the string in upper case by the casing rules of a locale, using linguistic casing:
`UpperCase( "istanbul", "tr-TR" )` gives `İSTANBUL`, with the dotted capital I of Turkish, where
the user's default locale gives `ISTANBUL` in English. Letters with no single upper-case form
stay: `"straße"` gives `STRAßE`.

| Parameter | Meaning |
| --- | --- |
| `pwszStr` | The text. |
| `pwszLocaleName` | A locale name such as `"tr-TR"` or `"de-DE"`; the user's default locale if omitted. |
| `dwMapFlags` | Extra `LCMAP_*` flags. `LCMAP_UPPERCASE` and `LCMAP_LINGUISTIC_CASING` are always added and `LCMAP_LOWERCASE` removed. |

**Returns** the upper-case text; `""` for `NULL` or an empty string.

**Example**

```freebasic
print UpperCase( "straße istanbul" )   ' STRAßE ISTANBUL
```

Microsoft Learn: [LCMapStringEx](https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-lcmapstringex)

### LowerCase

```freebasic
function LowerCase( byval pwszStr as wstring ptr, byval pwszLocaleName as wstring ptr = LOCALE_NAME_USER_DEFAULT, byval dwMapFlags as DWORD = 0 ) as ustring
```

Returns the string in lower case by the casing rules of a locale, using linguistic casing:
`"ÀÉÎ HELLO"` gives `àéî hello`. The parameters are those of [UpperCase](#uppercase), with
`LCMAP_LOWERCASE` always added and `LCMAP_UPPERCASE` removed.

**Returns** the lower-case text; `""` for `NULL` or an empty string.

**Example**

```freebasic
print LowerCase( "ÀÉÎ HELLO" )   ' àéî hello
```

### Ucode

```freebasic
function Ucode( byref ansiStr as const string, byval nCodePage as long = 0 ) as ustring
```

Reads a byte string in a code page and returns it as Unicode. `chr( &hE9 )` is `é` in the ANSI
code page of a Western machine; `Ucode( chr( &h82 ), 437 )` is `é` too, read as code page 437.

| Parameter | Meaning |
| --- | --- |
| `ansiStr` | The bytes. |
| `nCodePage` | The code page they are in; 0 (the default) for the ANSI code page, `CP_UTF8` for UTF-8. |

**Returns** the text, or `""` when the bytes cannot be converted.

**Example**

```freebasic
print Ucode( chr( &h82 ), 437 )   ' é
```

Microsoft Learn: [MultiByteToWideChar](https://learn.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar)

### Acode

```freebasic
function Acode( byval pwszStr as wstring ptr, byval nCodePage as long = 0 ) as string
```

Converts Unicode text to bytes in a code page. Characters the code page has no byte for are
replaced by its default character, normally `?`. `Acode( "café" )` gives four bytes, the last
`&hE9`, on a Western machine.

| Parameter | Meaning |
| --- | --- |
| `pwszStr` | The text. |
| `nCodePage` | The code page to produce; 0 (the default) for the ANSI code page, `CP_UTF8` for UTF-8. |

**Returns** the bytes, or `""` for `NULL` or when the conversion fails.

**Example**

```freebasic
dim legacy as string = Acode( "café", 1252 )
print len( legacy ); " bytes"   ' 4
```

Microsoft Learn: [WideCharToMultiByte](https://learn.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-widechartomultibyte)

### WideToUtf8

```freebasic
function WideToUtf8( byval pwszStr as wstring ptr ) as string
```

Converts Unicode text to UTF-8 bytes, the same as `Acode( pwszStr, CP_UTF8 )`. `"café"` gives five
bytes, `é` becoming `&hC3 &hA9`. Use it for files, network protocols and C libraries that expect
UTF-8.

**Returns** the UTF-8 bytes, without a byte order mark; `""` for `NULL` or an empty string.

**Example**

```freebasic
dim utf8 as string = WideToUtf8( "café" )
print len( utf8 )   ' 5
```

### Utf8ToWide

```freebasic
function Utf8ToWide( byref utf8Str as const string ) as ustring
```

Converts UTF-8 bytes to Unicode text, the same as `Ucode( utf8Str, CP_UTF8 )`. Invalid byte
sequences become the replacement character U+FFFD. A leading byte order mark is kept as the
character U+FEFF.

**Returns** the text, or `""` for an empty string.

**Example**

```freebasic
print Utf8ToWide( chr( &h63, &h61, &h66, &hC3, &hA9 ) )   ' café
```

### WideToOem

```freebasic
function WideToOem( byval pwszStr as wstring ptr ) as string
```

Converts Unicode text to bytes in the OEM code page, the one console programs and old DOS files
use: 437 in the United States, 850 in Western Europe. `"é"` gives `&h82` in code page 437.

**Returns** the bytes, or `""` for `NULL` or when the conversion fails.

**Example**

```freebasic
print hex( asc( WideToOem( "é" ) ) )   ' 82 in code page 437
```

### OemToWide

```freebasic
function OemToWide( byref oemStr as const string ) as ustring
```

Converts bytes in the OEM code page to Unicode text, such as the output of a console tool
captured from a pipe.

**Returns** the text, or `""` when the bytes cannot be converted.

**Example**

```freebasic
print OemToWide( chr( &h82 ) )   ' é in code page 437
```

### FormatByteSize

```freebasic
function FormatByteSize( byval ull as LONGLONG ) as ustring
```

Formats a size given in bytes the way Explorer shows it, in the largest unit that keeps the
number at least 1, to three significant digits: 532 gives `532 bytes`, 1234 `1.20 KB`, 1234567
`1.17 MB`, 1,234,567,890 `1.14 GB`. One kilobyte is 1024 bytes. The decimal separator follows the
user's settings.

**Returns** the text.

**Example**

```freebasic
print FormatByteSize( 1234567 )   ' 1.17 MB
```

Microsoft Learn: [StrFormatByteSizeW](https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-strformatbytesizew)

### FormatKBSize

```freebasic
function FormatKBSize( byval ull as LONGLONG ) as ustring
```

Formats a size given in bytes as a whole number of kilobytes, rounded up, with thousands
separators, the way Explorer's Size column shows it: 100 gives `1 KB`, 1234 `2 KB`, 1234567
`1,206 KB`.

**Returns** the text.

**Example**

```freebasic
print FormatKBSize( 1234567 )   ' 1,206 KB
```

Microsoft Learn: [StrFormatKBSizeW](https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-strformatkbsizew)

### StrFromTimeInterval

```freebasic
function StrFromTimeInterval overload( byval dwTimeMS as DWORD, byval digits as long ) as ustring
```

Formats a time given in milliseconds as hours, minutes and seconds, rounded to `digits`
significant digits:

| `dwTimeMS` | `digits` | Text |
| --- | --- | --- |
| 34000 | 3 | `34 sec` |
| 74000 | 3 | `1 min 14 sec` |
| 74000 | 2 | `1 min 10 sec` |
| 74000 | 1 | `1 min` |
| 3725000 | 6 | `1 hr 2 min 5 sec` |

**Returns** the text, padded as described.

**Example**

```freebasic
print "[" & trim( StrFromTimeInterval( 74000, 3 ) ) & "]"   ' [1 min 14 sec]
```

Microsoft Learn: [StrFromTimeIntervalW](https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-strfromtimeintervalw)

### ParseCount

```freebasic
function ParseCount( byref wszSourceString as const wstring, byref wszDelimiter as const wstring = "," ) as long
```

Counts the fields in a string: one more than the number of delimiters in it. Each character of
`wszDelimiter` is a delimiter on its own, so `";,"` splits at either, and `"--"` counts every
single `-`: `ParseCount( "a--b--c", "--" )` is 5, not 3. Empty fields count, and so does an empty
string, as one field. The match is case-sensitive.

| Parameter | Meaning |
| --- | --- |
| `wszSourceString` | The text. |
| `wszDelimiter` | The delimiter characters; a comma by default. |

**Returns** the number of fields, at least 1: `"one,two,three"` gives 3, `"1;2,3"` with `",;"`
gives 3, `"a,,b"` gives 3, `""` gives 1.

**Example**

```freebasic
print ParseCount( "1;2,3", ",;" )   ' 3
```

### ParseStr

```freebasic
function ParseStr( byref wszSourceString as const wstring, byval index as long = 1, byref wszDelimiter as const wstring = "," ) as ustring
```

Returns one field of a delimited string. Fields are numbered from 1; a negative `index` counts
from the end, -1 being the last. As in [ParseCount](#parsecount), each character of
`wszDelimiter` is a delimiter.

| Parameter | Meaning |
| --- | --- |
| `wszSourceString` | The text. |
| `index` | The field: 1 for the first, -1 for the last. |
| `wszDelimiter` | The delimiter characters; a comma by default. |

**Returns** the field, or `""` when it is empty or `index` is 0 or past the last field. For
`"one,two,three"`: 1 gives `one`, 3 `three`, -1 `three`, -3 `one`, 4 and 0 give `""`;
`ParseStr( "a,,b", 2 )` gives `""`.

**Example**

```freebasic
print ParseStr( "1;2,3", 2, ",;" )   ' 2
```

## See also

- [Category: sys/win](Category-Sys-Win)
- [Paths and files](SysWin-Paths-and-Files) for telling UTF-8 and UTF-16 text apart
- [Clipboard](SysWin-Clipboard) for text on the clipboard
- [BSTRING](BSTRING), the COM string
- Microsoft Learn: [Code page identifiers](https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers)
