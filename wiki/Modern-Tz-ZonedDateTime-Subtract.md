[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.Subtract**

# ZonedDateTime.Subtract

Subtracts elapsed time, whatever the clocks do meanwhile.

## Syntax

```freebasic
ZonedDateTime.Subtract( byref s as chrono.TimeSpan ) as ZonedDateTime
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.Subtract( chrono.TimeSpan.FromHours( 6 ) ).Hour      '' 6
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
