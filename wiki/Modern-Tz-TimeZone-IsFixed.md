[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.IsFixed**

# TimeZone.IsFixed

Returns true if the zone is UTC or a fixed offset, with no rules that change.

## Syntax

```freebasic
TimeZone.IsFixed as boolean
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
print TimeZone.Utc( ).IsFixed                          '' true
print TimeZone.FindById( "Europe/Paris" ).IsFixed      '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
