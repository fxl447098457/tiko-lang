[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.TryFromLocal**

# ZonedDateTime.TryFromLocal

Makes a wall-clock reading in a time zone, returning false when the policy refuses it.

## Syntax

```freebasic
ZonedDateTime.TryFromLocal( byref wall as chrono.DateTime, byref z as TimeZone, byval policy as Disambiguation, byref result as ZonedDateTime ) as boolean
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as ZonedDateTime r
print ZonedDateTime.TryFromLocal( chrono.DateTime( 2025, 11, 2, 1, 30, 0, 0 ), ny, dzReject, r )   '' false
print ZonedDateTime.TryFromLocal( chrono.DateTime( 2025, 11, 2, 1, 30, 0, 0 ), ny, dzLater, r )    '' true
print r.Abbreviation                                                                               '' EST
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
