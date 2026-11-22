[Home](Home) › [Result](Category-Result) › [Result](Category-Result) › **Failure**

# Failure

Returns the reason by reference; raises an error if the Result succeeded.

## Syntax

```freebasic
Failure( [ byval callerLine_ as long = __CALLER_LINE__, byval callerFile_ as zstring ptr = __CALLER_FILE__ ] ) byref as E
```

The two parameters are for the error message and are not written: their defaults are the calling statement's line and file ([`__CALLER_LINE__`](Caller-Line)).

## Examples

```freebasic
#import "std/outcome"
using outcome

dim r as Result( of int32, ustring ) = Fail( of int32, ustring )( "not a number" )

print r.Failure( )           '' not a number

'' Byref, like Value( )
r.Failure( ) = "bad input"
print r.Failure( )           '' bad input

'' On a SUCCESSFUL Result this raises, symmetrically with Value( ) on a
'' failure, at the caller's line with 'Failure( ) of a Result that did not
'' fail'. IsOk( ) is the guard for both; without it the compiler warns, TKO1150.
```

---

**Library:** [Result](Category-Result)  
**Category:** [Result](Category-Result)  
**Documented under:** Members
