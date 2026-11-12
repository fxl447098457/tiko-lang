[Home](Home) › [Date and Time (Chrono)](Category-Date-and-Time-Chrono) › [Chrono Date and Time](Category-Date-and-Time-Chrono) › **TimeZoneInfo.LocalOffsetAt**

# TimeZoneInfo.LocalOffsetAt

Returns the local zone's UTC offset in minutes at a given moment, DST included.

## Syntax

```freebasic
TimeZoneInfo.LocalOffsetAt( byref i as Instant ) as int16
```

## Notes

- The offset **at that instant**, not right now. Converting a July timestamp with January's offset is the commonest time-zone bug there is, and this is the call that avoids it.
- Minutes east of UTC: a zone behind UTC gives a negative number.
- An Invalid instant gives 0, which is also UTC's offset. [TryLocalOffsetAt](Modern-Chrono-TimeZoneInfo-TryLocalOffsetAt) returns false there instead.
- This is the machine's own zone. For any zone by its IANA name, see [TimeZone.OffsetSecondsAt](Modern-Tz-TimeZone-OffsetSecondsAt).

## Examples

```freebasic
#import "std/chrono"
using chrono

dim as Instant jan = DateTime( 2026, 1, 15, 12, 0, 0, 0 ).AssumeUtc( )
dim as Instant jul = DateTime( 2026, 7, 15, 12, 0, 0, 0 ).AssumeUtc( )

'' Differ by the daylight-saving shift, where the zone has one
print TimeZoneInfo.LocalOffsetAt( jan ), TimeZoneInfo.LocalOffsetAt( jul )

print TimeZoneInfo.LocalOffsetAt( Instant.Invalid( ) )   '' 0
```

---

**Library:** [Chrono Date and Time](Category-Date-and-Time-Chrono)  
**Category:** [Date and Time (Chrono)](Category-Date-and-Time-Chrono)  
**Documented under:** The Members
