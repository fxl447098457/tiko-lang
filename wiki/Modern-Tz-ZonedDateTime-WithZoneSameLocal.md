[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.WithZoneSameLocal**

# ZonedDateTime.WithZoneSameLocal

Returns the same wall-clock reading in another time zone, which is a different moment.

## Syntax

```freebasic
ZonedDateTime.WithZoneSameLocal( byref z as TimeZone, byval policy as Disambiguation = dzCompatible ) as ZonedDateTime
```

## Notes

- Reinterprets: the reading is kept and the moment changes. Runtime error 1 where the policy refuses the reading in the new zone.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.WithZoneSameLocal( TimeZone.FindById( "Asia/Tokyo" ) ).ToIsoString( )      '' 2025-07-04T12:00:00+09:00[Asia/Tokyo]
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
