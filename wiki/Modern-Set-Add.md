[Home](Home) › [Set](Category-Set) › [Set](Category-Set) › **Add**

# Add

Adds a value; returns false if it was already there.

## Syntax

```freebasic
Add( byref v as T ) as boolean
```

## Examples

```freebasic
#import "std/containers"
using containers

dim seen as Set( of ustring )

print seen.Add( "ada" )      '' true -- inserted
print seen.Add( "ada" )      '' false -- already there

'' Deduplicating a stream in one pass
dim as ustring names( 0 to 2 ) = { "ada", "grace", "ada" }
dim uniq as Set( of ustring )
for each n in names
    if uniq.Add( n ) then print "new: " & n
next
```

---

**Library:** [Set](Category-Set)  
**Category:** [Set](Category-Set)  
**Documented under:** Members
