[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.OffsetSecondsAt**

# TzRules.OffsetSecondsAt

Returns the offset from UTC in seconds at a moment given in Unix seconds.

## Syntax

```freebasic
TzRules.OffsetSecondsAt( byval t as longint ) as long
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
TzRules.TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
print r.OffsetSecondsAt( 1735689600 )      '' -18000
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
