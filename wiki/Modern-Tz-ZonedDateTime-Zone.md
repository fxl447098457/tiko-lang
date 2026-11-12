[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.Zone**

# ZonedDateTime.Zone

Returns the time zone of a ZonedDateTime.

## Syntax

```freebasic
ZonedDateTime.Zone as TimeZone
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.Zone.Id      '' America/New_York
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
