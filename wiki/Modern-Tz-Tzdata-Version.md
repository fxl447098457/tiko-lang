[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **tzdata.Version**

# tzdata.Version

Returns the release of the zone database std/tzdata puts in the program, such as 2026f.

## Syntax

```freebasic
tzdata.Version( ) as ustring
```

## Notes

- Importing `std/tzdata` is all a program has to do: the database is registered with std/tz when the program starts.
- Where the system has zone files of its own, they are read first. [TimeZone.DataVersion](Modern-Tz-TimeZone-DataVersion) says which one a program is using.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
print tzdata.Version( )      '' 2026f
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** std/tzdata
