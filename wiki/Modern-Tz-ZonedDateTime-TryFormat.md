[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **ZonedDateTime.TryFormat**

# ZonedDateTime.TryFormat

Formats the value through a pattern, returning false for a bad pattern.

## Syntax

```freebasic
ZonedDateTime.TryFormat( byref pattern as const ustring, byref result as ustring ) as boolean
```

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ZonedDateTime z = ZonedDateTime.FromInstant( chrono.Instant.ParseIso( "2025-07-04T16:00:00Z" ), TimeZone.FindById( "America/New_York" ) )
dim as ustring s
print z.TryFormat( "HH:mm VV", s )      '' true
print s                                  '' 12:00 America/New_York
print z.TryFormat( "HH:mm VVV", s )     '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
