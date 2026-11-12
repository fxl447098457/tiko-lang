[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.WithZoneSameInstant**

# ZonedDateTime.WithZoneSameInstant

Returns the same moment as it reads in another time zone.

## Syntax

```freebasic
ZonedDateTime.WithZoneSameInstant( byref z as TimeZone ) as ZonedDateTime
```

## Notes

- Converts: the moment is kept and the wall-clock reading changes. [WithZoneSameLocal](Modern-Tz-ZonedDateTime-WithZoneSameLocal) does the opposite.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.WithZoneSameInstant( TimeZone.FindById( "Asia/Tokyo" ) ).ToIsoString( )      '' 2025-07-05T01:00:00+09:00[Asia/Tokyo]
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
