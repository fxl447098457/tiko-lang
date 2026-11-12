[Home](Home) › [Date and Time (Chrono)](Category-Date-and-Time-Chrono) › [Chrono Date and Time](Category-Date-and-Time-Chrono) › **TimeZoneInfo.StandardName**

# TimeZoneInfo.StandardName

Returns the OS's name for the local zone's standard time.

## Syntax

```freebasic
TimeZoneInfo.StandardName( ) as ustring
```

## Notes

- The name is whatever the OS calls the zone, for display only: it is not a key into any zone database.
- Windows gives a display name ("Newfoundland Standard Time"); Linux and macOS give an abbreviation ("NST").
- This year's name, not the name in force at any other time.
- An empty string when the OS gives no name.

## Examples

```freebasic
#import "std/chrono"
using chrono

'' For example "Eastern Standard Time" -- the OS's own wording
print TimeZoneInfo.StandardName( ) <> ""     '' -1 (true)
```

---

**Library:** [Chrono Date and Time](Category-Date-and-Time-Chrono)  
**Category:** [Date and Time (Chrono)](Category-Date-and-Time-Chrono)  
**Documented under:** The Members
