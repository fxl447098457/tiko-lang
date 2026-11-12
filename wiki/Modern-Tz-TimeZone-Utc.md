[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.Utc**

# TimeZone.Utc

Returns the UTC time zone, which needs no zone database.

## Syntax

```freebasic
TimeZone.Utc( ) as TimeZone
```

## Notes

- `FindById( "UTC" )` returns the same zone.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone u = TimeZone.Utc( )
print u.Id                                                          '' UTC
print u.OffsetSecondsAt( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ) )   '' 0
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
