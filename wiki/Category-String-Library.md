[Home](Home) › [All Categories](Categories) › **String Library**

# String Library

```freebasic
#import "std/containers"
#import "std/strings"
using strings, containers

print Replace( "Hello World", "World", "Earth" )   ' Hello Earth
print Tally( "a,b,c", "," )                        ' 2
print PadLeft( "42", 6, "0" )                      ' 000042
print Between( "log(42) end", "(", ")" )           ' 42

dim parts as Array( of string ) = Split( "a,b,c" )
print parts.Count( )                               ' 3
print Join( parts, " | " )                         ' a | b | c

dim rows as Array( of CsvRow ) = SplitCsv( text )  ' RFC 4180, quotes and all
print rows[ 0 ].fields[ 1 ]
```

Building text from values with a layout -- a width, a number of decimals, hexadecimal -- is [Format](Category-Format), in the same module.

## Why It Exists

The built-in string intrinsics include LEFT, RIGHT, MID, INSTR, INSTRREV, TRIM, UCASE, LCASE, SPACE and STRING, but none of them replaces, splits, joins or pads, and none works with a set of characters. Every program that needs those writes them again, usually with a 'redim preserve' loop that is quadratic.

NOTHING HERE IS A KEYWORD. Replace, Contains, Split and the rest belong to the module: nothing is added to a program until it imports std/strings, and the bare names only after 'using strings', so they stay available as your own identifiers. The language is unchanged.

## All Four String Types

Every function is declared three times -- STRING, WSTRING, USTRING -- and ZSTRING is served by the STRING overload through the compiler's own conversion, which for bytes to bytes is exact and involves no locale. You never name which family you are in; the first argument decides.

There is no dynamic ZSTRING or WSTRING, so a function cannot return the type it was handed:

```freebasic
string, zstring   ->  string        bytes, no encoding assumed
wstring, ustring  ->  ustring       UTF-16 on every target
```

A WSTRING in giving a USTRING out is the surprising one. It is also the only answer available: a fixed-length result would need a buffer the caller has not supplied. On Windows it costs nothing to use, because a ustring already is UTF-16.

EVERY PARAMETER AFTER THE FIRST IS A USTRING, in all three overloads. That is forced, not preferred. The compiler ranks an overload on all of its parameters, so with per-family types on the second one,

```freebasic
Tally( someWstring, "abc" )        ' error 98: Ambiguous call
```

is an ambiguity rather than a choice. One shared type on the later parameters moves the whole decision onto the first.

The cost is that a pattern handed to the BYTE family is converted UTF-8 -> UTF-16 -> UTF-8 on the way in. For an ASCII or UTF-8 pattern that is exact, and for a literal it costs nothing at run time -- the compiler converts string literals to ustring at compile time. It does not survive a pattern of arbitrary non-UTF-8 bytes; searching binary for a raw byte sequence is outside what this library does, and USTRING draws the same line. The haystack is never converted, so byte positions in a STRING stay byte positions.

## Code Units, Positions, AND Case

Positions and lengths count CODE UNITS, matching LEN, \[\] and INSTR. On the wide family an astral character is a surrogate pair and counts as 2. A search can never land mid-character -- a surrogate half cannot equal a BMP unit -- though MID can split one.

POSITIONS ARE 1-BASED, and 0 means "not found", matching INSTR. The functions over [string slices](Category-String-Slices) -- `Find`, `Equals`, `TrimSpace`, `SplitSlices` and the slice overloads of `StartsWith` and `EndsWith` -- are the exception: they count from 0, as `s[i]` and `s[lo to hi]` do, and `Find` answers -1. This is NOT the zero-based convention containers.Array uses. Strings and containers are different worlds and each keeps its own tradition.

A start below 1 is invalid and answers 0 (or "" for a function returning text) rather than clamping, so a position fed back in from a call that returned "not found" cannot silently restart the scan.

