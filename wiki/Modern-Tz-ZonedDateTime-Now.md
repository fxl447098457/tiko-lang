[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.Now**

# ZonedDateTime.Now

Returns the current moment as it reads in a time zone.

## Syntax

```freebasic
ZonedDateTime.Now( byref z as TimeZone ) as ZonedDateTime
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime now_ = ZonedDateTime.Now( TimeZone.FindById( "Asia/Tokyo" ) )
print now_.Zone.Id      '' Asia/Tokyo
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
