[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.Invalid**

# ZonedDateTime.Invalid

Returns an Invalid ZonedDateTime, the value arithmetic gives outside the years 1 to 9999.

## Syntax

```freebasic
ZonedDateTime.Invalid( ) as ZonedDateTime
```

## Notes

- An Invalid value carries through arithmetic and conversions. Reading one of its fields is runtime error 1.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
print ZonedDateTime.Invalid( ).IsValid      '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
