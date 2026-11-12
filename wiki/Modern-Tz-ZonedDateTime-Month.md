[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.Month**

# ZonedDateTime.Month

Returns the month, 1 to 12 of the wall-clock reading in the zone.

## Syntax

```freebasic
ZonedDateTime.Month as long
```

## Notes

- Runtime error 1 for an Invalid value.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.Month      '' 7
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