'ignoreCase' folds ASCII only on the byte family, because a STRING is a byte buffer with no declared encoding and folding above 127 would be guessing at a codepage. The wide family folds through the generated simple BMP table, so it gives the same answer on every machine and in every locale.

ON THE BYTE FAMILY A CHARACTER SET IS A SET OF BYTES. InstrChars, TallyChars, VerifySet, SpanOf, RemoveChars, RetainChars, ReplaceChars and SplitChars compare one unit at a time, and on a STRING a unit is a byte. Put a multi-byte character in the set and each of its bytes joins separately:

```freebasic
dim as string s = "xx" & chr(&hC3) & chr(&hA9) & "yy"    ' UTF-8
InstrChars( 1, s, wchr(&hE8) )      ' 3 -- matched the C3 byte
```

A STRING carries no encoding, so the set cannot be decoded into characters. Use the ustring overload for character sets over non-ASCII text; there a set member is one code unit and the answer is 4. The substring functions are unaffected on both families: they match whole sequences and are exact for any UTF-8 pattern.

## The Functions

n is the input length, m the pattern length.

SEARCH AND INSPECT                                          returns

```freebasic
Tally( s, match [, ic] )                     O(n*m)   int32
    Non-overlapping occurrences. "aaaa" contains "aa" TWICE.
TallyChars( s, chars [, ic] )                O(n*k)   int32
InstrChars( start, s, chars [, ic] )         O(n*k)   int32
VerifySet( start, s, chars [, ic] )          O(n*k)   int32
    First position NOT in the set, or 0 if every one is.
SpanOf( start, s, chars [, ic] )             O(n*k)   int32
StartsWith( s, prefix [, ic] )               O(m)     boolean
EndsWith( s, suffix [, ic] )                 O(m)     boolean
Contains( s, match [, ic] )                  O(n*m)   boolean
```

EXTRACT

```freebasic
Extract( start, s, match [, ic] )            O(n*m)   text before match
ExtractChars( start, s, chars [, ic] )       O(n*k)
Remain( s, match [, start] [, ic] )          O(n*m)   text after match
RemainChars( s, chars [, start] [, ic] )     O(n*k)
Between( s, open, close [, start] [, ic] )   O(n*m)
ClipLeft( s, count )                         O(n)
ClipRight( s, count )                        O(n)
DeleteAt( s, start, count )                  O(n)
InsertAt( s, insert, position )              O(n)
```

TRANSFORM

```freebasic
Replace( s, match, with_ [, ic] )            O(n*m)
Remove( s, match [, ic] )                    O(n*m)
RemoveChars( s, chars [, ic] )               O(n*k)
RetainChars( s, chars [, ic] )               O(n*k)
ReplaceChars( s, chars, with_ [, ic] )       O(n*k)   length is invariant
RemoveBetween( s, open, close
               [, all] [, start] [, ic] )    O(n*m)
Reverse( s )                                 O(n)
Repeat( count, s )                           O(n*count)
Shrink( s [, mask] )                         O(n*k)
MCase( s )                                   O(n)     title case
```

PAD, WRAP, ESCAPE, PREDICATES

```freebasic
PadLeft( s, width [, pad] )                  O(width)
PadRight( s, width [, pad] )                 O(width)
PadCenter( s, width [, pad] )                O(width)
Wrap( s [, open] [, close] )                 O(n)
Unwrap( s [, open] [, close] [, ic] )        O(n)
Escape( s )                                  O(n)
Unescape( s )                                O(n)
IsNumeric( s )                               O(n)     boolean
IsBlank( s )                                 O(n)     boolean
```

SPLIT AND JOIN

```freebasic
Split( s [, delim] [, ic] )                  O(n*m)   Array( of T )
SplitChars( s [, chars] [, ic] )             O(n*k)   Array( of T )
Join( parts [, delim] )                      O(total) text
```

CSV

```freebasic
SplitCsv( s [, delim] )                      O(n)     Array( of CsvRow )
    A whole RFC-4180 document: records and fields in one pass.
    Zero rows means an unclosed quote.
SplitCsvRow( s [, delim] )                   O(n)     Array( of T )
    One record. The quote-aware Split. Empty means malformed.
```

