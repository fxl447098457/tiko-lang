[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.AbbreviationAt**

# TimeZone.AbbreviationAt

Returns the zone's abbreviation at a given moment, such as EST or CEST.

## Syntax

```freebasic
TimeZone.AbbreviationAt( byref i as chrono.Instant ) as ustring
```

## Notes

- For display only: `CST` is the abbreviation of three different zones, so it cannot be looked up.
- A fixed zone's abbreviation is its id. The [Local](Modern-Tz-TimeZone-Local) zone gives the operating system's names for this year.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as chrono.Instant july = chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" )
print ny.AbbreviationAt( july )      '' EDT
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
