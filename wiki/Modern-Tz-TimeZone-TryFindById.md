[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.TryFindById**

# TimeZone.TryFindById

Looks up a time zone by IANA id, returning false when there is no such zone.

## Syntax

```freebasic
TimeZone.TryFindById( byref zoneId as const ustring, byref result as TimeZone ) as boolean
```

## Notes

- The id is checked before any file is touched: letters, digits, `_`, `+` and `-` in segments joined by `/`. Anything else, `..` included, is simply not found.
- A link keeps the name asked for: `US/Eastern` is `US/Eastern`, with New York's rules.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone z
print TimeZone.TryFindById( "Asia/Tokyo", z )       '' true
print z.Id                                          '' Asia/Tokyo
print TimeZone.TryFindById( "Mars/Olympus", z )     '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