## The Rules That Are Easy To Get Wrong

Each of these has a defensible opposite, so each is a decision rather than an accident, and each is asserted in the test suite.

EMPTY ARGUMENTS

```freebasic
Tally( s, "" )              0     a zero-width match advances nothing
InstrChars( n, s, "" )      0     "find one of nothing" cannot succeed
VerifySet( n, s, "" )       n     "find one NOT among nothing" cannot fail
SpanOf( n, s, "" )          0     nothing is in the set, so the run is empty
StartsWith( s, "" )         true  vacuous, including for s = ""
Contains( s, "" )           true  same
RemoveChars( s, "" )        s     an empty set removes nothing
RetainChars( s, "" )        ""    and so keeps nothing -- the complement
Shrink( s, "" )             s     there is nothing to shrink
Split( s, "" )              one field, the whole string
SplitCsv( s, "" )           one field per record, records still split
SplitCsv( "" )              one record of one empty field
```

EXTRACT AND REMAIN MISS DIFFERENTLY, on purpose:

```freebasic
Extract( 1, s, missing )    the whole remainder
Remain( s, missing )        ""
```

Extract's rule is what makes a parse loop terminate cleanly -- the final field has no trailing delimiter, and this hands it back instead of dropping it. Remain's is the only honest answer to "everything after X" when there was no X.

SPLIT NEVER DROPS A FIELD. N delimiters give N+1 fields, always:

```freebasic
Split( "a,,c" ) -> 3      Split( ",a" ) -> 2      Split( "" ) -> 1
```

That is what makes Join( Split( s, d ), d ) equal s for every s.

SPLITCSV'S TRAILING RULE IS THE OPPOSITE, and the two sit next to each other, so it is worth saying twice: Split( "a," ) is two fields, and SplitCsv( "a,b\n" ) is one record. A trailing delimiter is a field the writer meant; a trailing newline is how text files end.

INVALID ARGUMENTS ARE NO-OPS, not errors and not truncation. DeleteAt with a start past the end, or a count of zero, returns the string unchanged; InsertAt with a position below 1 does the same. A pad width of 0 or less gives "".

ONE UNIT MEANS ONE UNIT. ReplaceChars maps a single unit to a single unit, so 'with\_' must be exactly one; anything else -- empty, longer, or an astral character, which is two units -- returns the string unchanged rather than writing half a character. The pad functions take the same rule with a softer failure: a pad that is not one unit pads with a SPACE, because a pad function that pads with nothing is useless while a substitution that substitutes nothing is merely inert.

## CSV

Split is the wrong tool for a comma-separated FILE, and not by a little. There is no delimiter that survives being both a separator and content, so split-on-comma-then-repair cannot be patched into correctness; a quoted field containing a comma is not an edge case, it is the first line of most real exports.

[SplitCsv](Modern-String-SplitCsv) handles, in a single pass with a cursor:

```freebasic
"a,b"          a delimiter inside quotes, taken literally
""             two quotes inside quotes, as one literal quote
CRLF, LF, CR   mixed freely, each ending exactly one record
"l1\nl2"       a NEWLINE INSIDE A QUOTED FIELD -- content, not a record break
a,b,           a trailing empty field
a,b            a last record with no trailing newline
```

RECORDS ARE FOUND BY THE SAME PASS AS FIELDS, which is what buys the embedded newline. A row is not a line. Splitting into lines first passes every other case and fails that one, and broker and CRM exports do contain memo columns with newlines in them.

The result is a table:

```freebasic
dim rows as Array( of CsvRow ) = SplitCsv( text )
for each byref row in rows
    for each fld in row.fields
        print fld
    next
next
```

CsvRow holds STRING fields and CsvURow holds USTRING ones, following the same return rule as everything else here -- a STRING in gives CsvRow, a WSTRING or USTRING gives CsvURow. A row is a TYPE wrapping an array rather than a bare nested generic, because a generic will not instantiate directly in a TYPE field: Array( of Array( of string ) ) is not available.

