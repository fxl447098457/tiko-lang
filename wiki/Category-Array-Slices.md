[Home](Home) › [All Categories](Categories) › **Array Slices**

# Array Slices

```freebasic
dim as int32 a( 1 to 6 ) = { 10, 20, 30, 40, 50, 60 }

dim as span( of int32 ) v = a( 2 to 4 )   ' elements 2 to 4 of a, no copy
print len( v ), v( 0 )                    ' 3  20 -- a span counts from 0
v( 1 ) = 99                               ' writes a( 3 )

for each x as int32 in v( 1 to 2 )        ' a span of a span
    print x                               ' 99 / 40
next

sub DoubleAll( b( ) as int32 )            ' an ordinary array procedure
    for i as int32 = lbound( b ) to ubound( b )
        b( i ) *= 2
    next
end sub
DoubleAll( a( 5 to 6 ) )                  ' a span where b( ) is wanted
```

A **span** names part of a one-dimensional array where its elements already are. Making one allocates nothing and copies nothing: it is a pointer to the first element and a count. Writing through it writes the array.

## Why It Exists

A procedure that works on part of an array has had to take the whole array plus a first and last index, or have the part copied into a new array first. A span is the part itself: one parameter, any run of any array, no copy.

A view into memory it does not own is also the classic way to read freed memory. A span follows the same rules as a [string slice](Category-String-Slices): the compiler tracks where it came from and refuses programs where the array could go away or move while the span is in use; what one procedure cannot see is checked at run time under `-exx`.

## The Type

`span( of T )` is a span of `T` elements — any element type: numbers, strings, pointers, your own types. It is three pointer-sized words and passes and returns by value.

`span` is not a keyword. A program that declares its own **type** called `span` keeps it (and loses `span( of T )`); a variable, parameter or procedure called `span` does not hide it. A typedef is looked through, so `span( of long )` and `span( of int32 )` are the same type.

## Syntax

```freebasic
a( lo to hi )         ' elements lo to hi of a, both included, in a's own indices
v( i )                ' one element, counted from 0
v( lo to hi )         ' a span of a span, counted from 0
span( of T )( p, n )  ' n elements from a T ptr
```

An array is indexed `a( i )`, so it is sliced `a( lo to hi )`; a string is indexed `s[i]`, so it is sliced `s[lo to hi]`. Each takes its own brackets: `a[1 to 2]` on an array is `TKO1074`, and `s(1 to 2)` on a string is `TKO1070`, each naming the right form.

The source may be a fixed array, a dynamic array or an `a( )` parameter, of one dimension (`TKO1069` for more). A dynamic array whose rank was never written is checked when the span is made.

**A span counts from 0**, whatever its array does: `lbound( v )` is 0 and `ubound( v )` is `len( v ) - 1`. So `a( 2 to 4 )( 0 )` is `a( 2 )`, and a procedure taking a span never needs the source's bounds.

- **Empty**: `a( lo to lo - 1 )` has no elements, so `a( lbound( a ) to ubound( a ) )` is always the whole array — an empty one included.
- **`lbound( v, 0 )`** is 1 and `ubound( v, 0 )` is 1 (one dimension); dimension 2 and beyond give 0 and -1, as they do for a one-dimensional array.

## Bounds

**Making a span is always checked**, in every build: `lbound <= lo <= hi + 1 <= ubound + 1`. A violation is runtime error 6, in the array's own indices:

```
Aborting due to runtime error 6 (out of bounds array access) at line 5 of prog.tiko(),
'A' accessed with invalid index = 9, must be between 0 and 8
```

Bounds the compiler can see are wrong — past the end of a fixed array, `5 to 3` — are `TKO1071` before the program runs.

**Reading `v( i )` is checked under `-exx`** (or `-earray`), as an array subscript is.

## Writing Through A Span

A span is as writable as its array. A span of a `const` array, or of a `const` span, is a `const span( of T )`; `span( of const T )` means the same. A writable span converts to a `const` one wherever one is wanted; the other way is `TKO1052`, and writing through a `const` span is `TKO0617`. `const` qualifies the elements: a `const` span variable may be pointed at another run later.

## What A Span Does

