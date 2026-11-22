[Home](Home) › [All Categories](Categories) › **Result**

# Result

A **Result** is the answer from something that can fail. It holds exactly one of two things: the **value** you asked for, or a **reason** why it could not be produced -- never both, and never neither. A `Result( of int32, ustring )` holds either a number or a piece of text saying what went wrong.

Think of taking a coat to a tailor: it comes back either altered, or with a note pinned to it -- "fabric too thin to take in". Either way you get something back, and when the alteration is missing, the note says why.

You make a successful one with `Ok( ... )( value )` and a failed one with `Fail( ... )( reason )`. Whoever receives it asks `IsOk( )`, then reads `Value( )` on success or `Failure( )` on failure; `ValueOr( fallback )` gives the value, or the fallback when you do not need to know why. Because the reason travels inside the return value, a failure cannot be mistaken for a value.

Use a Result when the caller needs to know *why* something failed -- a file that would not open, text that would not parse. When "there is nothing" needs no explanation, use an [Optional](Category-Optional) instead.

The example below parses text into a number, and prints either the number or the reason it could not:

```freebasic
#import "std/outcome"
using outcome

type ParseResult as Result( of int32, ustring )

function Parse( byref s as ustring ) as ParseResult
    if( len( s ) = 0 ) then
        return Fail( of int32, ustring )( "empty" )
    end if
    ...
    return Ok( of int32, ustring )( n )
end function

dim r as ParseResult = Parse( input_ )

if( r.IsOk( ) ) then
    print r.Value( )
else
    print "cannot parse: "; r.Failure( )
end if
```

## Why It Exists

Without Result, the error is not part of the return type. It lives in a global status code, does not participate in the type system, and is trivially ignored:

```freebasic
dim v as int32 = Parse( s )           ' did it work?  ask err, maybe
if( err <> 0 ) then
```

Result puts the reason IN THE RETURN TYPE, where it has a name and cannot be read by accident as a value.

## Result OR OPTIONAL?

```freebasic
Optional( of T )        "nothing is here"
Result( of T, E )       "nothing is here, AND this is why"
```

Use Optional when the absence needs no explanation -- a lookup that missed, a list that was empty. Use Result when it does. A Result whose E is never inspected should have been an Optional.

## Members

```freebasic
IsOk( ) as boolean                        O(1)
Value( ) byref as T                       O(1)   RAISES if failed
Failure( ) byref as E                     O(1)   RAISES if successful
ValueOr( byref dflt as T ) byref as T     O(1)   never raises
```

and two FREE PROCEDURES, not constructors:

```freebasic
Ok( of T, E )( v ) as Result( of T, E )
Fail( of T, E )( e ) as Result( of T, E )
```

There is deliberately no operator '=', no comparison, no ToString and no GetIterator. See WHY THERE ARE SO FEW MEMBERS below.

There is no FailureOr( ): a default reason for a success is not a thing anyone wants.

## A DEFAULT-CONSTRUCTED Result Is A Failure

```freebasic
dim r as Result( of int32, ustring )   ' failed, with an empty reason
```

This is the most important property of the type, and the choice is not arbitrary. A Result that nobody has set must not read as success, or every forgotten assignment becomes a silent Ok. There is no third state.

## Both Type Arguments Must Be Written Out

Inference reads parameter positions only, and Ok( ) mentions just T while Fail( ) mentions just E, so neither call can infer the pair:

```freebasic
return Ok( of int32, ustring )( 3L )
return Fail( of int32, ustring )( "not a number" )
```

That is more ceremony than Optional's Some( x ), and it is the reason the pairing is normally named once:

```freebasic
type ParseResult as Result( of int32, ustring )
```

The usual inference rule still applies inside: an untyped integer literal is an INTEGER, so Ok( of long, ustring )( 3 ) is a mismatch and Ok( ... )( 3L ) is not.

## Reading The Wrong Side Raises

Value( ) on a failure and Failure( ) on a success BOTH raise FB_RTERROR_ILLEGALFUNCTIONCALL. With no handler installed the program stops, naming the line that made the call:

```freebasic
Aborting due to runtime error 1 (illegal function call) at line 9 of demo.tiko(), Value( ) of a failed Result
```

The symmetry is deliberate. Asking why something failed when it did not fail is the same class of mistake as reading a value that is not there, and it is the one a one-sided implementation would let through silently.

