[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.AbbreviationAt**

# TzRules.AbbreviationAt

Returns the zone's abbreviation at a moment given in Unix seconds.

## Syntax

```freebasic
TzRules.AbbreviationAt( byval t as longint ) as ustring
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
TzRules.TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
print r.AbbreviationAt( 1735689600 )      '' EST
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
