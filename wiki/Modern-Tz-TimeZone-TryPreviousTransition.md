[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.TryPreviousTransition**

# TimeZone.TryPreviousTransition

Finds the last moment before a given moment when the zone's offset changed.

## Syntax

```freebasic
TimeZone.TryPreviousTransition( byref before as chrono.Instant, byref result as chrono.Instant ) as boolean
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant july = chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" )
dim as chrono.Instant t
print ny.TryPreviousTransition( july, t )     '' true
print t.ToIsoString( )                         '' 2025-03-09T07:00:00Z
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
