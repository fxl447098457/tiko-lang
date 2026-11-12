[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.FixedOffset**

# TimeZone.FixedOffset

Returns a time zone that is always a fixed number of seconds ahead of UTC.

## Syntax

```freebasic
TimeZone.FixedOffset( byval seconds as long ) as TimeZone
```

## Notes

- -18:00 to +18:00; anything else is runtime error 1.
- Its id is the offset: `+05:30`, or `+00:19:32` when there are seconds. `FixedOffset( 0 )` is `+00:00`, a different zone from `UTC`.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ist = TimeZone.FixedOffset( 5 * 3600 + 30 * 60 )
print ist.Id          '' +05:30
print ist.IsFixed     '' true
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