NO FILE I/O. This takes text and returns rows; the reading belongs to the caller. That is what lets every awkward case be an assertion in the test suite instead of something discovered on a Tuesday with a real statement.

AN UNCLOSED QUOTE ANSWERS ZERO ROWS. A well-formed parse always yields at least one record -- an empty input is one record of one empty field, the same rule that makes Split( "" ) one field -- so a count of 0 is unambiguous and means exactly one thing:

```freebasic
dim rows as Array( of CsvRow ) = SplitCsv( text )
if rows.Count( ) = 0 then          ' malformed; do not use the rows
```

Consuming the rest of the document as one field is the alternative, and it produces a plausible-looking single row rather than a complaint. Silence is the one answer that cannot be checked. There is no Result type here and no error code: the count already carries it, and a total function needs neither.

A TRAILING NEWLINE DOES NOT MAKE AN EXTRA RECORD -- "a,b\n" is one row, not two. That is the opposite of Split's never-drop-a-field rule, and deliberately so: a file ending in a newline is the normal case, not a file with a blank record at the end. A blank line in the MIDDLE is still a real, empty record.

A DELIMITER THAT IS NOT EXACTLY ONE CODE UNIT means no delimiter at all: every record comes back as one field, with records and quoting still honoured. Same rule as Split's empty delimiter, and there is no useful reading of a two-character CSV separator.

ON THE BYTE FAMILY THIS IS EXACT FOR UTF-8, unlike the character-set functions. Quote, comma, CR and LF are all below 0x80, and no UTF-8 continuation byte is, so a multi-byte character can never be mistaken for a delimiter or a record break. The fields come back as the same bytes that went in.

[SplitCsvRow](Modern-String-SplitCsvRow) is the same parser over a single record, returning the Array( of T ) that Split returns -- a drop-in wherever the fields may be quoted. An empty result means malformed, on the same rule. Text holding more than one record answers the first; the rest is a table, and SplitCsv is what returns tables.

COMPLEXITY IS O(n). The scan appends whole runs of ordinary characters with MID rather than one unit at a time. Per-character '&=' is what the obvious version does, and it is quadratic in the field length, because a tiko string grows one 32-byte granule at a time, not geometrically.

Ported from the finara import engine (fnr\_CsvParse), itself ported from tracks. The cursor is the same; three things changed on the way in:

- the failure is a ROW COUNT rather than a Result( of Table, Error ), so the string library keeps its single dependency on std/containers' Array and stays total;
- an EMPTY INPUT is one empty record rather than none, which is what makes the zero-row signal unambiguous;
- a delimiter that is not one unit is a no-op rather than an error, matching how every other invalid argument here behaves.

The column profiles and transaction mapping that surround the parser in finara did not come with it. They are that application's schema, not a string algorithm.

### Writing CSV

`JoinCsvRow( fields [, sep] )` is SplitCsv's other half: it turns an `Array( of ustring )` into one CSV record, and `CsvWriter` writes records to any `fs.Stream` -- a file, a pipe -- as UTF-8.

```freebasic
#import "std/strings"
#import "std/containers"
#import "std/fs"

dim as containers.Array( of ustring ) row
row.Push( "name" ) : row.Push( "a, b" ) : row.Push( !"say \"hi\"" )
print strings.JoinCsvRow( row )                 ' name,"a, b","say ""hi"""

dim as fs.File f
if f.Create( "out.csv" ).IsOk( ) then
    dim as strings.CsvWriter w = strings.CsvWriter( f )
    w.WriteRow( row )
    if w.Finish( ).IsOk( ) = false then print "write failed"
end if
```

A field is quoted when it holds the separator, a double quote, CR or LF, or starts or ends with a space or tab; a quote inside is doubled (RFC 4180). Records end with CRLF; `CsvWriter( f, sep, false )` ends them with LF. Whatever JoinCsvRow writes, SplitCsv reads back as the same fields. The writer keeps the first failure: rows after it are not written, and `Finish( )` reports it, or else the stream's `Flush( )`.

