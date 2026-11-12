[Home](Home) › [Date and Time (Chrono)](Category-Date-and-Time-Chrono) › [Chrono Date and Time](Category-Date-and-Time-Chrono) › **TimeZoneInfo.DaylightName**

# TimeZoneInfo.DaylightName

Returns the OS's name for the local zone's daylight saving time.

## Syntax

```freebasic
TimeZoneInfo.DaylightName( ) as ustring
```

## Notes

- For display only, like `StandardName`: a display name on Windows, an abbreviation on Linux and macOS.
- A zone with no daylight saving time gives the standard name on Linux and macOS; Windows gives its own daylight name for the zone even then.
- An empty string when the OS gives no name.

## Examples

```freebasic
#import "std/chrono"
using chrono

'' For example "Eastern Daylight Time"
if TimeZoneInfo.SupportsDaylightSavingTime( ) then
    print TimeZoneInfo.DaylightName( ) <> ""  '' -1 (true)
end if
```

---

**Library:** [Chrono Date and Time](Category-Date-and-Time-Chrono)  
**Category:** [Date and Time (Chrono)](Category-Date-and-Time-Chrono)  
**Documented under:** The Members
