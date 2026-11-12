[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.StandardOffsetSecondsAt**

# TzRules.StandardOffsetSecondsAt

Returns the standard offset in seconds at a moment in Unix seconds, leaving DST out.

## Syntax

```freebasic
TzRules.StandardOffsetSecondsAt( byval t as longint ) as long
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
TzRules.TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
print r.StandardOffsetSecondsAt( 1751644800 )      '' -18000
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
