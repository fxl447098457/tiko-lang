[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.FromInstant**

# ZonedDateTime.FromInstant

Returns a moment as it reads in a time zone.

## Syntax

```freebasic
ZonedDateTime.FromInstant( byref i as chrono.Instant, byref z as TimeZone ) as ZonedDateTime
```

## Notes

- An Invalid instant or zone is runtime error 1.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant july = chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" )
print ZonedDateTime.FromInstant( july, ny ).ToIsoString( )     '' 2025-07-04T12:00:00-04:00[America/New_York]
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
