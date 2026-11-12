[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.IsDaylightSavingTime**

# TimeZone.IsDaylightSavingTime

Returns true if the zone's rules call that moment daylight time.

## Syntax

```freebasic
TimeZone.IsDaylightSavingTime( byref i as chrono.Instant ) as boolean
```

## Notes

- This is the database's own flag. Europe/Dublin's winter is "daylight time" at +00:00 there, because Irish standard time is the summer's +01:00.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant july = chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" )
print ny.IsDaylightSavingTime( july )      '' true
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
