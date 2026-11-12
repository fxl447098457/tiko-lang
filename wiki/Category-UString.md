[Home](Home) › [All Categories](Categories) › **UString**

# UString

## Why It Exists

Besides USTRING, tiko has three string types, and none of them is a portable Unicode string:

STRING          var-len, heap, byte-oriented. Dynamic, but it has no encoding

```freebasic
-- it is a byte buffer.
```

ZSTRING \[\* N\]   raw NUL-terminated bytes, for C interop. WSTRING \[\* N\]   raw wide characters, wchar_t-width: 2 bytes on Windows,

```freebasic
4 on Linux and macOS, 1 on DOS. Fixed length only.
```

So the same source builds a UTF-16 string on one target and a UTF-32 string on another, silently -- and whichever you pick, you cannot resize it. The width leaks into every byte offset, every pointer walk, and every file written.

USTRING is one type that is dynamic, Unicode, and byte-identical on every target. A code unit is uint16 everywhere. STRING, ZSTRING and WSTRING are untouched.

## Declaring

```freebasic
dim as ustring u              '' var-len, grows on demand
dim as ustring * 16 f         '' fixed, 16 CODE UNITS (32 bytes)

u = "hello"                   '' literals convert at compile time
var v = u + "!"               '' VAR infers the dynamic form
```

USTRING \* N is NUL-terminated and LEN returns the text length, following WSTRING \* N. It does NOT space-pad the way STRING \* N does.

## Code Units, NOT Characters

LEN, \[\], ASC, and every position and length in LEFT/RIGHT/MID/INSTR count UTF-16 CODE UNITS. A character outside the Basic Multilingual Plane is a surrogate pair and therefore counts as 2:

```freebasic
dim as ustring a = "e"        '' 1 unit
dim as ustring b = "<U+1D11E>" '' 2 units -- one character, one pair
```

This is the same answer WSTRING already gives on Windows, and it keeps \[\] and LEN O(1). It does mean MID can split a surrogate pair, exactly as it can on a WSTRING -- that is a property of UTF-16, not something this type introduces.

Indexing yields the code unit's value, so a non-ASCII BMP character reads as its real codepoint:

```freebasic
dim as ustring e = "<U+20AC>"
print e[0]                    '' 8364
```

## Conversion

STRING / ZSTRING  <->  USTRING     UTF-8, on every target WSTRING           <->  USTRING     re-encoded where wchar_t is not 16 bits

Malformed UTF-8 becomes U+FFFD rather than raising an error: a text editor must be able to open a damaged file, not refuse it.

THE ONE BOUNDARY: arbitrary BINARY does not round-trip through a USTRING. Bytes that are not valid UTF-8 become U+FFFD and the originals are gone. Binary data belongs in STRING.

Note this differs from STRING <-> WSTRING, which goes through the C locale and is therefore codepage- and platform-dependent. A portable type cannot afford that.

To build a ustring from a codepoint, use WCHR -- CHR produces a single BYTE, which is not valid UTF-8 above 127:

```freebasic
dim as ustring c : c = wchr(233)      '' one character
```

## Ucase / Lcase

Simple case mapping over the BMP, from a generated table -- NOT towupper() or towlower(), which are locale-dependent and would make the same string fold differently depending on the user's locale and on which libc the program linked against.

"Simple" means one code unit in, one out. Case changes that alter length (the German sharp s upper-casing to "SS") are not applied, matching every other string type. Astral characters have no simple case mapping and pass through unchanged.

The table was built from Python's unicodedata and is committed as `src/rtlib/ustr_casetable.c`.

## Interop

A ustring works anywhere a STRING or WSTRING does, converting as above. Two cases are worth knowing:

Passing a ustring to a WSTRING PTR parameter -- a Win32 ...W API, typically -- is a FREE pointer reinterpret where wchar_t is 16 bits, because a ustring already is UTF-16:

```freebasic
declare function MessageBoxW( ..., byval txt as wstring ptr, ... ) as int32
dim as ustring msg = "hello"
MessageBoxW( ..., msg, ... )        '' no conversion, no copy
```

Where wchar_t is wider the text must be re-encoded into a temporary, and the compiler emits a warning so that cost is not invisible to someone developing on Windows.

