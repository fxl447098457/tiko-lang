[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.RegisterDatabase**

# TimeZone.RegisterDatabase

Gives std/tz a zone database to fall back on, in the .tzdb format tools/tzdb makes.

## Syntax

```freebasic
TimeZone.RegisterDatabase( byval p as const ubyte ptr, byval n as longint ) as boolean
```

## Notes

- `#import "std/tzdata"` calls this for you with the database it embeds. Call it yourself only to use a database of your own.
- The bytes are read in place and must stay valid for the life of the program -- an `#embed` does.
- The first registration is kept; later ones, and bytes that are not a database, return false.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as string notADatabase = "hello"
print TimeZone.RegisterDatabase( cptr( const ubyte ptr, strptr( notADatabase ) ), len( notADatabase ) )   '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
