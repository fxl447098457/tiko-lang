[Home](Home) › [All Categories](Categories) › **String Slices**

# String Slices

```freebasic
#import "std/strings"

dim as ustring s = "hello, world"

dim as uslice word = s[7 to 11]     ' "world": units 7 to 11, no copy
print word, len( word )             ' world  5
print s[0 to 4]                     ' hello
print word[1 to 3]                  ' orl -- a slice of a slice

word[0] = asc( "W" )                ' writes into s
print s                             ' hello, World

dim as ustring kept = word          ' an owned copy
print strings.TrimSpace( "  padded  " )       ' padded
for each part as const slice in strings.SplitSlices( "a,b,c", "," )
    print part                                ' a / b / c
next
```

A **slice** names part of a string where it already is. Making one allocates nothing and copies nothing: it is a pointer into the string's text and a length. It prints, compares and joins like the text it names, and `len` on it is a single read.

## Why It Exists

`Mid`, `Left`, `Right` and the `std/strings` functions that return text all build a new string. A tokenizer, a splitter or a parser that takes a line apart pays one allocation and one copy for every piece, though most pieces are looked at once and dropped. A slice is the piece without the copy, and the copy is made only when the program decides to keep it — by assigning the slice to a string.

A view into memory it does not own is also the classic way to read freed memory. The compiler tracks where every slice came from and refuses the programs where its text could go away or move while it is in use; [String Slice Lifetime](String-Slice-Lifetime) has the rules. What a single procedure cannot show is checked at run time under `-exx`.

## The Types

| Type | Sliced from | Unit |
| --- | --- | --- |
| `uslice` | `ustring`, `ustring * N` | a UTF-16 code unit (`ushort`), on every target |
| `slice` | `string`, `string * N`, `zstring * N`, `zstring ptr` | a byte (`ubyte`) |
| `wslice` | `wstring * N`, `wstring ptr` | a `wchar_t`: 2 bytes on Windows, 4 on Linux and macOS |

The three are predeclared types, not keywords. A program that declares its own `slice`, `uslice` or `wslice` — a variable, a type, a parameter — keeps it, and compiles as it did.

A slice is three pointer-sized words. It passes and returns by value like any small type.

## Syntax

```freebasic
s[lo to hi]       ' units lo to hi, both included, counted from 0
```

`s[i]` already reads one unit of a string, counting from 0; `s[lo to hi]` extends it to a range. `s[0 to 4]` is the same five units as `Mid( s, 1, 5 )`, without the copy.

