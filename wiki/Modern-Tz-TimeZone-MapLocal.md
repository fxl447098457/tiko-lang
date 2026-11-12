[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.MapLocal**

# TimeZone.MapLocal

Counts the moments a wall-clock reading names in the zone: 1, 2 or 0.

## Syntax

```freebasic
TimeZone.MapLocal( byref wall as chrono.DateTime, byref a as chrono.Instant, byref b as chrono.Instant ) as long
```

## Notes

- 2 when the clocks went back and the reading happened twice; 0 when they went forward and it never happened. `a` and `b` hold the moments, earlier first.
- The reading's own offset, if it has one, is ignored.
- To pick one moment, use [TryResolve](Modern-Tz-TimeZone-TryResolve) or [Resolve](Modern-Tz-TimeZone-Resolve).

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant a, b
print ny.MapLocal( chrono.DateTime( 2025, 11, 2, 1, 30, 0, 0 ), a, b )     '' 2
print a.ToIsoString( )                                                     '' 2025-11-02T05:30:00Z
print b.ToIsoString( )                                                     '' 2025-11-02T06:30:00Z
print ny.MapLocal( chrono.DateTime( 2025, 3, 9, 2, 30, 0, 0 ), a, b )      '' 0
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
