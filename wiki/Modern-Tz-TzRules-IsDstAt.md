[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.IsDstAt**

# TzRules.IsDstAt

Returns true if the rules call a moment, given in Unix seconds, daylight time.

## Syntax

```freebasic
TzRules.IsDstAt( byval t as longint ) as boolean
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
TzRules.TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
print r.IsDstAt( 1751644800 )      '' true
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
