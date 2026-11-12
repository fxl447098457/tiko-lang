[Home](Home) › [Date and Time (Chrono)](Category-Date-and-Time-Chrono) › [Chrono Date and Time](Category-Date-and-Time-Chrono) › **WallClock.Resolution**

# WallClock.Resolution

Returns the smallest step the wall clock reports, as a TimeSpan.

## Syntax

```freebasic
WallClock.Resolution( ) as TimeSpan
```

## Notes

- On Windows it is one tick (100 ns) where the system offers a precise clock, and 15.625 ms where it does not. On Linux and macOS it is what the OS reports for its real-time clock.
- It describes the wall clock only. A Stopwatch reads a different, monotonic counter.

## Examples

```freebasic
#import "std/chrono"
using chrono

dim as TimeSpan r = WallClock.Resolution( )

print r.Ticks > 0                     '' -1 (true)
print r.TotalMilliseconds <= 15.625   '' -1 (true)
```

---

**Library:** [Chrono Date and Time](Category-Date-and-Time-Chrono)  
**Category:** [Date and Time (Chrono)](Category-Date-and-Time-Chrono)  
**Documented under:** The Members
