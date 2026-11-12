[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.AddCalendarDays**

# ZonedDateTime.AddCalendarDays

Returns the same wall-clock time a number of days later, across any change of offset.

## Syntax

```freebasic
ZonedDateTime.AddCalendarDays( byval n as long ) as ZonedDateTime
```

## Notes

- Where the reading happens twice, the offset the value already had is kept; where it does not happen, it moves forward by the gap.
- Invalid outside the years 1 to 9999.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as ZonedDateTime m = ZonedDateTime.FromLocal( chrono.DateTime( 2025, 3, 8, 12, 0, 0, 0 ), ny )
print m.AddCalendarDays( 1 ).ToIsoString( )      '' 2025-03-09T12:00:00-04:00[America/New_York]
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
