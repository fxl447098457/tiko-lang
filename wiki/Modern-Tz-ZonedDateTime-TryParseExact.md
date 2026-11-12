[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.TryParseExact**

# ZonedDateTime.TryParseExact

Reads text in a pattern that ends in VV, returning false if it does not match.

## Syntax

```freebasic
ZonedDateTime.TryParseExact( byref s as const ustring, byref pattern as const ustring, byref result as ZonedDateTime, byval offsets as OffsetPolicy = opReject, byval policy as Disambiguation = dzCompatible ) as boolean
```

## Notes

- `VV` must end the pattern; the longest zone id the text ends with is taken.
- `v` cannot be read back: an abbreviation does not name one zone.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime r
print ZonedDateTime.TryParseExact( "2025-07-04 12:00 Europe/Paris", "yyyy-MM-dd HH:mm VV", r )      '' true
print r.ToInstant( ).ToIsoString( )                                                                    '' 2025-07-04T10:00:00Z
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