- **Empty**: `s[lo to lo - 1]` has no units. `s[0 to -1]` is legal on an empty string, so `s[0 to len( s ) - 1]` is always the whole string.
- **A slice of a slice** — `v[1 to 3]` — is a smaller view of the same text.
- **A literal takes no `[ ]`**. Pass it where a `const` slice is wanted instead (see [Parameters](#parameters)).

From a pointer:

```freebasic
slice( p )        ' p's text up to its NUL
slice( p, n )     ' n units, no scan
p[lo to hi]       ' no scan: hi is trusted
```

`p` is a `zstring ptr` for `slice`, a `wstring ptr` for `wslice`. Slicing any other pointer, or a type that is not a string, is `TKO1050`.

## What A Slice Can Reach

A slice covers the source's **current** length:

| Source | Extent |
| --- | --- |
| `string`, `ustring` | its `Len` |
| `string * N` | N, padding included |
| `zstring * N`, `ustring * N`, `wstring * N` | up to the first NUL, the same as `Len` |
| `zstring ptr`, `wstring ptr` | whatever `hi` or `n` says; `slice( p )` scans to the NUL |

**Making a slice is always checked**, in every build: `lo` and `hi` must satisfy `0 <= lo <= hi + 1 <= len`. A violation is runtime error 6, naming the source and the allowed range:

```
Aborting due to runtime error 6 (out of bounds array access) at line 3 of prog.tiko(),
'S' accessed with invalid index = 9, must be between -1 and 4
```

Bounds the compiler can see are wrong — `5 to 2`, a negative `lo`, past the end of a `string * 4` — are `TKO1051` before the program runs.

**Reading `v[i]` is checked under `-exx`** (or `-earray`), as an array subscript is. Without it, an index past the end reads whatever follows.

Bounds count code units. A slice may cut a UTF-8 sequence or a UTF-16 surrogate pair in two; nothing is reported, and the units are what they are.

## Writing Through A Slice

A slice is as writable as its source:

| Source | Slice |
| --- | --- |
| a variable, a `byref` parameter, a field | writable: `v[i] = x` changes the source in place |
| a `const` variable or parameter, a literal, a temporary | `const` |
| `zstring ptr` / `const zstring ptr` | writable / `const` |

A writable slice converts to a `const` one wherever one is wanted. The other way is `TKO1052`. Writing through a `const` slice is the ordinary `TKO0617`.

`const` qualifies the **text**, not the variable: a `const uslice` variable can be declared without a value and pointed at other text later, as a `const zstring ptr` can.

A slice has a fixed length. Nothing done through it can grow or shrink its source.

## What A Slice Does

| Operation | Result |
| --- | --- |
| `len( v )` | its length in code units |
| `v[i]` | one code unit, a number; assignable if the slice is writable |
| `v[lo to hi]` | a slice of the same text |
| `=` `<>` `<` `>` `<=` `>=` | compare with a slice or a string of the same width, unit by unit |
| `&` | an owned string |
| `print`, `write #` | the text |
| `for each c in v` | each code unit in turn |
| `select case v` | compares at run time; `select case as const` is refused |
| `iif( c, a, b )` | two slice arms give a slice; a slice and a string give an owned string |
| `dim u as ustring = v`, a string parameter | an owned copy |
| `cast( string, v )` on a `slice`, `cast( ustring, v )` on a `uslice` | an owned copy; the other width is refused |

`ustring( v )` and `string( v )` are not conversions; assignment or `cast` is the way back to an owned string.

A slice has no NUL at its end, so it does not convert to a `zstring ptr` or `byref as zstring` parameter (`TKO0698`). To pass one to C, ask for the copy: `cast( string, v )` is terminated and lasts until the end of the statement.

## Parameters

A parameter `byval v as const uslice` accepts any string:

| Argument | What happens |
| --- | --- |
| a `ustring` or `ustring * N` | viewed in place, no copy |
| a `uslice` | passed as it is |
| a `string`, `zstring`, `wstring` or a literal | converted once, into a temporary that lasts until the end of the statement |

So one `const` slice parameter serves every string type, and a function written that way never copies an argument that is already the right width.

A **writable** slice parameter, `byval v as uslice`, takes only a variable of its own width or a writable slice: writes into a converted copy would be lost. Anything else is `TKO1053`; a `const` source is `TKO1052`.

```freebasic
sub Upper( byval v as uslice )
    for i as integer = 0 to len( v ) - 1
        if v[i] >= 97 andalso v[i] <= 122 then v[i] -= 32
    next
end sub

dim as ustring s = "make me loud"
Upper( s[5 to 6] )
print s                 ' make ME loud
```

When a function takes two slices of different widths, a `ustring` and a plain literal can match two overloads equally well, and the call is ambiguous (`TKO0660`). Passing `s[0 to len( s ) - 1]` instead of `s` settles it.

## Standard Library

`#import "std/strings"` adds functions over all three slice types. Every parameter is a `const` slice, so any string can be passed. Positions count from 0, as `s[i]` does, and -1 means not found. Nothing in them allocates.

| Function | Does |
| --- | --- |
| [Find](Modern-String-Find) | position of the first match at or after a start, or -1 |
| [Equals](Modern-String-Equals) | same code units, optionally ignoring the case of A to Z |
| [StartsWith](Modern-String-StartsWith), [EndsWith](Modern-String-EndsWith) | prefix and suffix tests, slice overloads |
| [TrimStart](Modern-String-TrimStart), [TrimEnd](Modern-String-TrimEnd), [TrimSpace](Modern-String-TrimSpace) | a slice of the argument without its spaces, tabs, CRs and LFs |
| [SplitSlices](Modern-String-SplitSlices) | each part between separators, one at a time, for `for each` |

The other `std/strings` functions take strings, count from 1 and return 0 for not found; see [String Library](Category-String-Library).

## Lifetime In Brief

| Rule | Error |
| --- | --- |
| A slice lives in a local, a parameter or a result — not `shared`, `static`, an array or container element, or `new` | `TKO1054` |
| A type holding a slice is declared `type T as view`, and follows the same rules | `TKO1055` |
| A slice's address is taken only to pass it | `TKO1056` |
| A slice is not kept past the block its source belongs to | `TKO1057` |
| A slice of a temporary is used in its statement, not kept | `TKO1058` |
| A function returns a slice only of its caller's text | `TKO1059` |
| A lambda or `spawn` does not capture a slice | `TKO1060` |
| A `byref` slice parameter is given only text that outlives the call | `TKO1061` |
| A string is not reassigned, appended to or otherwise moved while a slice of it is still to be read | `TKO1062` |

Details, and what is checked only under `-exx`: [String Slice Lifetime](String-Slice-Lifetime).

## Errors

| Id | When |
| --- | --- |
| `TKO1050` | the value cannot be sliced: it is not a string, a slice or a `zstring` / `wstring` pointer |
| `TKO1051` | constant bounds that are outside the source |
| `TKO1052` | a `const` slice where a writable one is needed |
| `TKO1053` | a writable slice parameter given something other than a variable of its width |
| `TKO1054` – `TKO1062` | the lifetime rules above |

## Known Limits

- **A slice of a `zstring ptr` or `wstring ptr` is as valid as the pointer.** The storage rules still apply, but nothing checks that the memory is alive.
- **There are no slices of arrays or of other types.** Slices are for strings.

See also: [String Slice Lifetime](String-Slice-Lifetime), [UString](Category-UString), [String Library](Category-String-Library), [For Each](Category-For-Each).

---

[Home](Home) · [Keyword Index](Keyword-Index)
