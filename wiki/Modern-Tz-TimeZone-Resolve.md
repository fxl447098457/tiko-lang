[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.Resolve**

# TimeZone.Resolve

Returns the moment a wall-clock reading names in the zone, or stops with an error.

## Syntax

```freebasic
TimeZone.Resolve( byref wall as chrono.DateTime, byval policy as Disambiguation = dzCompatible ) as chrono.Instant
```

## Notes

- Runtime error 1 where [TryResolve](Modern-Tz-TimeZone-TryResolve) would return false. With the default `dzCompatible` that is only outside the years 1 to 9999.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
print ny.Resolve( chrono.DateTime( 2025, 7, 4, 12, 0, 0, 0 ) ).ToIsoString( )   '' 2025-07-04T16:00:00Z
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
