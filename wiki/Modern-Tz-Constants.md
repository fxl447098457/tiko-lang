[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TZ_MIN_UNIX and TZ_MAX_UNIX**

# TZ_MIN_UNIX and TZ_MAX_UNIX

Gives the range std/tz works in, 0001-01-01 to 9999-12-31, in Unix seconds.

## Syntax

```freebasic
const TZ_MIN_UNIX as longint = -62135596800
const TZ_MAX_UNIX as longint = 253402300799
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
print chrono.Instant.FromUnixSeconds( TZ_MIN_UNIX ).ToIsoString( )      '' 0001-01-01T00:00:00Z
print chrono.Instant.FromUnixSeconds( TZ_MAX_UNIX ).ToIsoString( )      '' 9999-12-31T23:59:59Z
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