## Reverse Is The One Function Whose Families Disagree

On the wide family SURROGATE PAIRS ARE KEPT INTACT. A ustring is UTF-16 by definition, so reversing its code units blindly would emit a low surrogate before its high one -- invalid UTF-16 every time an astral character is present, not occasionally.

On the byte family bytes reverse as bytes, which does mangle multi-byte UTF-8. A STRING has no declared encoding, so there is no pair to recognise and no way to know whether there would be one. Reverse UTF-8 text through the ustring overload.

## Escape

Backslash escaping -- what makes a string safe to write between quotes in a config file, a log line, or generated source, and reversible afterwards.

```freebasic
\  "             ->  \\  \"
LF CR TAB NUL    ->  \n  \r  \t  \0
other units below 32, and 127   ->  \xHH
everything else, INCLUDING ALL NON-ASCII, passes through
```

Non-ASCII is left alone deliberately: escaping it would make a ustring unreadable and reduce a UTF-8 STRING to a wall of hex, and the job is to neutralise what breaks quoting, not to force the text to ASCII.

Unescape is the exact inverse. Unescape( Escape( s ) ) is s for every input, including one that already contains backslashes -- verified over every byte value 0..255. An unrecognised escape yields the escaped character ("\\q" -> "q"); a trailing lone backslash is kept, since nothing follows it to unquote.

## Implementation

In tiko-rt the algorithms live in lib/rt/src/inc/ops-core.ti and are written ONCE, then instantiated twice -- lib/rt/src/str/ops.tiko at byte width, lib/rt/src/ustr/ops.tiko at 16-bit -- with ## token pasting. Two hand-maintained copies of a search loop drift, and the drift shows up as one width quietly disagreeing with the other on an edge case nobody tests twice.

Reached from tiko code through 'extern "C" declare ... alias' at the module's scope -- the pattern inc/string.bi already uses for FORMAT. Note that 'alias' alone is not enough inside a module: without the extern "C" the name is mangled through the module's chain, and a nested namespace does not inherit an enclosing extern either.

Split, SplitChars, Join, SplitCsv and SplitCsvRow are the only ones with tiko bodies, because their result is an Array( of T ) that the runtime cannot build. They are public members of the module, compiled once with it, so any number of files in a program can import std/strings and still link. The runtime side returns field boundaries rather than strings, so a split is two linear passes instead of the ParseCount-then-Parse-in-a-loop shape, which rescans from the start for every field and is quadratic.

## Money Formatting

`MoneyFormat`, from `std/money`, renders an amount the way the user's locale writes money. Assign a numeric value, set the properties you care about, read back the string.

```freebasic
#import "std/money"
using money

dim as MoneyFormat m = DecimalParse( "-1234.5" ).Value( )
print m.ToString( )                  '' -$1,234.50   on en-CA

m.Negative = MONEY_NEG_PARENS
m.ThousandsSep = ""                  '' SUPPRESSED, not "use the locale"
print m.ToString( )                  '' ($1234.50)

m.UseLocale( MONEY_F_THOUSANDSSEP )  '' back to the locale's separator
```

`Currency` and `Decimal` HOLD money and the finance functions COMPUTE with it. Nothing displayed it. [MoneyFormat](Modern-String-MoneyFormat) is that half. It is documented in this library because what it does is build a string, and it ships in `std/money` beside Currency.

Everything the locale specifies -- symbol, decimal point, thousands separator, digit grouping, fraction digits, which side the symbol goes on, where the sign goes -- is used by default, and every one of them can be overridden or suppressed individually. Setting a property always marks it as yours, so `m.Symbol = ""` SUPPRESSES the symbol and only `UseLocale` gives it back; without that distinction suppression could not be expressed at all.

