[Home](Home) › [Date and Time (Chrono)](Category-Date-and-Time-Chrono) › [Chrono Date and Time](Category-Date-and-Time-Chrono) › **DateTime.AssumeLocal**

# DateTime.AssumeLocal

Returns the moment the date-time names if its clock reading is taken as local time.

## Syntax

```freebasic
DateTime.AssumeLocal
```

## Examples

```freebasic
#import "std/chrono"
using chrono

dim as DateTime d = DateTime( 2026, 8, 13, 14, 30, 5, 123 )
'' Reads the clock value as a reading in the OS time zone, whatever offset
'' it carries -- the local twin of AssumeUtc. The offset used is the one in
'' force on 13 August, not today's.
dim as Instant i = d.AssumeLocal( )

'' The same clock reading again, now with the offset recorded
print DateTime.FromInstant( i, TimeZoneInfo.LocalOffsetAt( i ) ).ToIsoString( )

'' A reading in a fall-back overlap happens twice: AssumeLocal names the
'' EARLIER moment. A reading in a spring-forward gap never happens: it moves
'' forward by the gap, so 02:30 in a 02:00 -> 03:00 gap names 03:30.
```

---

**Library:** [Chrono Date and Time](Category-Date-and-Time-Chrono)  
**Category:** [Date and Time (Chrono)](Category-Date-and-Time-Chrono)  
**Documented under:** The Members
