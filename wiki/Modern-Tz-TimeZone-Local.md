[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.Local**

# TimeZone.Local

Returns the machine's own time zone, answered by the operating system.

## Syntax

```freebasic
TimeZone.Local( ) as TimeZone
```

## Notes

- It agrees with [TimeZoneInfo](Modern-Chrono-TimeZoneInfo-LocalOffsetAt) everywhere.
- Its [Id](Modern-Tz-TimeZone-Id) is the machine's IANA id where one can be found: from `TZ` or `/etc/localtime` on Linux and macOS, and on Windows from the zone's Windows name through CLDR's table when the zone can be loaded. Otherwise it is "".
- Transitions of the Local zone are found by scanning ten years a day at a time: a change further away is not reported.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone here = TimeZone.Local( )
print here.IsValid          '' true
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
