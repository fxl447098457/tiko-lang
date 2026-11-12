[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.FromLocal**

# ZonedDateTime.FromLocal

Returns a wall-clock reading in a zone; a policy settles a repeated or skipped one.

## Syntax

```freebasic
ZonedDateTime.FromLocal( byref wall as chrono.DateTime, byref z as TimeZone, byval policy as Disambiguation = dzCompatible ) as ZonedDateTime
```

## Notes

- Runtime error 1 where [TryFromLocal](Modern-Tz-ZonedDateTime-TryFromLocal) would return false.
- See [Disambiguation](Modern-Tz-Disambiguation).

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as ZonedDateTime m = ZonedDateTime.FromLocal( chrono.DateTime( 2025, 3, 9, 2, 30, 0, 0 ), ny )
print m.ToIsoString( )      '' 2025-03-09T03:30:00-04:00[America/New_York]
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
