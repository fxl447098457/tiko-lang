[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.IsValid**

# TzRules.IsValid

Returns true if the rules were read; a dim'd TzRules has none.

## Syntax

```freebasic
TzRules.IsValid as boolean
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
print r.IsValid      '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
