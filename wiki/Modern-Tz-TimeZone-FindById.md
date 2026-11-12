[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.FindById**

# TimeZone.FindById

Returns the time zone with an IANA id such as Europe/Paris, or stops with an error.

## Syntax

```freebasic
TimeZone.FindById( byref zoneId as const ustring ) as TimeZone
```

## Notes

- The id is matched without regard to case and comes back spelled as the database spells it.
- An id that is not found is runtime error 1. Use [TryFindById](Modern-Tz-TimeZone-TryFindById) for ids from outside the program.
- Where zones come from: `$TZDIR`, then the system's zone files on Linux and macOS, then the database `std/tzdata` puts in the program.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone paris = TimeZone.FindById( "europe/paris" )
print paris.Id      '' Europe/Paris
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
