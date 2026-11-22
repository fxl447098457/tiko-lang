[Home](Home) › [Result](Category-Result) › [Result](Category-Result) › **Value**

# Value

Returns the value by reference; raises an error if the Result failed.

## Syntax

```freebasic
Value( [ byval callerLine_ as long = __CALLER_LINE__, byval callerFile_ as zstring ptr = __CALLER_FILE__ ] ) byref as T
```

The two parameters are for the error message and are not written: their defaults are the calling statement's line and file ([`__CALLER_LINE__`](Caller-Line)).

## Examples

```freebasic
#import "std/outcome"
using outcome

dim r as Result( of int32, ustring ) = Ok( of int32, ustring )( 42 )

print r.Value( )             '' 42

'' Value( ) returns BYREF, so it assigns in place
r.Value( ) = 43
print r.Value( )             '' 43

'' On a FAILED Result this raises FB_RTERROR_ILLEGALFUNCTIONCALL --
'' catchable by `on error`, and a bug at the call site otherwise: unhandled,
'' it stops at the caller's line with 'Value( ) of a failed Result'.
'' Guard with IsOk( ), or use ValueOr( ); without a guard the compiler warns,
'' TKO1150.
```

---

**Library:** [Result](Category-Result)  
**Category:** [Result](Category-Result)  
**Documented under:** Members