Windows reads `GetLocaleInfoEx( LOCALE_NAME_USER_DEFAULT, ... )` and Linux and macOS read `localeconv( )`. Not one portable path, and both reasons are silent failures rather than errors: the Windows CRT is not the Region control panel and does not reliably see per-user overrides, and `localeconv` hands back bytes in the process code page, where the euro sign is one byte on a 1252 machine. `std/money` pulls in nothing from `inc/win` -- `GetLocaleInfoEx` sits behind `_WIN32_WINNT >= &h0600` and `inc/win/_mingw.bi` defaults that to `&h0502`, so with the shipped headers it is not visible at all.

On Linux and macOS it asks for `LC_MONETARY` alone. Widening it to `LC_ALL` would move `LC_NUMERIC` too, and `DecimalFromDouble` parses `snprintf( "%.14e" )` output -- under a German `LC_NUMERIC` every double assigned to a MoneyFormat would silently become an invalid Decimal. Formatting money must not change how the rest of the program reads numbers.

The thirty layout combinations behind [MoneyCompose](Modern-String-MoneyCompose) were generated from glibc, not transcribed: thirty synthetic locales built with `localedef` and formatted with `strfmon(3)`, asserted one cell at a time.

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Text](Functions-Text) lists them beside the rest of the area.

### Find text in a string

| Function | What it does | From |
|---|---|---|
| [Contains](Modern-String-Contains) | Returns true if the text appears anywhere in the string. | `std/strings` |
| [StartsWith](Modern-String-StartsWith) | Returns true if the string begins with the given text. | `std/strings` |
| [EndsWith](Modern-String-EndsWith) | Returns true if the string ends with the given text. | `std/strings` |
| [Tally](Modern-String-Tally) | Counts how many times the text occurs, without overlaps. | `std/strings` |
| [InstrChars](Modern-String-InstrChars) | Returns the position of the first character from a set, or 0. | `std/strings` |
| [TallyChars](Modern-String-TallyChars) | Counts the characters that belong to a set. | `std/strings` |

### Check what a string holds

| Function | What it does | From |
|---|---|---|
| [IsBlank](Modern-String-IsBlank) | Returns true if the string is empty or holds only whitespace. | `std/strings` |
| [IsNumeric](Modern-String-IsNumeric) | Returns true if the string is a valid number, with spaces allowed around it. | `std/strings` |
| [VerifySet](Modern-String-VerifySet) | Returns the position of the first character not in a set, or 0 if all are. | `std/strings` |
| [SpanOf](Modern-String-SpanOf) | Counts the run of characters from a set that starts at a position. | `std/strings` |

### Take part of a string

| Function | What it does | From |
|---|---|---|
| [Between](Modern-String-Between) | Returns the text between two delimiters. | `std/strings` |
| [Extract](Modern-String-Extract) | Returns the text before a match, or the whole rest if there is none. | `std/strings` |
| [Remain](Modern-String-Remain) | Returns the text after a match, or an empty string if there is none. | `std/strings` |
| [ExtractChars](Modern-String-ExtractChars) | Returns the text before the first character from a set. | `std/strings` |
| [RemainChars](Modern-String-RemainChars) | Returns the text after the first character from a set. | `std/strings` |

### Change case

| Function | What it does | From |
|---|---|---|
| [MCase](Modern-String-MCase) | Returns a title-case copy: each word capitalised, the rest lower case. | `std/strings` |

### Trim, pad and align

| Function | What it does | From |
|---|---|---|
| [Shrink](Modern-String-Shrink) | Trims both ends and collapses each inner run of spaces to one. | `std/strings` |
| [PadLeft](Modern-String-PadLeft) | Pads on the left to a width, with spaces or a given character. | `std/strings` |
| [PadRight](Modern-String-PadRight) | Pads on the right to a width, with spaces or a given character. | `std/strings` |
| [PadCenter](Modern-String-PadCenter) | Centres the string in a width, padding both sides. | `std/strings` |

### Replace, insert and remove

