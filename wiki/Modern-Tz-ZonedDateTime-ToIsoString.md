[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.ToIsoString**

# ZonedDateTime.ToIsoString

Writes the value as ISO 8601 text with the zone in brackets, which reads back exactly.

## Syntax

```freebasic
ZonedDateTime.ToIsoString( ) as ustring
```

## Notes

- The offset has seconds only when they are not zero (`+00:19:32`), so a present-day value is plain RFC 3339 before the brackets.
- UTC writes `+00:00[UTC]`. A zone with no id writes no brackets, and that text does not read back as a ZonedDateTime.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.ToIsoString( )      '' 2025-07-04T12:00:00-04:00[America/New_York]
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
