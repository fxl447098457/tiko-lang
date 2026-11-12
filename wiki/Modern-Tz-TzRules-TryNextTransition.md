[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.TryNextTransition**

# TzRules.TryNextTransition

Finds the next change of offset after a moment, in Unix seconds.

## Syntax

```freebasic
TzRules.TryNextTransition( byval after as longint, byref result as longint ) as boolean
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
TzRules.TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
dim as longint t
print r.TryNextTransition( 1735689600, t )      '' true
print t                                          '' 1741503600
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
