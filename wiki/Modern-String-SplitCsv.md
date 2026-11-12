[Home](Home) › [String Library](Category-String-Library) › [String Library](Category-String-Library) › **SplitCsv**

# SplitCsv

Parses CSV text into rows and fields, quoted fields included.

## Syntax

```freebasic
SplitCsv( s [, delim] )
```

## Notes

- O(n) — a whole RFC-4180 document, records and fields in a single cursor pass.
- A **STRING** gives `Array( of CsvRow )` (STRING fields); a **WSTRING** or **USTRING** gives `Array( of CsvURow )` (USTRING fields) — the same return rule as every other function in this library.
- Handles a delimiter inside quotes, `""` as one literal quote, LF/CRLF/CR mixed, a trailing empty field, and a last record with no trailing newline.
- **A newline inside a quoted field is content, not a record break.** Records and fields come from the same pass, so a row is not a line.
- **Zero rows means an unclosed quote.** A well-formed parse always yields at least one record — an empty input is one record of one empty field — so the count is an unambiguous error signal.
- A trailing newline does **not** make an extra record: `"a,b\n"` is one row, not two. This is deliberately the opposite of [Split](Modern-String-Split)'s never-drop-a-field rule. A blank line in the *middle* is still a real, empty record.
- A delimiter that is not exactly one code unit means no delimiter: every record comes back as one field, records and quoting still honoured.
- On the byte family this is **exact for UTF-8** — quote, comma, CR and LF are all below `0x80` and no continuation byte is, so the fields come back as the same bytes that went in.
- No file I/O. It takes text and returns rows; the reading belongs to the caller.

## Examples

```freebasic
#import "std/containers"
#import "std/strings"
using strings, containers

'' A quoted comma is content -- this is what Split cannot do
dim as Array( of CsvRow ) t = SplitCsv( !"name,note\nPaul,\"one, two\"" )

print t.Count( )                  '' 2 -- the trailing-newline-free last record counts
print t[ 1 ].fields[ 1 ]          '' one, two

'' A newline inside quotes is part of the field, not a new record
dim as Array( of CsvRow ) memo = SplitCsv( !"\"line1\nline2\",z" )
print memo.Count( )               '' 1
print memo[ 0 ].fields.Count( )   '' 2

'' Zero rows is the error signal, and the only thing it can mean
dim as Array( of CsvRow ) bad = SplitCsv( !"a,\"never closed" )
if bad.Count( ) = 0 then print "malformed CSV"

'' Walking a table
for each byref row in t
    for each fld in row.fields
        print fld;
    next
    print
next
```

---

**Library:** [String Library](Category-String-Library)  
**Category:** [String Library](Category-String-Library)  
**Documented under:** The Functions
