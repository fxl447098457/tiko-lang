[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.ParseExact**

# ZonedDateTime.ParseExact

Reads text in a pattern that ends in VV, or stops with an error.

## Syntax

```freebasic
ZonedDateTime.ParseExact( byref s as const ustring, byref pattern as const ustring, byval offsets as OffsetPolicy = opReject, byval policy as Disambiguation = dzCompatible ) as ZonedDateTime
```

## Notes

- Runtime error 1 where [TryParseExact](Modern-Tz-ZonedDateTime-TryParseExact) would return false.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
print ZonedDateTime.ParseExact( "04/07/2025 09:15 Europe/London", "dd/MM/yyyy HH:mm VV" ).Abbreviation      '' BST
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
