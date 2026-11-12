[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.CompareTo**

# ZonedDateTime.CompareTo

Compares two values by the moment they name: -1, 0 or 1.

## Syntax

```freebasic
ZonedDateTime.CompareTo( byref o as ZonedDateTime ) as long
```

## Notes

- The same moment in two zones compares 0, but `=` is false: equality asks for the same zone too. `<`, `>`, `<=` and `>=` compare moments.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
dim as ZonedDateTime t = z.WithZoneSameInstant( TimeZone.FindById( "Asia/Tokyo" ) )
print z.CompareTo( t )      '' 0
print z = t                 '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
