[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.Version**

# TzRules.Version

Returns the zone file's format version, 1 to 4, or 0 for rules from a POSIX TZ string.

## Syntax

```freebasic
TzRules.Version as long
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
TzRules.TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
print r.Version      '' 0
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
