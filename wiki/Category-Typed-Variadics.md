[Home](Home) › [All Categories](Categories) › **Typed Variadics**

# Typed Variadics

```freebasic
function Sum( nums() as const long ... ) as long
    dim as long t
    for each n in nums
        t += n
    next
    return t
end function

print Sum( )                 ' 0
print Sum( 1, 2, 3 )         ' 6

dim as long xs( 0 to 3 ) = { 10, 20, 30, 40 }
print Sum( xs( ) )           ' 100 -- the array itself, no copy
```

An array parameter with `...` after its type takes **any number of arguments, every one of them typed**. The caller writes a plain list; the compiler converts each argument to the element type and packs them into an array; the procedure receives an ordinary array parameter.

## Why It Exists

A procedure that takes "some values" has two ways to say so without this, and both cost something. A C-style `...` takes anything and checks nothing: the callee reads arguments back with `va_arg` and trusts that the caller passed what it expects. An array parameter is checked, but every caller builds the array first, by hand, before every call.

A typed variadic is the second with the first's call syntax. Every argument is converted, or refused, at compile time, exactly as an argument to an ordinary parameter of the element type would be. The callee never sees anything new: `lbound`, `ubound`, `for each` and every other array operation work on it as they do on any array parameter.

## Declaring One

The variadic is an array parameter -- a name with `()`, `as`, the element type -- followed by `...`:

```freebasic
sub LogAll( byref prefix as const ustring, items() as const ustring ... )
    for each item in items
        print prefix; item
    next
end sub

LogAll( "> ", "one", "two", "three" )
```

- It is the **last** parameter (`TKO0973`), and a procedure has at most one.
- It takes **no default value** (`TKO0974`). No arguments already means an empty array.
- `byval` and `byref` do not apply to it, as to any array parameter.
- The element type is any type an array can hold, `const` included. `const T` is the usual choice: the callee reads the list and has no reason to change it.
- A `declare` and its definition must agree on the `...` (`TKO0975`).
- It works on member procedures, `virtual` and `override`, constructors and procedure-pointer types. A pointer to `sub( xs() as long ... )` is a different type from a pointer to `sub( xs() as long )`, and a call through the first packs its arguments.

A C-style `...` -- no name, no type -- keeps its own meaning. The two never appear in one procedure.

## Calling One

With `k` fixed parameters before the variadic, the first `k` arguments bind to them as usual. The rest are the list:

- **None:** the array is empty, `lbound` 0 and `ubound` -1. Nothing is allocated.
- **Several, or one that is not an array:** each is converted to the element type and packed, in order, into a temporary array. The array lives until the end of the statement, like every argument temporary; its elements are destroyed in reverse order.
- **One that is a whole array of the element type:** that array **is** the list. See [Passing an Array](#passing-an-array).

A conversion goes through the element type's **constructors**, as it does for a `byref ... as const T` parameter. That is what makes a type-erasing element type work -- each argument picks the constructor that takes it:

```freebasic
type Item
    as long kind
    as double d
    as ustring s
    declare constructor( byval v as double )
    declare constructor( byref v as const ustring )
end type
constructor Item( byval v as double )
    kind = 1 : d = v
end constructor
constructor Item( byref v as const ustring )
    kind = 2 : s = v
end constructor

sub Show( items() as const Item ... )
    for each byref it in items
        if it.kind = 1 then print it.d else print it.s
    next
end sub

Show( 1.5, "two", 3 )
```

An argument that converts to nothing is `TKO0698`, at that argument. One that reaches two constructors equally is `TKO0660`.

## Passing an Array

A list built at run time is passed as a whole array:

```freebasic
dim as ustring words( 0 to 2 ) = { "a", "b", "c" }
LogAll( "- ", words( ) )
```

It is passed as it stands, with no copy. Its element type must be exactly the variadic's, `const` aside: an array of another type is `TKO0687`, not an element-by-element conversion, which would hide a copy of the whole array behind a call that looks free. Only a single array argument is a spread; an array among other arguments is `TKO0698`, since an array is never one element.

## Overloads

A call that matches an overload **without** packing always beats one that needs it:

```freebasic
sub Pick overload ( byval a as long )
    print "one long"
end sub
sub Pick overload ( xs() as const long ... )
    print "a list"
end sub

Pick( 5 )        ' one long
Pick( 5, 6 )     ' a list
Pick( )          ' a list
```

So adding a variadic overload never changes which procedure an existing call runs. Among candidates that all pack, each packed argument is ranked as an ordinary argument against the element type.

A variadic constructor is not a default constructor: `dim as T x` still needs one that takes no arguments, while `T( )`, written out, calls the variadic one with an empty list.

## See Also

- [strings.Format](Category-Format), which takes its arguments this way
- [Feature Index](Feature-Index)
