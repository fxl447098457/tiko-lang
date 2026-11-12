[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.Id**

# TimeZone.Id

Returns the zone's id: its IANA name, UTC, or a fixed offset such as +05:30.

## Syntax

```freebasic
TimeZone.Id as ustring
```

## Notes

- "" for an Invalid zone, and for the [Local](Modern-Tz-TimeZone-Local) zone when its IANA id is unknown.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
print TimeZone.FindById( "america/NEW_york" ).Id     '' America/New_York
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
