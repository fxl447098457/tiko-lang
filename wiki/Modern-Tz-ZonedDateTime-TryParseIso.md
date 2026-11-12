[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.TryParseIso**

# ZonedDateTime.TryParseIso

Reads ISO 8601 text with a [Zone/Id] annotation, returning false if it cannot.

## Syntax

```freebasic
ZonedDateTime.TryParseIso( byref s as const ustring, byref result as ZonedDateTime, byval offsets as OffsetPolicy = opReject, byval policy as Disambiguation = dzCompatible ) as boolean
```

## Notes

- The zone annotation is required. Before it, an offset (`Z`, `+05`, `+0530`, `+05:30`, with seconds too) or none; a date alone means the start of that day.
- When the text's offset is not the zone's for that reading, [OffsetPolicy](Modern-Tz-OffsetPolicy) decides. A `Z` always names the moment.
- Other annotations are ignored unless marked critical with `!`; `u-ca` may only be `gregory` or `iso8601`.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime r
print ZonedDateTime.TryParseIso( "2025-07-04T12:00-04:00[America/New_York]", r )      '' true
print r.ToInstant( ).ToIsoString( )                                                      '' 2025-07-04T16:00:00Z
print ZonedDateTime.TryParseIso( "2025-07-04T12:00-04:00", r )                         '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