| Operation | Result |
| --- | --- |
| `len( v )` | its element count |
| `v( i )` | one element, an lvalue of `T`: read it, assign it, pass it `byref`, reach its fields |
| `v( lo to hi )` | a span of the same elements |
| `lbound( v )`, `ubound( v )` | 0 and `len( v ) - 1` |
| `for each x in v`, `for each byref x in v` | each element in turn; `byref` binds the array's own element |
| a `byval` / `byref` `span( of T )` parameter, a function result | passed and returned by value |
| an argument for `b( ) as T` | the procedure sees an array indexed 0 to `len - 1` over the span's elements |
| `iif( c, v, w )` | a span |

A span does not print, compare, or convert to an array or a string. `v( )` is `TKO1072`: a span takes exactly one index.

## A Span For An Array Parameter

Any procedure that takes `b( ) as T` takes a `span( of T )`. It receives a fixed-length, one-dimensional array over the span's elements, indexed from 0, so its `lbound`/`ubound` loops work unchanged and its writes land in the source array.

- The element type must be `T` exactly; otherwise, or for a parameter of two or more dimensions, `TKO0687`. A `const` span needs a `b( ) as const T` (`TKO1052`).
- When an overload takes `byval v as span( of T )` and another `b( ) as T`, a span argument picks the span one; `f( a( ) )` still picks the array one.
- **`redim` in the procedure is runtime error 1** (illegal function call), exactly as for a fixed array passed to `a( )`: it aborts under `-e`/`-exx` and otherwise only sets `Err`.
- **`erase` in the procedure clears the span's elements in the source array**, as `erase` clears a fixed array.

## From A Pointer

`span( of T )( p, n )` is `n` elements starting at `p`, a `T ptr` or an `any ptr` — for a C buffer or memory from `allocate`. A pointer to `const T` makes a `span( of const T )` (`TKO1052` otherwise); anything else is `TKO1073`. Nothing checks that the memory is alive or holds `n` elements: the span is as valid as the pointer.

## Lifetime

The rules of [String Slice Lifetime](String-Slice-Lifetime) apply to spans word for word:

| Rule | Error |
| --- | --- |
| A span lives in a local, a parameter or a result — not `shared`, `static`, an array element, `new`, or a span of slices or spans | `TKO1054` |
| A type holding a span is declared `type T as view` | `TKO1055` |
| A span is not kept past the block its array belongs to | `TKO1057` |
| A function returns a span only of what its caller handed it — a span parameter, a `byref` or `b( )` parameter | `TKO1059` |
| A lambda or `spawn` does not capture a span | `TKO1060` |

And one rule is the array's own. A **dynamic array** moves when it is `redim`med, `redim preserve`d or `erase`d. While a span of it is still to be used, in the same procedure, each of these is `TKO1062` — and so is passing the array to a `b( )` parameter, which may `redim` it:

```freebasic
redim as int32 d( 0 to 3 )
dim as span( of int32 ) v = d( 0 to 1 )
redim preserve d( 0 to 99 )     ' TKO1062: v is used below
print v( 0 )
```

Taking the span again after the `redim` is fine. A **fixed** array never moves and is never locked. The same lock now also covers a string slice of an element of a dynamic string array, `q( 1 )[0 to 2]`.

What crosses a procedure — a procedure given both a span and its array, which then `redim`s the array — is caught under `-exx`: each use of the span checks that it still lies inside the array's current memory, and runtime error 6 stops the program where the span is read. A span of a fixed array or a pointer has nothing to check against.

## Errors

| Id | When |
| --- | --- |
| `TKO1069` | the array has more than one dimension |
| `TKO1070` | `( lo to hi )` on something that is not an array or a span — a string names `[lo to hi]` |
| `TKO1071` | constant bounds outside a fixed array, or below 0 on a span |
| `TKO1072` | a span given other than one index |
| `TKO1073` | `span( of T )( p, n )` without a `T ptr` and a count |
| `TKO1074` | `[lo to hi]` on an array or a span |
| `TKO1052` | a `const` span where a writable one is needed |
| `TKO0687` | a span for `b( ) as T` of another element type, or of more dimensions |
| `TKO1054` – `TKO1062` | the lifetime rules above |

## Known Limits

- **One dimension only.** A row of a two-dimensional array cannot be sliced.
- **No standard-library functions over spans yet.** `containers.Array( of T )` cannot be sliced; its `Data( )` and `Count( )` make a span through `span( of T )( p, n )`.

See also: [String Slices](Category-String-Slices), [String Slice Lifetime](String-Slice-Lifetime), [Array Results](Category-Array-Results), [For Each](Category-For-Each), [Compiler Option: -earray](Compiler-Option-Earray).

---

[Home](Home) · [Keyword Index](Keyword-Index)
