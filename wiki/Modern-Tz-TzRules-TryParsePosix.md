[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.TryParsePosix**

# TzRules.TryParsePosix

Reads one zone's rules from a POSIX TZ string such as EST5EDT,M3.2.0,M11.1.0.

## Syntax

```freebasic
TzRules.TryParsePosix( byref s as string, byref result as TzRules ) as boolean
```

## Notes

- The offset is POSIX's: hours ADDED to local time to reach UTC, so `EST5` is five hours behind.
- Rules are `Jn`, `n` or `Mm.w.d`, with an optional `/time` up to 167 hours. A daylight name with no rules gets `M3.2.0,M11.1.0`.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
TzRules.TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
print r.IsValid                                '' true
print r.OffsetSecondsAt( 1751644800 )          '' -14400
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
