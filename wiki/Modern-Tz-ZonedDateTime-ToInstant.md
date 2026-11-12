[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.ToInstant**

# ZonedDateTime.ToInstant

Returns the moment a ZonedDateTime names.

## Syntax

```freebasic
ZonedDateTime.ToInstant( ) as chrono.Instant
```

## Notes

- Instant.Invalid for an Invalid value.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
print z.ToInstant( ).ToIsoString( )      '' 2025-07-04T16:00:00Z
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
