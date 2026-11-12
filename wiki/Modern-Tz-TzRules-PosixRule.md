[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.PosixRule**

# TzRules.PosixRule

Returns the POSIX TZ rule that covers the years after the file's last transition.

## Syntax

```freebasic
TzRules.PosixRule as ustring
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
TzRules.TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
print r.PosixRule      '' EST5EDT,M3.2.0,M11.1.0
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
