[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.GetTimeOfDay**

# ZonedDateTime.GetTimeOfDay

Returns the time of day of the wall-clock reading.

## Syntax

```freebasic
ZonedDateTime.GetTimeOfDay( ) as chrono.LocalTime
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.GetTimeOfDay( ).ToIsoString( )      '' 12:00:00
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
