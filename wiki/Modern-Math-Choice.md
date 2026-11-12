[Home](Home) › [Math Library](Category-Math-Library) › [Math Library](Category-Math-Library) › **Choice**

# Choice

Returns one element of an array or container picked at random, by reference.

## Syntax

```freebasic
Choice( r, a( ) )
```

## Examples

```freebasic
#import "std/numeric"
using numeric

dim r as Rng = RngFromEntropy( )
dim as string names_( 0 to 2 ) = { "ada", "grace", "alan" }

'' One element, uniformly. It returns BYREF, so it can be assigned
'' through as well as read.
dim as string picked = Choice( r, names_( ) )
print picked = "ada" orelse picked = "grace" orelse picked = "alan"    '' -1
```

## Containers

```freebasic
ChoiceArray( r, a )      '' containers.Array( of T )
ChoiceDeque( r, d )      '' containers.Deque( of T )
```

The same pick for the containers, for any element type: one draw, every element equally likely, returned **by reference**. On an empty container there is no element to return, and both raise runtime error 6 (out of bounds). There is no form for a `LinkedList`, because reaching a random node means walking the list; copy it into an `Array` first.

```freebasic
#import "std/containers"
#import "std/numeric"
using containers
using numeric

dim r as Rng = RngFromEntropy( )
dim stock as Array( of int32 ) = { 5, 5, 5 }

'' By reference: this takes one from a random slot
ChoiceArray( r, stock ) -= 1
print stock[ 0 ] + stock[ 1 ] + stock[ 2 ]     '' 14

dim names_ as Array( of ustring ) = { "ada", "grace", "alan" }
dim as ustring picked = ChoiceArray( r, names_ )
print picked = "ada" orelse picked = "grace" orelse picked = "alan"    '' -1
```

---

**Library:** [Math Library](Category-Math-Library)  
**Category:** [Math Library](Category-Math-Library)  
**Documented under:** Nothing Becomes A Keyword
