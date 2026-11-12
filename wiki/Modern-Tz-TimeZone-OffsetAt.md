[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.OffsetAt**

# TimeZone.OffsetAt

Returns the zone's offset from UTC at a given moment as a TimeSpan.

## Syntax

```freebasic
TimeZone.OffsetAt( byref i as chrono.Instant ) as chrono.TimeSpan
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant july = chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" )
print ny.OffsetAt( july ).TotalHours      '' -4
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
