[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.StartOfDay**

# ZonedDateTime.StartOfDay

Returns the first moment of the date in the zone, which is not always midnight.

## Syntax

```freebasic
ZonedDateTime.StartOfDay( ) as ZonedDateTime
```

## Notes

- Where the clocks went forward at midnight, the day began at 01:00.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone sp = TimeZone.FindById( "America/Sao_Paulo" )
dim as ZonedDateTime m = ZonedDateTime.FromLocal( chrono.DateTime( 2018, 11, 4, 15, 0, 0, 0 ), sp )
print m.StartOfDay( ).ToIsoString( )      '' 2018-11-04T01:00:00-02:00[America/Sao_Paulo]
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