IsOk( ) is the guard and costs nothing. ValueOr( ) is the branch-free alternative for the value side and never raises. Where the compiler can see that no IsOk( ) check covers a Value( ) or Failure( ) on every path to it, it warns, `TKO1150` (see [Optional](Category-Optional#empty-access-raises) for what it follows).

Both accessors return BYREF, so they can be written through:

```freebasic
r.Value( ) = 3
dim byref as ustring f = r.Failure( )
```

and ValueOr( ) aliases either the stored value or the CALLER'S default, so passing a temporary gives a reference that dies at the end of the statement -- the same hazard as any byref return, not a Result one.

## Zero Is A Value

```freebasic
Ok( of int32, ustring )( 0L )          ' a success whose value is 0
Fail( of int32, ustring )( "" )        ' a failure whose reason is ""
```

Neither collapses into the other. Every "0 means error" or "empty means failed" convention Result replaces gets one of these wrong.

## It Is NOT A Sum Type

Result is a T and an E and a boolean -- three fields, not a tagged union:

```freebasic
sizeof( Result( of T, E ) ) >= sizeof( T ) + sizeof( E ) + sizeof( boolean )
```

Consequences, all of them observable:

- BOTH T and E must be default-constructible, and both default constructors

```freebasic
run for every Result. A T or an E declaring any constructor suppresses the
implicit default one and is refused:

    error 183: TYPE or CLASS has no default constructor
      in instantiation of 'Result( of long, NODEFAULTCTOR )'
```

- Both slots are destroyed, always -- not just the active one. A union-based

```freebasic
implementation that destroyed only the live side would leak.
```

- The slots are independent, so T and E may be the SAME type.

```freebasic
Result( of ustring, ustring ) -- a parsed word, or a message saying why not --
is legal and keeps the two apart.
```

This is the price of having no sum types in the language.

## Why There Are So Few Members

Not minimalism. Every member of a generic is instantiated whether it is called or not, so a member needing '=' on T or E would make the WHOLE TYPE unusable for a T or an E without one -- the same rule that forced Array's Sort, IndexOf and Contains to become free procedures.

So the members here use only default construction, copy and destruction, and Result instantiates over anything with those, including containers, which have no '=':

```freebasic
dim r as Result( of Array( of int32 ), ustring )           ' fine
dim s as Result( of int32, Array( of int32 ) )              ' fine
dim n as Result( of Result( of int32, ustring ), ustring ) ' fine
```

## Library Only

No compiler change went into this, and several things were deliberately NOT done:

```freebasic
no '?' operator                     ' propagating early-return
no must-use diagnostic              ' see below
no sum type underneath              ' see above
no implicit conversion to boolean   ' 'if( r ) then' does not compile
```

IGNORING A RESULT STAYS A CONVENTION. Nothing stops this:

```freebasic
Parse( s )                          ' return value dropped, silently
```

A must-use diagnostic needs a compiler change and is not part of this. What the type buys is that the failure has a name and a type -- not that you are forced to look at it. That is the honest limit of a library-only version.

## Ownership AND Copying

Copy and assignment are DEEP, because both slots are stored by value and tiko's value semantics do the work. The two Results are independent afterwards in BOTH directions, in either state.

A Result( of T ptr, ... ) copies the POINTER. There are no smart pointers.

## A Naming Trap

The failure field is named 'f', not the obvious 'e'. tiko identifiers are case-insensitive, so a field named 'e' IS the type parameter 'E', and the instantiation fails with a misleading

```freebasic
error 14: Expected identifier, found 'E'
```

The same collision bites CALLERS, and much more sharply: a variable named 'e' anywhere in scope at the point Result is instantiated breaks that instantiation with the same error. This is a defect in the generics implementation, not a property of Result -- the type parameter is being resolved against the instantiation site's scope -- and it applies to 't' and Array( of T ) and every other shipped generic equally. Until it is fixed, avoid single-letter variables named after a type parameter near a generic instantiation.

Source: pkg/std/outcome/result.tiko

## Tests

src/tests/generics/container-result.bas is exhaustive: every member, both states, both free constructors, all four assignment transitions, self-assignment, slot independence, copy independence in both directions, byref mutation through Value( ) and Failure( ), distinct T and E in both orders, T = E, a container in each position and in both at once, a nested Result, a Result as a return value, and destructor balance over BOTH slots -- asserted for the mixed case and for the never-set case separately.

src/tests/generics/result-value-on-failure.bas and result-failure-on-ok.bas are COMPILE_AND_RUN_FAIL tests pinning the two raising paths. They are separate modules because each raise ends the process.

src/tests/generics/fail-result-nodefaultctor.bas pins the diagnostic for a type with no default constructor in the E position.

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Errors and missing values](Functions-Errors) lists them beside the rest of the area.

### Return a value or the reason it failed

| Function | What it does | From |
|---|---|---|
| [Result](Modern-Result-Result) | Holds either a value or the reason it could not be made; a new one counts as failed. | `std/outcome` |
| [Ok](Modern-Result-Ok) | Returns a successful Result holding the value; both types must be written out. | `std/outcome` |
| [Fail](Modern-Result-Fail) | Returns a failed Result holding the reason; both types must be written out. | `std/outcome` |
| [Result.IsOk](Modern-Result-IsOk) | Returns true if the Result holds a value rather than a reason for failure. | `std/outcome` |
| [Result.Value](Modern-Result-Value) | Returns the value by reference; raises an error if the Result failed. | `std/outcome` |
| [Result.Failure](Modern-Result-Failure) | Returns the reason by reference; raises an error if the Result succeeded. | `std/outcome` |
| [Result.ValueOr](Modern-Result-ValueOr) | Returns the value, or the fallback you pass if the Result failed. | `std/outcome` |

### Return a value that may be missing

| Function | What it does | From |
|---|---|---|
| [Optional](Modern-Result-Optional) | Holds one value or nothing at all; a new one is empty. | `std/outcome` |

<!-- finder:end -->

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
