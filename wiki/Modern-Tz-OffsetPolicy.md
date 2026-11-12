[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **OffsetPolicy**

# OffsetPolicy

Chooses what parsing does when the text's offset and its zone disagree.

## Syntax

```freebasic
enum OffsetPolicy : opReject, opUse, opPrefer, opIgnore
```

## Notes

- `opReject` (the default): the text is refused.
- `opUse`: the offset decides the moment; the zone gives its reading.
- `opPrefer`: the offset where the zone allows it for that reading, otherwise the reading.
- `opIgnore`: the wall-clock reading, resolved in the zone.
- This happens when a zone's rules changed after the text was written.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as ustring s = "2025-07-04T12:00:00-05:00[America/New_York]"
dim as ZonedDateTime r
print ZonedDateTime.TryParseIso( s, r )             '' false
print ZonedDateTime.TryParseIso( s, r, opUse )      '' true
print r.Hour                                        '' 13
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** ZonedDateTime
