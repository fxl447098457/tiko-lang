[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **Disambiguation**

# Disambiguation

Chooses what a wall-clock reading that happened twice, or never, should mean.

## Syntax

```freebasic
enum Disambiguation : dzCompatible, dzEarlier, dzLater, dzReject
```

## Notes

- `dzCompatible` (the default): of two, the earlier; a skipped reading moves forward by the length of the gap.
- `dzEarlier`: of two, the earlier; a skipped reading moves back by the gap.
- `dzLater`: of two, the later; a skipped reading moves forward by the gap.
- `dzReject`: neither is accepted.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.DateTime twice = chrono.DateTime( 2025, 11, 2, 1, 30, 0, 0 )
print ny.Resolve( twice, dzEarlier ).ToIsoString( )     '' 2025-11-02T05:30:00Z
print ny.Resolve( twice, dzLater ).ToIsoString( )       '' 2025-11-02T06:30:00Z
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
