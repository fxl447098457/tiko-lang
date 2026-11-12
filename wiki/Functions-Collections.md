[Home](Home) › [Function Finder](Function-Finder) › **Collections**

# Collections

The functions to keep lists, lookups and sets of values; sort and search them, grouped by what you want to do. The **From** column says what a program needs before it can call one:

- **built-in**: nothing; it is always available.
- `std/containers`: `#import "std/containers"`, then `using containers` to call it by its bare name.
- `std/numeric`: `#import "std/numeric"`, then `using numeric` to call it by its bare name.
- `fbc-int/array.bi`: `#include "fbc-int/array.bi"`, then `using FB`.

Jump to: [Choose a container](#choose-a-container) · [Array: add and remove](#array-add-and-remove) · [Array: read, count and visit](#array-read-count-and-visit) · [Array: find a value](#array-find-a-value) · [Sort an Array or a LinkedList](#sort-an-array-or-a-linkedlist) · [Map: add and change](#map-add-and-change) · [Map: look up](#map-look-up) · [Map: list keys and values](#map-list-keys-and-values) · [Set: add, remove and test](#set-add-remove-and-test) · [Built-in arrays: bounds and size](#built-in-arrays-bounds-and-size) · [Built-in arrays: resize and erase](#built-in-arrays-resize-and-erase) · [Queues and stacks: LinkedList and Deque](#queues-and-stacks-linkedlist-and-deque) · [PriorityQueue: take the smallest first](#priorityqueue-take-the-smallest-first) · [Combine sets](#combine-sets) · [Find the first, last or nearest key](#find-the-first-last-or-nearest-key) · [BitSet: flags by number](#bitset-flags-by-number) · [Rearrange an Array](#rearrange-an-array) · [Walk a container step by step](#walk-a-container-step-by-step) · [Reserve room ahead of time](#reserve-room-ahead-of-time) · [Check a container's internals](#check-a-containers-internals)

## Choose a container

| Function | What it does | From |
|---|---|---|
| [Array](Modern-Array-Array) | Holds a growable list of values in order, reached by position from 0. | `std/containers` |
| [Map](Modern-Map-Map) | Holds key and value pairs in a hash table, so you find a value by its key. | `std/containers` |
| [Set](Modern-Set-Set) | Holds each value at most once, in no particular order. | `std/containers` |
| [OrderedMap](Modern-OrderedMap-OrderedMap) | Holds key and value pairs kept sorted by key. | `std/containers` |
| [OrderedSet](Modern-OrderedSet-OrderedSet) | Holds each value at most once, kept in sorted order. | `std/containers` |
| [LinkedList](Modern-LinkedList-LinkedList) | Holds a chain of values that is quick to add to and remove from at either end. | `std/containers` |
| [Deque](Category-Deque) | Holds a sequence that is quick to change at both ends and can be read by index. | `std/containers` |
| [PriorityQueue](Category-PriorityQueue) | Holds values and hands them back smallest first. | `std/containers` |
| [PriorityQueueBy](Category-PriorityQueue#any-other-order-priorityqueueby) | Holds values and hands them back in the order your comparer gives. | `std/containers` |
| [BitSet](Category-BitSet) | Holds a set of small non-negative whole numbers, one bit each. | `std/containers` |

## Array: add and remove

| Function | What it does | From |
|---|---|---|
| [Array.Push](Modern-Array-Push) | Adds a value at the end, growing the array as needed. | `std/containers` |
| [Array.Pop](Modern-Array-Pop) | Removes and returns the last element, or a default value if the array is empty. | `std/containers` |
| [Array.Insert](Modern-Array-Insert) | Inserts a value at a position, moving the later elements up one place. | `std/containers` |
| [Array.Remove](Modern-Array-Remove) | Removes the element at a position, keeping the rest in order. | `std/containers` |
| [Array.RemoveSwap](Modern-Array-RemoveSwap) | Removes the element at a position quickly by moving the last element into its place. | `std/containers` |
| [Array.Clear](Modern-Array-Clear) | Removes every element but keeps the allocated room. | `std/containers` |

## Array: read, count and visit

| Function | What it does | From |
|---|---|---|
| [Array.At](Modern-Array-At) | Returns a reference to the element at a position, like a[ i ]. | `std/containers` |
| [Array.Count](Modern-Array-Count) | Returns the number of elements; the valid indices are 0 to Count minus 1. | `std/containers` |
| [Array.IsEmpty](Modern-Array-IsEmpty) | Returns true if the array has no elements. | `std/containers` |
| [ForEach](Modern-Array-ForEach) | Calls a procedure on every element in order, passing each by reference. | `std/containers` |

## Array: find a value

| Function | What it does | From |
|---|---|---|
| [IndexOf](Modern-Array-IndexOf) | Returns the index of the first element equal to a value, or -1 if there is none. | `std/containers` |
| [Contains](Modern-Array-Contains) | Returns true if any element equals the value. | `std/containers` |
| [MinIndex](Category-Searching#smallest-and-largest) | Returns the index of the first smallest element, or -1 if the array is empty. | `std/containers` |
| [MinIndexBy](Category-Searching#smallest-and-largest) | Returns the index of the first smallest element by your comparer, or -1 if empty. | `std/containers` |
| [MaxIndex](Category-Searching#smallest-and-largest) | Returns the index of the first largest element, or -1 if the array is empty. | `std/containers` |
| [MaxIndexBy](Category-Searching#smallest-and-largest) | Returns the index of the first largest element by your comparer, or -1 if empty. | `std/containers` |
| [BinarySearch](Category-Searching#searching-a-sorted-array) | Returns where a value is in a sorted array, or a negative number if it is absent. | `std/containers` |
| [BinarySearchBy](Category-Searching#searching-a-sorted-array) | Returns where a value is in an array sorted by your comparer, or a negative number. | `std/containers` |
| [LowerBound](Category-Searching#searching-a-sorted-array) | Returns the first index whose element is not less than the value, in a sorted array. | `std/containers` |
| [LowerBoundBy](Category-Searching#searching-a-sorted-array) | Returns the first index not less than the value, in an array sorted by your comparer. | `std/containers` |
| [UpperBound](Category-Searching#searching-a-sorted-array) | Returns the first index whose element is greater than the value, in a sorted array. | `std/containers` |
| [UpperBoundBy](Category-Searching#searching-a-sorted-array) | Returns the first index greater than the value, in an array sorted by your comparer. | `std/containers` |
| [PartitionPoint](Category-Searching#searching-a-sorted-array) | Returns the index of the first element that fails a test, when passing ones come first. | `std/containers` |

## Sort an Array or a LinkedList

| Function | What it does | From |
|---|---|---|
| [Sort](Modern-Sorting-Sort) | Sorts an Array in ascending order in place; equal elements may change places. | `std/containers` |
| [SortBy](Modern-Sorting-SortBy) | Sorts an Array in place by your comparer; equal elements may change places. | `std/containers` |
| [StableSort](Modern-Sorting-StableSort) | Sorts an Array in ascending order, keeping equal elements in their original order. | `std/containers` |
| [StableSortBy](Modern-Sorting-StableSortBy) | Sorts an Array by your comparer, keeping equal elements in their original order. | `std/containers` |
| [IsSorted](Modern-Sorting-IsSorted) | Returns true if the Array is already in ascending order. | `std/containers` |
| [IsSortedBy](Modern-Sorting-IsSortedBy) | Returns true if the Array is already in order by your comparer. | `std/containers` |
| [SortList](Modern-Sorting-SortList) | Sorts a LinkedList in ascending order by relinking nodes; equal elements keep order. | `std/containers` |
| [SortListBy](Modern-Sorting-SortListBy) | Sorts a LinkedList by your comparer, relinking nodes; equal elements keep order. | `std/containers` |
| [Sort](Modern-Array-Sort) (Array) | Sorts an Array in ascending order in place; equal elements may change places. | `std/containers` |
| [SortBy](Modern-Array-SortBy) (Array) | Sorts an Array in place by your comparer; equal elements may change places. | `std/containers` |
| [StableSort](Modern-Array-StableSort) (Array) | Sorts an Array in ascending order, keeping equal elements in their original order. | `std/containers` |
| [StableSortBy](Modern-Array-StableSortBy) (Array) | Sorts an Array by your comparer, keeping equal elements in their original order. | `std/containers` |
| [IsSorted](Modern-Array-IsSorted) (Array) | Returns true if the Array is already in ascending order. | `std/containers` |
| [SortList](Modern-LinkedList-SortList) (LinkedList) | Sorts a LinkedList in ascending order by relinking nodes; equal elements keep order. | `std/containers` |
| [SortListBy](Modern-LinkedList-SortListBy) (LinkedList) | Sorts a LinkedList by your comparer, relinking nodes; equal elements keep order. | `std/containers` |

## Map: add and change

| Function | What it does | From |
|---|---|---|
| [Map.Put](Modern-Map-Put) | Stores a value under a key, replacing any old one; returns true if the key was new. | `std/containers` |
| [Map.Add](Modern-Map-Add) | Adds a key and value if the key is new; an existing value is left alone. | `std/containers` |
| [Map.Remove](Modern-Map-Remove) | Removes a key and its value; returns true if the key was there. | `std/containers` |
| [Map.Clear](Modern-Map-Clear) | Removes every entry. | `std/containers` |
| [OrderedMap.Put](Modern-OrderedMap-Put) | Stores a value under a key, replacing any old one; returns true if the key was new. | `std/containers` |
| [OrderedMap.Add](Modern-OrderedMap-Add) | Adds a key and value if the key is new; an existing value is left alone. | `std/containers` |
| [OrderedMap.Remove](Modern-OrderedMap-Remove) | Removes a key and its value; returns true if the key was there. | `std/containers` |
| [OrderedMap.Clear](Modern-OrderedMap-Clear) | Removes every entry. | `std/containers` |

## Map: look up

| Function | What it does | From |
|---|---|---|
| [Map.TryGet](Modern-Map-TryGet) | Copies the value for a key into a variable; returns false, adding nothing, if absent. | `std/containers` |
| [Map.Contains](Modern-Map-Contains) | Returns true if the key is present, without adding it. | `std/containers` |
| [Map.Count](Modern-Map-Count) | Returns the number of entries; reading an absent key with m[ k ] adds one. | `std/containers` |
| [Map.IsEmpty](Modern-Map-IsEmpty) | Returns true if the map has no entries. | `std/containers` |
| [OrderedMap.TryGet](Modern-OrderedMap-TryGet) | Copies the value for a key into a variable; returns false, adding nothing, if absent. | `std/containers` |
| [OrderedMap.Contains](Modern-OrderedMap-Contains) | Returns true if the key is present, without adding it. | `std/containers` |
| [OrderedMap.Count](Modern-OrderedMap-Count) | Returns the number of entries; reading an absent key with m[ k ] adds one. | `std/containers` |
| [OrderedMap.IsEmpty](Modern-OrderedMap-IsEmpty) | Returns true if the map has no entries. | `std/containers` |

## Map: list keys and values

| Function | What it does | From |
|---|---|---|
| [Map.Keys](Modern-Map-Keys) | Returns a copy of all the keys as an Array, in no particular order. | `std/containers` |
| [Map.Values](Modern-Map-Values) | Returns a copy of all the values as an Array, in no particular order. | `std/containers` |
| [Map.Pairs](Modern-Map-Pairs) | Returns a view that lets for each (k, v) give each key and value as two variables. | `std/containers` |
| [OrderedMap.Keys](Modern-OrderedMap-Keys) | Returns a copy of all the keys as an Array, already sorted. | `std/containers` |
| [OrderedMap.Values](Modern-OrderedMap-Values) | Returns a copy of all the values as an Array, in the order of their keys. | `std/containers` |
| [OrderedMap.Pairs](Modern-OrderedMap-Pairs) | Returns a view that lets for each (k, v) walk keys and values in key order. | `std/containers` |

## Set: add, remove and test

| Function | What it does | From |
|---|---|---|
| [Set.Add](Modern-Set-Add) | Adds a value; returns false if it was already there. | `std/containers` |
| [Set.Remove](Modern-Set-Remove) | Removes a value; returns true if it was there. | `std/containers` |
| [Set.Contains](Modern-Set-Contains) | Returns true if the value is in the set. | `std/containers` |
| [Set.Count](Modern-Set-Count) | Returns the number of values in the set. | `std/containers` |
| [Set.IsEmpty](Modern-Set-IsEmpty) | Returns true if the set has no values. | `std/containers` |
| [Set.Clear](Modern-Set-Clear) | Removes every value. | `std/containers` |
| [Set.Items](Modern-Set-Items) | Returns a copy of all the values as an Array, in no particular order. | `std/containers` |
| [OrderedSet.Add](Modern-OrderedSet-Add) | Adds a value; returns false if it was already there. | `std/containers` |
| [OrderedSet.Remove](Modern-OrderedSet-Remove) | Removes a value; returns true if it was there. | `std/containers` |
| [OrderedSet.Contains](Modern-OrderedSet-Contains) | Returns true if the value is in the set. | `std/containers` |
| [OrderedSet.Count](Modern-OrderedSet-Count) | Returns the number of values in the set. | `std/containers` |
| [OrderedSet.IsEmpty](Modern-OrderedSet-IsEmpty) | Returns true if the set has no values. | `std/containers` |
| [OrderedSet.Clear](Modern-OrderedSet-Clear) | Removes every value. | `std/containers` |
| [OrderedSet.Items](Modern-OrderedSet-Items) | Returns a copy of all the values as an Array, already sorted. | `std/containers` |

## Built-in arrays: bounds and size

| Function | What it does | From |
|---|---|---|
| [UBound](Ubound) | Returns the highest valid index of an array dimension, or -1 if there is none. | built-in |
| [LBound](Lbound) | Returns the lowest valid index of an array dimension, or 0 if there is none. | built-in |
| [ArrayLen](Arraylen) | Returns the total number of elements in an array, counting every dimension. | `fbc-int/array.bi` |
| [ArraySize](Arraysize) | Returns the total size of an array's elements in bytes. | `fbc-int/array.bi` |
| [FBARRAY](Fbarray-Array-Descriptor-Structure-and-Access) | Holds an array's descriptor: its bounds, sizes and data pointers. | `fbc-int/array.bi` |

## Built-in arrays: resize and erase

| Function | What it does | From |
|---|---|---|
| [ReDim](Redim) | Creates or resizes a variable-length array; elements are reset unless Preserve is used. | built-in |
| [Preserve](Preserve) | Keeps the existing elements when ReDim resizes an array. | built-in |
| [Erase](Erase) | Frees a variable-length array's elements, or resets those of a fixed-length array. | built-in |

## Queues and stacks: LinkedList and Deque

| Function | What it does | From |
|---|---|---|
| [LinkedList.PushBack](Modern-LinkedList-PushBack) | Adds a value at the back of the list. | `std/containers` |
| [LinkedList.PushFront](Modern-LinkedList-PushFront) | Adds a value at the front of the list. | `std/containers` |
| [LinkedList.PopFront](Modern-LinkedList-PopFront) | Removes and returns the front value, or a default value if the list is empty. | `std/containers` |
| [LinkedList.PopBack](Modern-LinkedList-PopBack) | Removes and returns the back value, or a default value if the list is empty. | `std/containers` |
| [LinkedList.Front](Modern-LinkedList-Front) | Returns a reference to the front value without removing it. | `std/containers` |
| [LinkedList.Back](Modern-LinkedList-Back) | Returns a reference to the back value without removing it. | `std/containers` |
| [LinkedList.Count](Modern-LinkedList-Count) | Returns the number of values in the list. | `std/containers` |
| [LinkedList.IsEmpty](Modern-LinkedList-IsEmpty) | Returns true if the list has no values. | `std/containers` |
| [LinkedList.Clear](Modern-LinkedList-Clear) | Removes every value and frees its nodes. | `std/containers` |
| [Deque.PushBack](Category-Deque#members) | Adds a value at the back of the deque. | `std/containers` |
| [Deque.PushFront](Category-Deque#members) | Adds a value at the front of the deque. | `std/containers` |
| [Deque.PopFront](Category-Deque#members) | Removes and returns the front value, or a default value if the deque is empty. | `std/containers` |
| [Deque.PopBack](Category-Deque#members) | Removes and returns the back value, or a default value if the deque is empty. | `std/containers` |
| [Deque.TryPopFront](Category-Deque#members) | Removes the front value into a variable; returns false if the deque is empty. | `std/containers` |
| [Deque.TryPopBack](Category-Deque#members) | Removes the back value into a variable; returns false if the deque is empty. | `std/containers` |
| [Deque.Front](Category-Deque#members) | Returns a reference to the front value; the deque must not be empty. | `std/containers` |
| [Deque.Back](Category-Deque#members) | Returns a reference to the back value; the deque must not be empty. | `std/containers` |
| [Deque.At](Category-Deque#members) | Returns a reference to the value at a position, 0 being the front, like d[ i ]. | `std/containers` |
| [Deque.Count](Category-Deque#members) | Returns the number of values in the deque. | `std/containers` |
| [Deque.IsEmpty](Category-Deque#members) | Returns true if the deque has no values. | `std/containers` |
| [Deque.Clear](Category-Deque#members) | Removes every value but keeps the allocated room. | `std/containers` |

## PriorityQueue: take the smallest first

| Function | What it does | From |
|---|---|---|
| [PriorityQueue.Push](Category-PriorityQueue#members) | Adds a value to the queue. | `std/containers` |
| [PriorityQueue.Pop](Category-PriorityQueue#members) | Removes and returns the smallest value, or a default value if the queue is empty. | `std/containers` |
| [PriorityQueue.TryPop](Category-PriorityQueue#members) | Removes the smallest value into a variable; returns false if the queue is empty. | `std/containers` |
| [PriorityQueue.Peek](Category-PriorityQueue#members) | Returns a reference to the smallest value without removing it; test IsEmpty first. | `std/containers` |
| [PriorityQueue.Count](Category-PriorityQueue#members) | Returns the number of values in the queue. | `std/containers` |
| [PriorityQueue.IsEmpty](Category-PriorityQueue#members) | Returns true if the queue has no values. | `std/containers` |
| [PriorityQueue.Clear](Category-PriorityQueue#members) | Removes every value. | `std/containers` |
| [PriorityQueue.ToSortedArray](Category-PriorityQueue#members) | Returns the values as an Array in priority order, leaving the queue unchanged. | `std/containers` |
| [MakeHeap](Category-PriorityQueue#building-from-an-array) | Creates a PriorityQueue from an Array's values, leaving the Array unchanged. | `std/containers` |

## Combine sets

| Function | What it does | From |
|---|---|---|
| [Set.UnionWith](Modern-Set-UnionWith) | Adds every value of another set to this one; the other set is unchanged. | `std/containers` |
| [Set.IntersectWith](Modern-Set-IntersectWith) | Keeps only the values that are also in another set. | `std/containers` |
| [Set.ExceptWith](Modern-Set-ExceptWith) | Removes every value that is also in another set. | `std/containers` |
| [OrderedSet.UnionWith](Modern-OrderedSet-UnionWith) | Adds every value of another set to this one; the other set is unchanged. | `std/containers` |
| [OrderedSet.IntersectWith](Modern-OrderedSet-IntersectWith) | Keeps only the values that are also in another set. | `std/containers` |
| [OrderedSet.ExceptWith](Modern-OrderedSet-ExceptWith) | Removes every value that is also in another set. | `std/containers` |
| [BitSet.UnionWith](Category-BitSet#set-algebra) | Sets every bit that is set in another BitSet. | `std/containers` |
| [BitSet.IntersectWith](Category-BitSet#set-algebra) | Clears every bit that is not also set in another BitSet. | `std/containers` |
| [BitSet.DifferenceWith](Category-BitSet#members) | Clears every bit that is set in another BitSet. | `std/containers` |
| [BitSet.SymmetricDifferenceWith](Category-BitSet#members) | Keeps only the bits that are set in exactly one of the two BitSets. | `std/containers` |
| [BitSet.IsSubsetOf](Category-BitSet#set-algebra) | Returns true if every bit set here is also set in another BitSet. | `std/containers` |
| [BitSet.Equals](Category-BitSet#set-algebra) | Returns true if both BitSets have the same bits set, whatever their lengths. | `std/containers` |

## Find the first, last or nearest key

| Function | What it does | From |
|---|---|---|
| [OrderedMap.TryFirst](Modern-OrderedMap-TryFirst) | Copies the smallest key and its value into variables; returns false if the map is empty. | `std/containers` |
| [OrderedMap.TryLast](Modern-OrderedMap-TryLast) | Copies the largest key and its value into variables; returns false if the map is empty. | `std/containers` |
| [OrderedMap.TryFloor](Modern-OrderedMap-TryFloor) | Finds the largest key at or below a given one; returns false if there is none. | `std/containers` |
| [OrderedMap.TryCeiling](Modern-OrderedMap-TryCeiling) | Finds the smallest key at or above a given one; returns false if there is none. | `std/containers` |
| [OrderedSet.TryFirst](Modern-OrderedSet-TryFirst) | Copies the smallest value into a variable; returns false if the set is empty. | `std/containers` |
| [OrderedSet.TryLast](Modern-OrderedSet-TryLast) | Copies the largest value into a variable; returns false if the set is empty. | `std/containers` |
| [OrderedSet.TryFloor](Modern-OrderedSet-TryFloor) | Finds the largest value at or below a given one; returns false if there is none. | `std/containers` |
| [OrderedSet.TryCeiling](Modern-OrderedSet-TryCeiling) | Finds the smallest value at or above a given one; returns false if there is none. | `std/containers` |

## BitSet: flags by number

| Function | What it does | From |
|---|---|---|
| [BitSet.Set](Category-BitSet#members) | Sets a bit, or clears it when given false, growing the BitSet as needed. | `std/containers` |
| [BitSet.Reset](Category-BitSet#members) | Clears a bit. | `std/containers` |
| [BitSet.Flip](Category-BitSet#members) | Flips a bit, so a set bit becomes clear and a clear bit becomes set. | `std/containers` |
| [BitSet.Test](Category-BitSet#members) | Returns true if a bit is set; a bit beyond Length is never set. | `std/containers` |
| [BitSet.CountOnes](Category-BitSet#members) | Counts the bits that are set. | `std/containers` |
| [BitSet.FirstSet](Category-BitSet#members) | Returns the first set bit at or after a position, or -1 if there is none. | `std/containers` |
| [BitSet.NextClear](Category-BitSet#members) | Returns the first clear bit at or after a position. | `std/containers` |
| [BitSet.SetAll](Category-BitSet#members) | Sets every bit below Length. | `std/containers` |
| [BitSet.ClearAll](Category-BitSet#members) | Clears every bit. | `std/containers` |
| [BitSet.IsEmpty](Category-BitSet#members) | Returns true if no bit is set. | `std/containers` |
| [BitSet.Length](Category-BitSet#growth-and-length) | Returns the number of addressable bits, which is not the number that are set. | `std/containers` |
| [BitSet.Resize](Category-BitSet#growth-and-length) | Grows or shrinks the BitSet; shrinking clears the bits that fall off. | `std/containers` |

## Rearrange an Array

| Function | What it does | From |
|---|---|---|
| [ReverseArray](Category-Searching#rearranging-in-place) | Reverses the order of an Array's elements in place. | `std/containers` |
| [RotateArray](Category-Searching#rearranging-in-place) | Rotates an Array left by k places, so element k comes first; negative k rotates right. | `std/containers` |
| [Dedup](Category-Searching#rearranging-in-place) | Removes consecutive duplicates, keeping the first of each run; returns how many went. | `std/containers` |
| [DedupBy](Category-Searching#rearranging-in-place) | Removes consecutive elements your test calls equal; returns how many went. | `std/containers` |
| [NextPermutation](Category-Searching#rearranging-in-place) | Rearranges into the next permutation in sorted order; returns false after the last. | `std/containers` |
| [NextPermutationBy](Category-Searching#rearranging-in-place) | Rearranges into the next permutation by your comparer; returns false after the last. | `std/containers` |
| [PartialSort](Category-Searching#rearranging-in-place) | Puts the k smallest elements, sorted, at the front; the rest are left in no order. | `std/containers` |
| [PartialSortBy](Category-Searching#rearranging-in-place) | Puts the k first elements by your comparer, sorted, at the front. | `std/containers` |
| [NthElement](Category-Searching#rearranging-in-place) | Puts at index k the element a full sort would put there, without sorting the rest. | `std/containers` |
| [ShuffleArray](Modern-Math-Shuffle#containers) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [NthElementBy](Category-Searching#rearranging-in-place) | Puts at index k the element a sort by your comparer would put there. | `std/containers` |

## Walk a container step by step

| Function | What it does | From |
|---|---|---|
| [Array.GetIterator](Modern-Array-GetIterator) | Returns an iterator over the elements, for stepping through them by hand. | `std/containers` |
| [ArrayIterator](Modern-Array-ArrayIterator) | Holds a position in an Array; steps with IsValid, Value and MoveNext. | `std/containers` |
| [Map.GetIterator](Modern-Map-GetIterator) | Returns an iterator over the entries, each a pair read through .key and .value. | `std/containers` |
| [MapIterator](Modern-Map-MapIterator) | Holds a position in a Map; each step gives a pair read through .key and .value. | `std/containers` |
| [MapPairView](Modern-Map-MapPairView) | Holds the view that Map.Pairs returns, for for each (k, v) to walk. | `std/containers` |
| [MapPairIter](Modern-Map-MapPairIter) | Holds a position in Map.Pairs; each step gives the key and value as a tuple. | `std/containers` |
| [Set.GetIterator](Modern-Set-GetIterator) | Returns an iterator over the values, in no particular order. | `std/containers` |
| [SetIterator](Modern-Set-SetIterator) | Holds a position in a Set; changing a value through it loses that value. | `std/containers` |
| [LinkedList.GetIterator](Modern-LinkedList-GetIterator) | Returns an iterator over the values that stays valid when others are added. | `std/containers` |
| [LinkedListIterator](Modern-LinkedList-LinkedListIterator) | Holds a position in a LinkedList; it survives changes elsewhere in the list. | `std/containers` |
| [OrderedMap.GetIterator](Modern-OrderedMap-GetIterator) | Returns an iterator over the entries in ascending key order. | `std/containers` |
| [OrderedMapIterator](Modern-OrderedMap-OrderedMapIterator) | Holds a position in an OrderedMap, stepping in ascending key order. | `std/containers` |
| [OrderedMapPairView](Modern-OrderedMap-OrderedMapPairView) | Holds the view that OrderedMap.Pairs returns, for for each (k, v) to walk. | `std/containers` |
| [OrderedMapPairIter](Modern-OrderedMap-OrderedMapPairIter) | Holds a position in OrderedMap.Pairs, giving key and value as a tuple in key order. | `std/containers` |
| [OrderedSet.GetIterator](Modern-OrderedSet-GetIterator) | Returns an iterator over the values in ascending order. | `std/containers` |
| [OrderedSetIterator](Modern-OrderedSet-OrderedSetIterator) | Holds a position in an OrderedSet, stepping in ascending order. | `std/containers` |
| [Deque.GetIterator](Category-Deque#members) | Returns an iterator that walks the deque from front to back. | `std/containers` |
| [PriorityQueue.GetIterator](Category-PriorityQueue#members) | Returns an iterator over the values in heap order, which is not priority order. | `std/containers` |
| [BitSet.GetIterator](Category-BitSet#members) | Returns an iterator over the set bits, in ascending order. | `std/containers` |

## Reserve room ahead of time

| Function | What it does | From |
|---|---|---|
| [Array.Capacity](Modern-Array-Capacity) | Returns how many elements fit before the array has to grow. | `std/containers` |
| [Array.Reserve](Modern-Array-Reserve) | Makes room for at least n elements without adding any; it never shrinks. | `std/containers` |
| [Array.Shrink](Modern-Array-Shrink) | Releases unused room, cutting the capacity down to the count. | `std/containers` |
| [Map.Capacity](Modern-Map-Capacity) | Returns the number of slots in the table, always a power of two. | `std/containers` |
| [Map.Reserve](Modern-Map-Reserve) | Makes room for n entries, so filling the map does not have to regrow it. | `std/containers` |
| [Set.Capacity](Modern-Set-Capacity) | Returns the number of slots in the table, always a power of two. | `std/containers` |
| [Set.Reserve](Modern-Set-Reserve) | Makes room for n values, so filling the set does not have to regrow it. | `std/containers` |
| [Deque.Capacity](Category-Deque#members) | Returns how many values fit before the deque has to grow, always a power of two. | `std/containers` |
| [Deque.Reserve](Category-Deque#members) | Makes room for at least n values without adding any. | `std/containers` |
| [PriorityQueue.Reserve](Category-PriorityQueue#members) | Makes room for at least n values without adding any. | `std/containers` |

## Check a container's internals

| Function | What it does | From |
|---|---|---|
| [OrderedMap.BlackHeight](Modern-OrderedMap-BlackHeight) | Returns the tree's black height, or -1 if its balancing rules are broken. | `std/containers` |
| [OrderedSet.BlackHeight](Modern-OrderedSet-BlackHeight) | Returns the tree's black height, or -1 if its balancing rules are broken. | `std/containers` |
| [LinkedNode](Modern-LinkedList-LinkedNode) | Holds one LinkedList value and the links to its neighbours; normal code never uses it. | `std/containers` |

## See Also

- [Array guide](Category-Array)
- [Map guide](Category-Map)
- [OrderedMap and OrderedSet guide](Category-OrderedMap)
- [Sorting guide](Category-Sorting)
- [Collection initializers](Category-Collection-Initializers)

---

[Home](Home) · [Function Finder](Function-Finder) · [Keyword Index](Keyword-Index)

<!-- Generated by tools/wikifinder/finder.py. Edit the data, not this page. -->
