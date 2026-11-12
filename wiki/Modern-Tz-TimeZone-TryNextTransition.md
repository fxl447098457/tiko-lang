[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.TryNextTransition**

# TimeZone.TryNextTransition

Finds the next moment the zone's offset changes after a given moment.

## Syntax

```freebasic
TimeZone.TryNextTransition( byref after as chrono.Instant, byref result as chrono.Instant ) as boolean
```

## Notes

- A change that alters only the abbreviation or the daylight flag is not a transition: nothing on the clock moved.
- False when there is none before the year 9999.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant july = chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" )
dim as chrono.Instant t
print ny.TryNextTransition( july, t )     '' true
print t.ToIsoString( )                     '' 2025-11-02T06:00:00Z
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
