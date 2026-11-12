[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.ToWall**

# ZonedDateTime.ToWall

Returns the wall-clock reading alone, as a DateTime with no offset.

## Syntax

```freebasic
ZonedDateTime.ToWall( ) as chrono.DateTime
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.ToWall( ).ToIsoString( )      '' 2025-07-04T12:00:00
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
