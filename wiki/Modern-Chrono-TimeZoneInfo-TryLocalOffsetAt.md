[Home](Home) › [Date and Time (Chrono)](Category-Date-and-Time-Chrono) › [Chrono Date and Time](Category-Date-and-Time-Chrono) › **TimeZoneInfo.TryLocalOffsetAt**

# TimeZoneInfo.TryLocalOffsetAt

Gets the local zone's UTC offset at a given moment, returning false for an Invalid moment.

## Syntax

```freebasic
TimeZoneInfo.TryLocalOffsetAt( byref i as Instant, byref result as int16 ) as boolean
```

## Notes

- The same offset as [LocalOffsetAt](Modern-Chrono-TimeZoneInfo-LocalOffsetAt): minutes east of UTC, at that instant, DST included.
- False for an Invalid instant, and `result` is left alone. LocalOffsetAt answers 0 there, which is also a real offset, UTC's; this is the call that tells the two apart.

## Examples

```freebasic
#import "std/chrono"
using chrono

dim as short off
if TimeZoneInfo.TryLocalOffsetAt( WallClock.UtcNow( ), off ) then
    print "offset now:"; off
end if

print TimeZoneInfo.TryLocalOffsetAt( Instant.Invalid( ), off )   '' false
```

---

**Library:** [Chrono Date and Time](Category-Date-and-Time-Chrono)  
**Category:** [Date and Time (Chrono)](Category-Date-and-Time-Chrono)  
**Documented under:** The Members
