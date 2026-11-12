[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.ToString**

# ZonedDateTime.ToString

Writes the value as ISO 8601 text, or through a pattern with VV for the zone id.

## Syntax

```freebasic
ZonedDateTime.ToString( ) as ustring
ZonedDateTime.ToString( byref pattern as const ustring ) as ustring
```

## Notes

- The pattern letters are std/chrono's, plus `VV` (the zone id) and `v` (the abbreviation). The fields show the wall-clock reading; `z` and `K` show the offset in whole minutes.
- A bad pattern is runtime error 1; [TryFormat](Modern-Tz-ZonedDateTime-TryFormat) returns false instead.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.ToString( "yyyy-MM-dd HH:mm v (VV)" )      '' 2025-07-04 12:00 EDT (America/New_York)
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
