[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.OffsetSecondsAt**

# TimeZone.OffsetSecondsAt

Returns the zone's offset from UTC in seconds at a given moment.

## Syntax

```freebasic
TimeZone.OffsetSecondsAt( byref i as chrono.Instant ) as long
```

## Notes

- Seconds, not minutes: before standard time, local mean time had offsets like Amsterdam's +00:19:32.
- An Invalid instant is runtime error 1.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant july = chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" )
print ny.OffsetSecondsAt( july )      '' -14400
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
