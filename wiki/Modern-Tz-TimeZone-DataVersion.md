[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TimeZone.DataVersion**

# TimeZone.DataVersion

Returns the tz database release the first zone source holds, such as 2026f.

## Syntax

```freebasic
TimeZone.DataVersion( ) as ustring
```

## Notes

- "" when the source does not say.
- Where both are present, the system's files are read before the copy `std/tzdata` adds, so this tells you which one the program is using.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
print cbool( len( TimeZone.DataVersion( ) ) > 0 )     '' true
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TimeZone
