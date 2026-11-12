# Named time zones

An offset says how far a clock is from UTC at one moment. A **time zone** says
it for every moment: New York is five hours behind UTC in winter and four in
summer, and the dates it changes have changed over the years. `std/tz` knows the
zones by their IANA names, such as `America/New_York` and `Europe/Paris`.

```tiko
{{#include ../../examples/time/zones.tiko}}
```

**Output**

```text
{{#include ../../examples/time/zones.out}}
```

`TimeZone.FindById( name )` finds a zone, matching the name in any case.
`std/tz` reads the zone files Linux and macOS install. **`#import
"std/tzdata"`** adds a copy of the database to the program, about 250 KB, and
then named zones work on Windows too.

A `ZonedDateTime` is a moment in a zone: `FromLocal` makes one from a
wall-clock reading, `FromInstant` from a moment. Two ways to change zone keep
different things:

| Call | Keeps | Changes |
|---|---|---|
| `WithZoneSameInstant( z )` | the moment | the wall-clock reading |
| `WithZoneSameLocal( z )` | the wall-clock reading | the moment |

And two kinds of arithmetic: `Add( span )` adds elapsed time, while
`AddCalendarDays( n )` keeps the wall-clock reading, which is what "same time
next week" means when the clocks change in between.

**Some readings happen twice and some never.** When the clocks go back, 01:30
comes round twice; when they go forward, 02:30 is skipped. `MapLocal` says how
many moments a reading names: 1, 2 or 0. `FromLocal` takes a policy for the
other cases. The default, `dzCompatible`, picks the earlier of two and moves a
skipped reading forward by the length of the gap. `dzEarlier`, `dzLater` and
`dzReject` say otherwise.

`ToIsoString( )` writes the zone in brackets after the offset, so the text
reads back to the same moment in the same zone. In patterns, `VV` is the zone
name and `v` its abbreviation at that moment.

```admonish danger title="Pitfall"
**An abbreviation is not a zone.** `CST` is Central Standard Time in North
America, China Standard Time and Cuba Standard Time. Store the IANA name
(`VV`), never the abbreviation.
```

### Activities

1. Print what time a 15:00 call from Sydney on 1 April 2025 is in London.
2. Find the next date the clocks change in `Europe/London` after today, with
   `TimeZone.TryNextTransition`.
