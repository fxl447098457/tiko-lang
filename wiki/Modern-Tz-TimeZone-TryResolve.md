[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.TryResolve**

# TimeZone.TryResolve

Turns a wall-clock reading in the zone into one moment, under a Disambiguation policy.

## Syntax

```freebasic
TimeZone.TryResolve( byref wall as chrono.DateTime, byval policy as Disambiguation, byref result as chrono.Instant ) as boolean
```

## Notes

- False when the policy refuses the reading (`dzReject` on a repeated or skipped reading), or it falls outside the years 1 to 9999.
- See [Disambiguation](Modern-Tz-Disambiguation) for what each policy does.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant r
print ny.TryResolve( chrono.DateTime( 2025, 3, 9, 2, 30, 0, 0 ), dzCompatible, r )    '' true
print r.ToIsoString( )                                                               '' 2025-03-09T07:30:00Z
print ny.TryResolve( chrono.DateTime( 2025, 3, 9, 2, 30, 0, 0 ), dzReject, r )        '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
