[Home](Home) › [All Categories](Categories) › **Optional**

# Optional

An **Optional** is a box that either holds one value or is empty. It is how a function says "here is your answer -- or there is none" without inventing a special value, such as 0 or -1, to mean *nothing*.

Think of a parcel locker: when you open it there is either a parcel inside or there is not, and you can tell which before you reach in. An empty locker is never mistaken for a parcel.

You make a full one with `Some( value )` and an empty one with `None( of T )( )`. Whoever receives it asks `HasValue( )` before taking the value out with `Value( )`, or uses `ValueOr( fallback )`, which gives back the value if there is one and the fallback if not. Because being empty is part of the type, a real value of 0 or -1 can never be confused with "no answer" -- see [Zero Is A Value](#zero-is-a-value).

Use an Optional for a result that may simply be missing: a lookup that finds nothing, a setting that was never given. When the caller also needs to know *why* there is no value, use a [Result](Category-Result) instead.

The example below looks up a year by name. A known name gives a value; an unknown one gives an empty Optional, and `ValueOr` supplies -1 in its place:

```freebasic
#import "std/outcome"
using outcome

function Lookup( byref key as ustring ) as Optional( of int32 )
    if( key = "ada" ) then
        return Some( 1815L )
    end if
    return None( of int32 )( )
end function

dim r as Optional( of int32 ) = Lookup( "ada" )

if( r.HasValue( ) ) then
    print r.Value( )                 ' 1815
end if

dim as int32 unknown = -1
print Lookup( "nobody" ).ValueOr( unknown )      ' -1
```

## Why It Exists

Without Optional there is no way to say "a value that might not be there". Absence is encoded as 0, -1, NULL, an empty string, or an out-parameter boolean -- differently in every library, and indistinguishable from a legitimate result whenever the sentinel is itself a legal value:

```freebasic
function Find( ... ) as int32        ' is -1 "absent", or an index?
if( Find( ... ) = -1 ) then

dim idx as int32 = IndexOf( v, x )    ' 0 could mean "found at 0"
                                     ' or "not found" -- depends on the API
```

Optional puts the absence IN THE TYPE, where it has a name and cannot be confused with a value. It also removes the out-parameter form: 'TryGet( key, byref out ) as boolean' is the shape a function takes only when it has no way to return "a long, or nothing".

## Members

```freebasic
HasValue( ) as boolean                    O(1)
Value( ) byref as T                       O(1)   RAISES if empty
ValueOr( byref dflt as T ) byref as T     O(1)   never raises
Clear( )                                  O(1)   becomes empty
```

and two FREE PROCEDURES, not constructors:

```freebasic
Some( v ) as Optional( of T )             T inferred from v
None( of T )( ) as Optional( of T )       T must be written out
```

There is deliberately no operator '=', no comparison, no ToString and no GetIterator. See WHY THERE ARE SO FEW MEMBERS below.

## A DEFAULT-CONSTRUCTED Optional Is Empty

```freebasic
dim o as Optional( of int32 )         ' empty, not "uninitialised"
```

There is no third state to get wrong. Construction by free procedure rather than by constructor is what lets T be inferred:

```freebasic
dim o as Optional( of int32 ) = Some( 3L )        ' not Optional( of long )( 3 )
```

None( ) exists so that returning nothing reads as a decision rather than as a forgotten assignment:

```freebasic
return None( of int32 )( )           ' deliberate
return                              ' also empty, but says nothing
```

T cannot be inferred for None( ) -- there is no argument to infer it from -- so it has to be written out.

## Inference Never Converts

Some( ) infers T from the ARGUMENT, and an untyped integer literal is an INTEGER:

```freebasic
dim o as Optional( of int32 ) = Some( 3 )        ' Optional( of integer ):
                                                ' type mismatch

dim o as Optional( of int32 ) = Some( 3L )       ' correct
```

The same rule the containers already carry, for the same reason: inference reads parameter positions and does not coerce. Use a suffixed literal or a variable of the element type.

## Empty Access Raises

Value( ) on an empty Optional raises FB_RTERROR_ILLEGALFUNCTIONCALL. With no handler installed the program stops, naming the line that called Value( ):

```freebasic
Aborting due to runtime error 1 (illegal function call) at line 14 of demo.tiko(), Value( ) of an empty Optional
```

It is catchable by 'on error', where ERR is 1 and ERL is that line. This is a bug at the call site, not a recoverable condition: HasValue( ) or ValueOr( ) is available and costs nothing.

The compiler warns, `TKO1150`, where it can see that no HasValue( ) check covers a Value( ) on every path to it. It follows `if` / `elseif` / `else`, `andalso` / `orelse`, `not` and `= false`, `iif`, `while` loops, and early `return` / `exit` / `error` / `end`; an assignment from `Some( )` or a call to `Assign( )` counts as a check, and `Clear( )`, a new assignment, or passing the Optional `byref` undoes one. It tracks named variables and parameters only, not a call's result or a field. `-Wno-TKO1150` turns it off.

ValueOr( ) is the branch-free alternative and never raises:

```freebasic
print o.ValueOr( fallback )
```

Both return BYREF. ValueOr( ) therefore aliases either the stored value or the CALLER'S default, so passing a temporary gives a reference that dies at the end of the statement -- the same hazard as any byref return, not an Optional one.

Value( ) IS usable as an assignment target, and writes through to the stored value:

```freebasic
dim o as Optional( of int32 ) = Some( 1L )
o.Value( ) = 5
print o.Value( )                    ' 5
```

Note this differs from Array.At( ), where 'a.At( 0 ) = 11' does NOT assign -- measured, both under -w 3, and both silent. Do not assume one from the other. Binding byref is unambiguous and works for both:

```freebasic
dim byref as int32 r = o.Value( )
r = 5
```

## Zero Is A Value

This is the whole point, and it is worth stating on its own:

```freebasic
dim engaged as Optional( of int32 ) = Some( 0L )
dim empty_  as Optional( of int32 )

engaged.ValueOr( zero )             ' 0
empty_.ValueOr( zero )              ' 0        -- same answer
engaged.HasValue( )                 ' true
empty_.HasValue( )                  ' false    -- different states
```

Every sentinel encoding Optional replaces gets this case wrong.

## Why There Are So Few Members

Not minimalism. Every member of a generic is instantiated whether it is called or not, so a member needing '=' on T would make the WHOLE TYPE unusable for any T without one -- the same rule that forced Array's Sort, IndexOf and Contains to become free procedures.

So Optional's members use only default construction, copy and destruction, and Optional( of T ) instantiates for any T that has those. Including containers, which have no '=':

```freebasic
dim o as Optional( of Array( of int32 ) )        ' fine
```

Anything needing more than that belongs in a free procedure, where the requirement lands on the call that actually needs it.

## It Is NOT A Sum Type

Optional is a T plus a boolean, not a tagged union. The stored T is always default-constructed, whether or not the Optional is engaged, so:

```freebasic
sizeof( Optional( of T ) ) >= sizeof( T ) + sizeof( boolean )
```

and T's default constructor runs for an empty Optional. That is the price of not having sum types in the language; it also means T MUST be default-constructible:

```freebasic
type NoDefaultCtor
    as int32 a
    declare constructor( byval n as int32 )      ' suppresses the implicit one
end type

dim o as Optional( of NoDefaultCtor )           ' error 183: TYPE or CLASS
                                                ' has no default constructor
```

## Library Only

No compiler change went into this, and several things were deliberately NOT done:

```freebasic
no '?' operator                     ' propagating early-return
no must-use diagnostic              ' ignoring an Optional stays a convention
no sum type underneath              ' see above
no implicit conversion to boolean   ' 'if( o ) then' does not compile
```

What it buys is that the absence has a name and a type. Nothing more is claimed.

## NOT Iterable

There is no GetIterator( ), so 'for each' over an Optional is a compile error rather than a zero-or-one loop. A maybe-value is not a sequence, and pretending it is makes the absence easy to skip silently:

```freebasic
for each v in maybe                 ' would do nothing, and say nothing
    use( v )
next
```

Write the branch.

## Ownership AND Copying

Copy and assignment are DEEP, because the T is stored by value and tiko's value semantics do the work. 'dim b = a' copies the flag and the T; assignment overwrites both. The two are independent afterwards in BOTH directions.

Clear( ) resets the slot rather than only clearing the flag, so a T holding a resource -- a string, a container -- releases it at the Clear( ) rather than at the Optional's own destruction.

An Optional( of T ptr ) copies the POINTER. There are no smart pointers.

Optional( of Optional( of T ) ) works and has three distinguishable states, which is what makes it composable at all.

## Implementation Note

Value( ) returns a reference to the stored slot even on the raising path, because a byref return must refer to something and the slot is always a real default-constructed object.

It does NOT use the function-'static' blank that LinkedList.Front( ) uses. That pattern is correct there -- an empty list has no node to point at -- but it would be a leak here: a function-'static' UDT in tiko lives until the program ends, so every instantiation of the member would retain one T, and its resources, for the lifetime of the program.

Source: pkg/std/outcome/optional.tiko

## Tests

src/tests/generics/container-optional.bas is exhaustive: every member, both states, both free constructors, all four assignment transitions between the states, self-assignment, copy independence in both directions, byref mutation through Value( ) and ValueOr( ), element types long / double / string / a UDT with no operators / a nested Array / a nested Optional, an Optional as a return value, and destructor balance with a counting element type -- asserted for the engaged case and for the never-engaged case separately.

src/tests/generics/optional-empty-value.bas is a COMPILE_AND_RUN_FAIL test pinning that Value( ) on an empty Optional aborts. It is a separate module because the raise ends the process.

src/tests/generics/fail-optional-nodefaultctor.bas pins the diagnostic for a T with no default constructor.

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Errors and missing values](Functions-Errors) lists them beside the rest of the area.

### Return a value that may be missing

| Function | What it does | From |
|---|---|---|
| [Some](Modern-Optional-Some) | Returns an Optional holding the value, its type taken from the argument. | `std/outcome` |
| [None](Modern-Optional-None) | Returns an empty Optional of the type you write out. | `std/outcome` |
| [Optional.HasValue](Modern-Optional-HasValue) | Returns true if the Optional holds a value. | `std/outcome` |
| [Optional.Value](Modern-Optional-Value) | Returns the value by reference; raises an error if the Optional is empty. | `std/outcome` |
| [Optional.ValueOr](Modern-Optional-ValueOr) | Returns the value, or the fallback you pass if the Optional is empty. | `std/outcome` |
| [Optional.Clear](Modern-Optional-Clear) | Empties the Optional, releasing whatever its value held. | `std/outcome` |

<!-- finder:end -->

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
