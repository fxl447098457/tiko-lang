[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.ParseIso**

# ZonedDateTime.ParseIso

Reads ISO 8601 text with a [Zone/Id] annotation, or stops with an error.

## Syntax

```freebasic
ZonedDateTime.ParseIso( byref s as const ustring, byval offsets as OffsetPolicy = opReject, byval policy as Disambiguation = dzCompatible ) as ZonedDateTime
```

## Notes

- Runtime error 1 where [TryParseIso](Modern-Tz-ZonedDateTime-TryParseIso) would return false.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
print ZonedDateTime.ParseIso( "2025-07-04T16:00:00Z[Asia/Tokyo]" ).Hour      '' 1
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
