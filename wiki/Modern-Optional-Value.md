[Home](Home) › [Optional](Category-Optional) › [Optional](Category-Optional) › **Value**

# Value

Returns the value by reference; raises an error if the Optional is empty.

## Syntax

```freebasic
Value( [ byval callerLine_ as long = __CALLER_LINE__, byval callerFile_ as zstring ptr = __CALLER_FILE__ ] ) byref as T
```

The two parameters are for the error message and are not written: their defaults are the calling statement's line and file ([`__CALLER_LINE__`](Caller-Line)).

## Examples

```freebasic
#import "std/outcome"
using outcome

dim o as Optional( of integer ) = Some( 42 )

print o.Value( )             '' 42

'' Byref, so it assigns in place
o.Value( ) = 43
print o.Value( )             '' 43

'' EMPTY ACCESS RAISES: Value( ) on an empty Optional raises
'' FB_RTERROR_ILLEGALFUNCTIONCALL, catchable by `on error`. Unhandled, it stops
'' the program at the CALLER'S line. Reading a value that is not there is a bug
'' at the call site, not a condition to recover from. ValueOr( ) is the
'' branch-free alternative.
```

```
Aborting due to runtime error 1 (illegal function call) at line 14 of demo.tiko(), Value( ) of an empty Optional
```

Where the compiler can see that no `HasValue( )` check covers a call on every path to it, it warns, `TKO1150`:

```freebasic
sub Show( byref o as Optional( of integer ) )
    print o.Value( )                     '' warning TKO1150: 'o.Value( )' may raise runtime error 1
    if o.HasValue( ) then print o.Value( )   '' no warning
end sub
```

---

**Library:** [Optional](Category-Optional)  
**Category:** [Optional](Category-Optional)  
**Documented under:** Members