Passing a ustring to a ZSTRING PTR parameter is deliberately a type mismatch: a pointer needs a buffer of the right element width, and a ustring's is 16 bits. Convert explicitly through a STRING if you need bytes.

## I/O

Where the output goes decides the encoding:

real Windows console                    the wide path, so the OS renders

```freebasic
UTF-16 directly
```

files, redirected output, other consoles                                UTF-8

That second case is the point: a ustring written to a file produces a portable UTF-8 file on every platform. LINE INPUT # and INPUT # decode UTF-8 to match.

PRINT USING counts CODE UNITS in its field widths, matching LEN and \[\]. It parses in UTF-16 rather than converting to UTF-8 first, so "\\   \\" applied to a five-character accented string yields all five characters and not the first three -- and yields the same thing whether the output is a console or a file.

A field can split a surrogate pair, exactly as MID can. That is a property of UTF-16, not of PRINT USING.

DRAW STRING draws ONE CODE UNIT AS ONE GLYPH. gfxlib2's font is a 256-glyph bitmap indexed by byte -- it has no Unicode support at all -- and gfxlib2 declares its character set as CP437, so each code unit maps through a CP437 table:

```freebasic
dim as ustring u = "<U+0398>"   '' theta
draw string (0, 0), u          '' draws CP437 byte &hE9: theta
```

A character the font has no glyph for draws as '?'. An astral character is one character, so it draws as a single '?' and not two.

The table is fixed rather than locale-based, which is where this departs from the wstring path (that one calls fb_wstr_ConvToA and so draws different glyphs on different machines). A CUSTOM font is also indexed by byte and its codepage is whatever its author's bitmap says -- if you need exact control over the indices, pass a STRING, whose bytes go through untouched.

OPEN ... ENCODING is honoured. A file opened with ENCODING "utf8", "utf16" or "utf32" is written and read in that encoding, byte-for-byte the same as a WSTRING would produce; PRINT #, WRITE #, LINE INPUT # and INPUT # all follow it. Without ENCODING a ustring file is UTF-8, as above.

LINE INPUT # has no line-length limit in either case.

## What Is Supported

Everything below is implemented and covered by tests (tests/ustring\_\*.bas and tests/ustr\_\*.c -- see tests/BASELINE.md).

Operators and intrinsics -- assignment, concatenation (+, &, +=), comparison, LEN, \[\] indexing, ASC, WCHR, LEFT, RIGHT, MID (function AND statement), INSTR, INSTRREV, TRIM/LTRIM/RTRIM (including the ANY and EX forms), UCASE, LCASE, SPACE, STRING, LSET, RSET, SWAP, VAL, STR, WSTR, HEX, FORMAT.

Language -- VAR inference, SELECT CASE, IIF, BYREF/BYVAL parameters with copy-back, function results (including BYREF returns and fixed-length results), overload resolution, UDT fields, LET/property/operator overloads (including `operator cast() as ustring`), arrays (multi-dimensional, SHARED, UDT-nested, REDIM PRESERVE, ERASE), COMMON, WITH, type aliases, static locals, STRPTR, VARPTR, SIZEOF, ustring ptr, variadics.

Not supported: `cast( ustring, x )` is refused with TKO0756, since a cast names a sized string type such as `zstring * n`. Assign instead (`dim as ustring u = s`), or convert a number with `STR`.

A ustring cannot be a member of a UNION (TKO0998): it has to be constructed and destroyed, and a union runs neither.

I/O -- PRINT, WRITE, PRINT #, WRITE #, LINE INPUT, LINE INPUT #, INPUT, INPUT #, PRINT USING, PUT/GET, OPEN ... ENCODING, READ/DATA, DRAW STRING.

The package `std/strings` library serves USTRING too -- see [String Library](Category-String-Library).

## Constants

`CONST G AS USTRING = "hé"` declares a ustring constant. It reads as a USTRING everywhere a ustring variable does: PRINT, WRITE and PRINT USING, the string intrinsics, a BYVAL or BYREF USTRING argument, and a WSTRING destination. `LEN( G )` counts UTF-16 units, so it is 2 here, not the 3 bytes the source spells it in.

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
