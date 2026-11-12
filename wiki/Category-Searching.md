[Home](Home) › [All Categories](Categories) › **Searching**

# Searching And Rearranging

Free procedures in `std/containers` that search a sorted [Array](Category-Array) or rearrange one in place. Each has a `...By` twin that takes a comparer, exactly like [Sort and SortBy](Category-Sorting).

```freebasic
#import "std/containers"
using containers

dim v as Array( of long ) = { 1, 3, 3, 7, 9 }

print LowerBound( v, 3L )              ' 1  -- first 3
print UpperBound( v, 3L )              ' 3  -- just past the last 3
print BinarySearch( v, 7L )            ' 3
print BinarySearch( v, 5L )            ' -4 -- not there; it would go at index 3
```

## Searching A Sorted Array

These need the array **sorted by the same order** they search with. On an unsorted array they return some index without complaint.

| Procedure | Returns |
|---|---|
| `LowerBound( a, v )` | the first index whose element is not less than `v` — where `v` would be inserted before any equal elements; `Count( )` when every element is less |
| `UpperBound( a, v )` | the first index whose element is greater than `v` — insertion after any equal elements |
| `BinarySearch( a, v )` | the index of the first element equal to `v`; when there is none, `-( insertion point ) - 1`, which is always negative and still says where `v` belongs |
| `PartitionPoint( a, pred )` | for an array where every element passing `pred` comes first, the index of the first one that fails |

**Write the value with the array's type.** The element type is worked out from both arguments, so `LowerBound( v, 3 )` on an `Array( of long )` is an error — `3` alone is an `integer`. Write `3L`, or pass a variable of type `long`.

Counting the occurrences of a value is `UpperBound( a, v ) - LowerBound( a, v )`.

## Smallest And Largest

`MinIndex( a )` and `MaxIndex( a )` return the index of the first smallest or largest element, or -1 for an empty array. They do not need a sorted array.

## Rearranging In Place

| Procedure | Does |
|---|---|
| `ReverseArray( a )` | reverses the order |
| `RotateArray( a, k )` | rotates left by `k`, so the element at index `k` becomes the first. Negative `k` rotates right; `k` is taken modulo the count |
| `Dedup( a )` | removes **consecutive** duplicates, keeping the first of each run, and returns how many it removed. Sort first to remove every duplicate |
| `NextPermutation( a )` | rearranges into the next permutation in sorted order and returns `true`; after the last one it rearranges back to sorted and returns `false` |
| `PartialSort( a, k )` | puts the `k` smallest elements, sorted, at the front; the rest are left in no particular order. O(n log k) |
| `NthElement( a, k )` | puts at index `k` the element a full sort would put there, with nothing greater before it and nothing less after it. O(n) on average |

```freebasic
#import "std/containers"
using containers

dim p as Array( of long ) = { 1, 2, 3 }
do
    print p[ 0 ]; p[ 1 ]; p[ 2 ]       ' all six orders, from 1 2 3 to 3 2 1
loop while NextPermutation( p )

dim scores as Array( of long ) = { 40, 95, 12, 77, 63, 88 }
PartialSort( scores, 3 )
print scores[ 0 ], scores[ 1 ], scores[ 2 ]   ' 12  40  63  -- the three lowest
```

`Dedup` compares with `=`; `DedupBy( a, same )` takes an equality test instead:

```freebasic
#import "std/containers"
using containers

dim words as Array( of ustring ) = { "a", "A", "b", "B", "b" }
var sameLetter = function( byref x as ustring, byref y as ustring ) as boolean
    return lcase( x ) = lcase( y )
end function
print DedupBy( words, sameLetter )     ' 3 removed: "a", "b" remain
```

Every move is a `SWAP`, so rearranging an `Array( of ustring )` copies no strings.

To put an `Array` in random order, `ShuffleArray( r, a )` from `std/numeric` takes an `Rng` and gives every order an equal chance; see [Shuffle](Modern-Math-Shuffle#containers).

## See Also

[Sorting](Category-Sorting) · [Array](Category-Array) · [PriorityQueue](Category-PriorityQueue)
