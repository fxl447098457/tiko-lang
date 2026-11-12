[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.StandardOffsetAt**

# TimeZone.StandardOffsetAt

Returns the zone's standard offset at a given moment, leaving daylight time out.

## Syntax

```freebasic
TimeZone.StandardOffsetAt( byref i as chrono.Instant ) as chrono.TimeSpan
```

## Notes

- Outside daylight time it is the offset itself.
- Compare it with [OffsetAt](Modern-Tz-TimeZone-OffsetAt) to ask whether the clocks are ahead of standard time.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant july = chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" )
print ny.StandardOffsetAt( july ).TotalHours      '' -5
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
