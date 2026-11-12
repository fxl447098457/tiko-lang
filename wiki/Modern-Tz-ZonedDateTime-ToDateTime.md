[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.ToDateTime**

# ZonedDateTime.ToDateTime

Returns the wall-clock reading with its offset as a chrono DateTime.

## Syntax

```freebasic
ZonedDateTime.ToDateTime( ) as chrono.DateTime
```

## Notes

- A DateTime holds whole minutes of offset. A historical offset with seconds is rounded to the nearest minute and the moment is kept, so the reading it shows moves by under 30 seconds.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.ToDateTime( ).ToIsoString( )      '' 2025-07-04T12:00:00-04:00
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
