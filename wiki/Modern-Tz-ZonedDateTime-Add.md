[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.Add**

# ZonedDateTime.Add

Adds elapsed time, whatever the clocks do meanwhile.

## Syntax

```freebasic
ZonedDateTime.Add( byref s as chrono.TimeSpan ) as ZonedDateTime
```

## Notes

- Across a change of offset the wall-clock reading moves by more or less than the span. For "the same time tomorrow" use [AddCalendarDays](Modern-Tz-ZonedDateTime-AddCalendarDays).

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as ZonedDateTime m = ZonedDateTime.FromLocal( chrono.DateTime( 2025, 3, 8, 12, 0, 0, 0 ), ny )
print m.Add( chrono.TimeSpan.FromHours( 24 ) ).ToIsoString( )      '' 2025-03-09T13:00:00-04:00[America/New_York]
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
