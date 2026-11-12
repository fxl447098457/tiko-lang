[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.IsValid**

# TimeZone.IsValid

Returns true if the time zone refers to a zone; a dim'd TimeZone does not.

## Syntax

```freebasic
TimeZone.IsValid as boolean
```

## Notes

- Every lookup on an Invalid zone is runtime error 1.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone none
print none.IsValid                                     '' false
print TimeZone.FindById( "Europe/Paris" ).IsValid      '' true
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