| Function | What it does | From |
|---|---|---|
| [Replace](Modern-String-Replace) | Replaces every occurrence of the text with other text. | `std/strings` |
| [ReplaceChars](Modern-String-ReplaceChars) | Replaces each character from a set with one given character. | `std/strings` |
| [Remove](Modern-String-Remove) | Removes every occurrence of the text. | `std/strings` |
| [RemoveChars](Modern-String-RemoveChars) | Removes every character that belongs to a set. | `std/strings` |
| [RetainChars](Modern-String-RetainChars) | Keeps only the characters that belong to a set. | `std/strings` |
| [RemoveBetween](Modern-String-RemoveBetween) | Removes a pair of delimiters and the text between them. | `std/strings` |
| [InsertAt](Modern-String-InsertAt) | Inserts text at a position. | `std/strings` |
| [DeleteAt](Modern-String-DeleteAt) | Deletes a number of characters at a position. | `std/strings` |
| [ClipLeft](Modern-String-ClipLeft) | Removes a number of characters from the start. | `std/strings` |
| [ClipRight](Modern-String-ClipRight) | Removes a number of characters from the end. | `std/strings` |

### Split and join

| Function | What it does | From |
|---|---|---|
| [Split](Modern-String-Split) | Breaks a string into an Array at each delimiter. | `std/strings` |
| [SplitChars](Modern-String-SplitChars) | Breaks a string into an Array wherever a character from a set appears. | `std/strings` |
| [Join](Modern-String-Join) | Joins an Array of strings into one, with a separator between them. | `std/strings` |
| [SplitCsv](Modern-String-SplitCsv) | Parses CSV text into rows and fields, quoted fields included. | `std/strings` |
| [SplitCsvRow](Modern-String-SplitCsvRow) | Parses one CSV record into an Array of fields. | `std/strings` |

### Build and wrap strings

| Function | What it does | From |
|---|---|---|
| [Repeat](Modern-String-Repeat) | Returns a string repeated n times. | `std/strings` |
| [Reverse](Modern-String-Reverse) | Returns the string with its characters in reverse order. | `std/strings` |
| [Wrap](Modern-String-Wrap) | Surrounds the string with quotes or a given pair of delimiters. | `std/strings` |
| [Unwrap](Modern-String-Unwrap) | Removes one surrounding pair of quotes or delimiters, if both are there. | `std/strings` |
| [Escape](Modern-String-Escape) | Replaces quotes, backslashes and control characters with backslash escapes. | `std/strings` |
| [Unescape](Modern-String-Unescape) | Turns backslash escapes back into the characters they stand for. | `std/strings` |

### Convert numbers to text

| Function | What it does | From |
|---|---|---|
| [Format](Category-Format) | Builds text from values with a format string such as "{:>6.2f}". | `std/strings` |

### Format money

| Function | What it does | From |
|---|---|---|
| [MoneyFormat](Modern-String-MoneyFormat) | Holds an amount and prints it the way the user's locale writes money. | `std/money` |
| [MoneySetLocale](Modern-String-MoneySetLocale) | Switches money formatting to a named locale; returns false if it is unknown. | `std/money` |
| [MoneyLocaleName](Modern-String-MoneyLocaleName) | Returns the name of the locale that money is formatted for. | `std/money` |
| [MoneyLocaleIsValid](Modern-String-MoneyLocaleIsValid) | Returns false if the system rejected the money locale. | `std/money` |
| [MoneyRefreshLocale](Modern-String-MoneyRefreshLocale) | Rereads the locale's money settings after the user changes them. | `std/money` |
| [MoneyCompose](Modern-String-MoneyCompose) | Assembles a number, symbol and sign in one of the standard layouts. | `std/money` |
| [MoneyLayoutFromICurrency](Modern-String-MoneyLayoutFromICurrency) | Converts a Windows positive-currency code into layout flags. | `std/money` |
| [MoneyLayoutFromINegCurr](Modern-String-MoneyLayoutFromINegCurr) | Converts a Windows negative-currency code into layout flags. | `std/money` |

<!-- finder:end -->

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
