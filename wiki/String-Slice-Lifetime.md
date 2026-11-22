[Home](Home) › [All Categories](Categories) › [String Slices](Category-String-Slices) › **String Slice Lifetime**

# String Slice Lifetime

A [slice](Category-String-Slices) points into text it does not own. If that text is freed, or moved to a bigger block when its string grows, the slice reads whatever is in the old memory now. tiko rules this out in three layers:

1. **Where a slice may live.** A slice is a *non-escaping* type: it can be a local, a parameter or a result, and nothing that could outlive the text it points into.
2. **Where it came from.** Every slice has an origin — the string it borrows — and the compiler refuses a binding or a return that would outlast it.
3. **What happens to the source meanwhile.** Within a procedure, a string cannot be reassigned or grown while a slice of it is still to be read. Across procedures, `-exx` checks each read of a slice against its string.

No annotations are written for any of this. The rules are the same whether the program has one slice or a thousand, and a program with none pays nothing for them.

## Where A Slice May Live

| Allowed | Refused |
| --- | --- |
| a local variable, in any block | `shared`, `static`, `common`, `extern` (`TKO1054`) |
| a module-level `dim` that is not `shared` (a local of the main program) | an array element, static or dynamic (`TKO1054`) |
| a parameter, `byval` or `byref` | a type argument: `Array( of slice )` (`TKO1054`) |
| a function result (see [Returning A Slice](#returning-a-slice)) | allocated with `new` (`TKO1054`) |
| a field of a type declared `as view` | a field of an ordinary type (`TKO1055`) |
| `@v` passed straight to a call | `@v` stored anywhere (`TKO1056`) |
| | captured by a lambda or by `spawn` (`TKO1060`) |

```freebasic
dim shared as uslice g          ' TKO1054: a uslice cannot be shared
dim as uslice arr( 3 )          ' TKO1054: a uslice cannot be an array element
```

## View Types

A type may hold slices if it is declared a **view**:

```freebasic
type Lexer as view
    src as const uslice
    pos as integer
end type
```

`as view` ends the line; the body is an ordinary type body. A view follows every rule a slice does — where it may live, its origin, returns — so a `Lexer` cannot be `shared`, an array element or a field of an ordinary type. A type that holds a view is itself a view and must say so:

```freebasic
type Holder
    lx as Lexer             ' TKO1055: type 'holder' holds slice field 'lx' and must be declared 'as view'
end type
```

A view type declared in a module stays a view for every program that imports it. Generic view types are not supported.

`std/strings`' [SplitSlices](Modern-String-SplitSlices) returns a view: the iterator holds the text and the separator, and hands out one part at a time, because an array of slices is not allowed.

## Origins

The origin of a slice is the storage its text ultimately belongs to, found by following the expression back through fields, indexes, parentheses and further slicing:

| Origin | Lives | Examples |
| --- | --- | --- |
| **program** | as long as the program | a literal, a named constant, a `shared`, `static`, `extern` or `common` string, anything reached through a pointer |
| **caller** | longer than this call | a `byref` string parameter, a slice or view parameter, a field reached through `this` |
| **local** | the block it is declared in | a local string; a `byval` string parameter, which is the call's own copy |
| **temporary** | this statement | a function result, a concatenation, a string converted for a slice parameter |

A slice variable's origin is the shortest origin of everything bound into it.

**A slice cannot be kept longer than its origin** (`TKO1057`):

```freebasic
dim as uslice v
if ready then
    dim as ustring inner = "abc"
    v = inner[0 to 1]       ' TKO1057: 'v' outlives 'inner', which this slice borrows from
end if
```

**A slice of a temporary is used in its statement and nowhere else** (`TKO1058`). Printing it, passing it to a call, or comparing it are all fine:

```freebasic
print (a & b)[0 to 3]                        ' fine
dim as const uslice v = (a & b)[0 to 3]      ' TKO1058: this slice borrows from a temporary that ends with the statement
```

`iif` over two slices takes the shorter-lived origin of the two arms.

## Returning A Slice

A function may return a slice whose origin is **caller** or **program**. A slice of a local, or of a `byval` parameter, is `TKO1059`:

```freebasic
function FirstWord( byref s as const ustring ) as const uslice   ' fine: the caller's text
    return s[0 to 2]
end function

function Bad( byval s as ustring ) as const uslice
    return s[0 to 2]        ' TKO1059: cannot return a slice of local 's'
end function
```

**At the call site**, the result is taken to borrow from **every** string passed `byref`, every slice or view argument, and `this` — whichever lives shortest. Nothing in the declaration says which argument the result really comes from, so the compiler assumes the worst. A call like `FirstWord( a & b )` returns a slice of a temporary: it can be printed in the same statement, not kept.

A `byref` slice parameter, or a field of a `byref` view parameter or of `this`, may be given only a slice whose origin is caller or program (`TKO1061`). Otherwise a procedure could leave a slice of its own local in the caller's variable.

## The Source Lock

Between the line that makes a slice and the last line that reads it, the string it borrows from cannot be changed in any way that might move or shrink its text (`TKO1062`):

```freebasic
dim as ustring s = "hello"
dim as uslice v = s[0 to 2]
s &= " world"               ' TKO1062: 's' cannot be changed while slice 'v' borrows from it (last used at line 4)
print v
```

Swap the last two lines and the program compiles: `v` has been read for the last time before `s` grows. Pointing `v` at other text also ends the lock on `s`.

| Moves the text: refused while borrowed | Leaves it in place: allowed |
| --- | --- |
| assignment, `let`, `&=`, `+=` and the other compound forms | `s[i] = x` |
| `swap` | the `Mid` statement, `LSet`, `RSet` |
| `input`, `line input` into it | writes through a writable slice of it |
| passing it `byref` to a parameter that is not `const` | reading it, passing it `byval`, `byref as const`, or as a slice |

An **array slice** (`span( of T )`, [Array Slices](Category-Array-Slices), after tiko 0.1.5) follows every rule on this page. Its own lock is on a **dynamic array**: `redim`, `redim preserve`, `erase`, and passing the array to a `b( )` parameter are refused while a span of it is still to be read; a fixed array is never locked. A string slice of an element of a dynamic string array, `q( 1 )[0 to 2]`, is locked by the same four.

**Loops**: a slice read in a loop body is read again by the next iteration, so a write later in the same body counts as before that read — `TKO1062`, unless the slice is pointed at new text first.

The lock is worked out within one procedure, in source order:

- **Branches** are taken as if all of them run. A write in a `then` arm followed by a use in the `else` arm is reported, though no run does both.
- **`goto` and `gosub`** jumping backwards are not followed as loops are.
- **Another name for the same string** — a pointer, a second `byref` parameter that refers to it, a `shared` string changed by a procedure this one calls — is not seen. That is what `-exx` is for.

## The `-exx` Check

Every slice of a `string` or `ustring` remembers which string it came from. Under `-exx` (or `-earray`), each read of such a slice — `v[i]`, printing it, comparing it, converting it, slicing it again, the start of a `for each` over it — first checks that its text still lies inside that string's current text. If the string has moved or shrunk, the program stops with runtime error 6 at that line; an `on error` handler can catch it as any error 6. `v[i]` is also checked against the slice's own length.

```freebasic
#cmdline "-exx"

dim shared as ustring logText

sub Note( byref msg as const ustring )
    logText &= msg & " -- long enough to move the text elsewhere"
end sub

sub Report( )
    logText = "start"
    dim as const uslice head = logText[0 to 4]
    Note( "grown" )          ' changes logText; this procedure cannot see that
    print head               ' stops here: runtime error 6
end sub

Report( )
```

Without `-exx` nothing is checked and nothing is slower: the word the check uses is filled in and never read. The same program then reads freed memory, and may well print `start`.

## What Is Not Caught

1. **Pointer origins.** A slice of a `zstring ptr` or `wstring ptr` is as valid as the pointer. It still cannot escape, but whether the memory is alive is the program's business.
2. **Changes made in another procedure, without `-exx`.**
3. **The same block again.** If a procedure reassigns the string and the allocator happens to hand back the same block at the same length, the `-exx` check passes and the slice reads the new text. That is memory-safe, but it is not the old text.
4. **Fixed buffers rewritten in place.** A `zstring * N` given a shorter value keeps its storage; a slice past the new NUL reads the old bytes, inside live memory.
5. **Raw pointers to a slice's text**, taken through a pointer cast, escape every rule, as raw pointers always do.

## Errors

| Id | Message |
| --- | --- |
| `TKO1054` | a ‹type› cannot be shared / static / common / extern / an array element / a generic type argument / allocated with new |
| `TKO1055` | type '‹name›' holds slice field '‹field›' and must be declared 'as view' |
| `TKO1056` | cannot take the address of slice '‹name›' except to pass it |
| `TKO1057` | '‹slice›' outlives '‹string›', which this slice borrows from |
| `TKO1058` | this slice borrows from a temporary that ends with the statement |
| `TKO1059` | cannot return a slice of local '‹name›' / of a temporary |
| `TKO1060` | a lambda / 'spawn' cannot capture slice '‹name›' |
| `TKO1061` | a slice stored through byref parameter '‹name›' must outlive the call |
| `TKO1062` | '‹string›' cannot be changed while slice '‹slice›' borrows from it (last used at line ‹n›) |

See also: [String Slices](Category-String-Slices), [Compiler Error Messages](Compiler-Error-Messages).

---

[Home](Home) · [Keyword Index](Keyword-Index)
