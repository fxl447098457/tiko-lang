[Home](Home) › [Math Library](Category-Math-Library) › [Math Library](Category-Math-Library) › **Shuffle**

# Shuffle

Shuffles an array or container in place so that every order is equally likely.

## Syntax

```freebasic
Shuffle( r, a( ) )
```

## Examples

```freebasic
#import "std/numeric"
using numeric

dim r as Rng = RngFromEntropy( )
dim as int32 a( 0 to 4 ) = { 1, 2, 3, 4, 5 }

'' Fisher-Yates, in place and unbiased -- every permutation equally
'' likely, which the sort-by-random-key trick does not give
Shuffle( r, a( ) )

dim as int32 total = 0
for each v in a
    total += v
next
print total                  '' 15 -- the same elements, reordered
```

## Containers

```freebasic
ShuffleArray( r, a )     '' containers.Array( of T )
ShuffleDeque( r, d )     '' containers.Deque( of T )
ShuffleList( r, l )      '' containers.LinkedList( of T )
```

The same shuffle for the containers, for any element type. Each one makes the same draws as `Shuffle`, so one seed puts a plain array and every container that holds the same values into the same order. `ShuffleList` relinks the list's nodes instead of moving values: no element is copied, and a reference to an element stays valid. With fewer than two elements nothing moves and nothing is drawn.

```freebasic
#import "std/containers"
#import "std/numeric"
using containers
using numeric

dim r as Rng = RngSeeded( 42 )
dim deck as Array( of ustring ) = { "A", "B", "C", "D", "E", "F", "G", "H" }

'' Any element type; the same draws as Shuffle, so seed 42 gives
'' this order on every run and every platform
ShuffleArray( r, deck )
for each card in deck
    print card;
next
print                        '' HBGDFECA

'' A LinkedList is relinked, not copied: no element moves in memory
dim queue as LinkedList( of ustring )
queue.PushBack( "x" ) : queue.PushBack( "y" ) : queue.PushBack( "z" )
ShuffleList( r, queue )
print queue.Count( )         '' 3
```

---

**Library:** [Math Library](Category-Math-Library)  
**Category:** [Math Library](Category-Math-Library)  
**Documented under:** Nothing Becomes A Keyword
