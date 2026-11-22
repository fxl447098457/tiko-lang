[Home](Home) › [Function Finder](Function-Finder) › **Text**

# Text

The functions to search, slice, change, split and format strings, grouped by what you want to do. The **From** column says what a program needs before it can call one:

- **built-in**: nothing; it is always available.
- `std/money`: `#import "std/money"`, then `using money` to call it by its bare name.
- `std/strings`: `#import "std/strings"`, then `using strings` to call it by its bare name.
- `string.bi`: `#include "string.bi"`.

Jump to: [Find text in a string](#find-text-in-a-string) · [Check what a string holds](#check-what-a-string-holds) · [Take part of a string](#take-part-of-a-string) · [Change case](#change-case) · [Trim, pad and align](#trim-pad-and-align) · [Replace, insert and remove](#replace-insert-and-remove) · [Split and join](#split-and-join) · [Build and wrap strings](#build-and-wrap-strings) · [Characters and their codes](#characters-and-their-codes) · [Convert numbers to text](#convert-numbers-to-text) · [Convert text to numbers](#convert-text-to-numbers) · [Format money](#format-money) · [Pack numbers into bytes and back](#pack-numbers-into-bytes-and-back)

## Find text in a string

| Function | What it does | From |
|---|---|---|
| [InStr](Instr) | Returns the position of the first match, or 0 if there is none. | built-in |
| [InStrRev](Instrrev) | Returns the position of the last match, or 0 if there is none. | built-in |
| [Contains](Modern-String-Contains) | Returns true if the text appears anywhere in the string. | `std/strings` |
| [Find](Modern-String-Find) | Returns the position of the first match in a slice, counting from 0, or -1. | `std/strings` |
| [StartsWith](Modern-String-StartsWith) | Returns true if the string begins with the given text. | `std/strings` |
| [EndsWith](Modern-String-EndsWith) | Returns true if the string ends with the given text. | `std/strings` |
| [Tally](Modern-String-Tally) | Counts how many times the text occurs, without overlaps. | `std/strings` |
| [InstrChars](Modern-String-InstrChars) | Returns the position of the first character from a set, or 0. | `std/strings` |
| [TallyChars](Modern-String-TallyChars) | Counts the characters that belong to a set. | `std/strings` |

## Check what a string holds

| Function | What it does | From |
|---|---|---|
| [Len](Len) | Returns the length of a string, or the size of a type. | built-in |
| [Equals](Modern-String-Equals) | Returns true if two slices hold the same code units, optionally ignoring case. | `std/strings` |
| [IsBlank](Modern-String-IsBlank) | Returns true if the string is empty or holds only whitespace. | `std/strings` |
| [IsNumeric](Modern-String-IsNumeric) | Returns true if the string is a valid number, with spaces allowed around it. | `std/strings` |
| [VerifySet](Modern-String-VerifySet) | Returns the position of the first character not in a set, or 0 if all are. | `std/strings` |
| [SpanOf](Modern-String-SpanOf) | Counts the run of characters from a set that starts at a position. | `std/strings` |

## Take part of a string

| Function | What it does | From |
|---|---|---|
| [Left](Left) | Returns the first n characters. | built-in |
| [Right](Right) | Returns the last n characters. | built-in |
| [Mid](Mid-Function) | Returns the characters from a position, optionally for a given length. | built-in |
| [Between](Modern-String-Between) | Returns the text between two delimiters. | `std/strings` |
| [Extract](Modern-String-Extract) | Returns the text before a match, or the whole rest if there is none. | `std/strings` |
| [Remain](Modern-String-Remain) | Returns the text after a match, or an empty string if there is none. | `std/strings` |
| [ExtractChars](Modern-String-ExtractChars) | Returns the text before the first character from a set. | `std/strings` |
| [RemainChars](Modern-String-RemainChars) | Returns the text after the first character from a set. | `std/strings` |

## Change case

| Function | What it does | From |
|---|---|---|
| [UCase](Ucase) | Returns an upper-case copy of the string. | built-in |
| [LCase](Lcase) | Returns a lower-case copy of the string. | built-in |
| [MCase](Modern-String-MCase) | Returns a title-case copy: each word capitalised, the rest lower case. | `std/strings` |

## Trim, pad and align

| Function | What it does | From |
|---|---|---|
| [Trim](Trim) | Removes spaces, or the given characters, from both ends. | built-in |
| [LTrim](Ltrim) | Removes spaces, or the given characters, from the start. | built-in |
| [RTrim](Rtrim) | Removes spaces, or the given characters, from the end. | built-in |
| [Shrink](Modern-String-Shrink) | Trims both ends and collapses each inner run of spaces to one. | `std/strings` |
| [TrimSpace](Modern-String-TrimSpace) | Returns a slice of the text without the spaces, tabs, CRs and LFs at either end. | `std/strings` |
| [TrimStart](Modern-String-TrimStart) | Returns a slice of the text without its leading spaces, tabs, CRs and LFs. | `std/strings` |
| [TrimEnd](Modern-String-TrimEnd) | Returns a slice of the text without its trailing spaces, tabs, CRs and LFs. | `std/strings` |
| [PadLeft](Modern-String-PadLeft) | Pads on the left to a width, with spaces or a given character. | `std/strings` |
| [PadRight](Modern-String-PadRight) | Pads on the right to a width, with spaces or a given character. | `std/strings` |
| [PadCenter](Modern-String-PadCenter) | Centres the string in a width, padding both sides. | `std/strings` |
| [LSet](Lset) | Copies a string into another, left-justified and padded with spaces. | built-in |
| [RSet](Rset) | Copies a string into another, right-justified and padded with spaces. | built-in |

## Replace, insert and remove

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
| [Mid](Mid-Statement) (statement) | Overwrites part of a string in place with other text. | built-in |

## Split and join

| Function | What it does | From |
|---|---|---|
| [Split](Modern-String-Split) | Breaks a string into an Array at each delimiter. | `std/strings` |
| [SplitSlices](Modern-String-SplitSlices) | Walks the parts of a slice between separators, one at a time, in a for each loop. | `std/strings` |
| [SplitChars](Modern-String-SplitChars) | Breaks a string into an Array wherever a character from a set appears. | `std/strings` |
| [Join](Modern-String-Join) | Joins an Array of strings into one, with a separator between them. | `std/strings` |
| [SplitCsv](Modern-String-SplitCsv) | Parses CSV text into rows and fields, quoted fields included. | `std/strings` |
| [SplitCsvRow](Modern-String-SplitCsvRow) | Parses one CSV record into an Array of fields. | `std/strings` |
| [JoinCsvRow](Category-String-Library#writing-csv) | Returns an Array of fields as one CSV record, quoting each field that needs it. | `std/strings` |
| [CsvWriter](Category-String-Library#writing-csv) | Writes CSV records to any fs.Stream as UTF-8, CRLF or LF line endings. | `std/strings` |

## Build and wrap strings

| Function | What it does | From |
|---|---|---|
| [Space](Space) | Returns a string of n spaces. | built-in |
| [WSpace](Wspace) | Returns a wide string of n spaces. | built-in |
| [String](String-Function) | Returns a string of n copies of one character. | built-in |
| [WString](Wstring-Function) | Returns a wide string of n copies of one character. | built-in |
| [Repeat](Modern-String-Repeat) | Returns a string repeated n times. | `std/strings` |
| [Reverse](Modern-String-Reverse) | Returns the string with its characters in reverse order. | `std/strings` |
| [Wrap](Modern-String-Wrap) | Surrounds the string with quotes or a given pair of delimiters. | `std/strings` |
| [Unwrap](Modern-String-Unwrap) | Removes one surrounding pair of quotes or delimiters, if both are there. | `std/strings` |
| [Escape](Modern-String-Escape) | Replaces quotes, backslashes and control characters with backslash escapes. | `std/strings` |
| [Unescape](Modern-String-Unescape) | Turns backslash escapes back into the characters they stand for. | `std/strings` |

## Characters and their codes

| Function | What it does | From |
|---|---|---|
| [Asc](Asc) | Returns the character code at a position in a string. | built-in |
| [Chr](Chr) | Returns a string made from one or more character codes. | built-in |
| [WChr](Wchr) | Returns a wide string made from one or more Unicode code points. | built-in |

## Convert numbers to text

| Function | What it does | From |
|---|---|---|
| [Str](Str) | Returns a number or boolean as text. | built-in |
| [WStr](Wstr) | Returns a number as a wide string. | built-in |
| [Format](Category-Format) | Builds text from values with a format string such as "{:>6.2f}". | `std/strings` |
| [Format](Format) | Formats a number with a picture string such as "#,##0.00". | `string.bi` |
| [Hex](Hex) | Returns a number as hexadecimal text. | built-in |
| [WHex](Whex) | Returns a number as hexadecimal wide-string text. | built-in |
| [Bin](Bin) | Returns a number as binary text. | built-in |
| [WBin](Wbin) | Returns a number as binary wide-string text. | built-in |
| [Oct](Oct) | Returns a number as octal text. | built-in |
| [WOct](Woct) | Returns a number as octal wide-string text. | built-in |

## Convert text to numbers

| Function | What it does | From |
|---|---|---|
| [Val](Val) | Converts text to a double. | built-in |
| [ValInt](Valint) | Converts text to a 32-bit integer. | built-in |
| [ValLng](Vallng) | Converts text to a 64-bit integer. | built-in |
| [ValUInt](Valuint) | Converts text to an unsigned 32-bit integer. | built-in |
| [ValULng](Valulng) | Converts text to an unsigned 64-bit integer. | built-in |

## Format money

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

## Pack numbers into bytes and back

| Function | What it does | From |
|---|---|---|
| [MKI](Mki) | Copies an integer's bytes into a string. | built-in |
| [MKL](Mkl) | Copies a Long's bytes into a 4-byte string. | built-in |
| [MKShort](Mkshort) | Copies a Short's bytes into a 2-byte string. | built-in |
| [MKLongInt](Mklongint) | Copies a LongInt's bytes into an 8-byte string. | built-in |
| [MKS](Mks) | Copies a Single's bytes into a 4-byte string. | built-in |
| [MKD](Mkd) | Copies a Double's bytes into an 8-byte string. | built-in |
| [CVI](Cvi) | Reads an integer back from a string of its bytes. | built-in |
| [CVL](Cvl) | Reads a Long back from a 4-byte string. | built-in |
| [CVShort](Cvshort) | Reads a Short back from a 2-byte string. | built-in |
| [CVLongInt](Cvlongint) | Reads a LongInt back from an 8-byte string. | built-in |
| [CVS](Cvs) | Reads a Single back from a 4-byte string. | built-in |
| [CVD](Cvd) | Reads a Double back from an 8-byte string. | built-in |

## See Also

- [String Library guide](Category-String-Library)
- [Format guide](Category-Format)
- [UString](Category-UString)
- [Block strings](Category-Block-Strings)
- [String slices](Category-String-Slices)
- [Regular expressions (PCRE2)](PCRE2-Tutorial)
- [Base64, hex and percent-encoding](Category-Codec)

---

[Home](Home) · [Function Finder](Function-Finder) · [Keyword Index](Keyword-Index)

<!-- Generated by tools/wikifinder/finder.py. Edit the data, not this page. -->
