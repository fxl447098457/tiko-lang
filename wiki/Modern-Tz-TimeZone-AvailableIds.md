[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.AvailableIds**

# TimeZone.AvailableIds

Returns every zone id the first zone source holds, sorted.

## Syntax

```freebasic
TimeZone.AvailableIds( ) as containers.Array( of ustring )
```

## Notes

- The first source that exists: `$TZDIR`, the system's zone files, or the database `std/tzdata` adds.
- Leaves out `Factory`, `localtime`, `posixrules` and the `posix/` and `right/` copies.
- Needs `#import "std/containers"` to hold the result.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
#import "std/containers"
using tz
dim as containers.Array( of ustring ) ids = TimeZone.AvailableIds( )
print cbool( ids.Count( ) > 300 )      '' true
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
