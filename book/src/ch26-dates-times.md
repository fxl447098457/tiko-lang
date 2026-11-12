# Dates and Times

A date looks like the simplest data a program handles, and is not. Months have four different
lengths. The same moment has a different wall-clock time in every city, and the difference
changes twice a year in many of them. "Tomorrow at this time" and "24 hours from now" are the same
thing on most days and not on two. A date written `03/04/2025` means March in one country and
April in the next.

tiko's answer is the `std/chrono` module. It gives each of those ideas its own type, so a program
says which one it means, and it refuses ambiguous input instead of guessing. This chapter covers
the types, what makes a value valid, reading and writing dates as text, calendar arithmetic, time
zones, the clocks a program can read, and the older `datetime.bi` functions that chrono sits
beside.

## The types and the tick

```tiko
{{#include ../examples/ch26/ticks.tiko}}
```

```text
{{#include ../examples/ch26/ticks.out}}
```

`#import "std/chrono"` brings in five value types, reached as `chrono.LocalDate` and so on:

| Type | Holds | Example |
|---|---|---|
| `LocalDate` | a calendar date | `2025-03-04` |
| `LocalTime` | a time of day | `14:30:05.2500000` |
| `DateTime` | a date and a time, with or without a UTC offset | `2025-03-04T14:30:05+01:00` |
| `Instant` | a point on the UTC timeline | `2025-03-04T13:30:05Z` |
| `TimeSpan` | a fixed length of time | `P1DT2H3M4.5S` |

Every one of them counts in **ticks of 100 nanoseconds**, so a second is ten million ticks, and
the range runs from the first moment of year 1 to the last tick of year 9999. The resolution is the
same at both ends of that range; a value does not lose precision by being far from some epoch.

The values are **immutable**. No method changes a date in place: `day.AddDays( 1 )` returns a new
date and leaves `day` alone, so a value can be passed around and stored without anyone changing it
underneath. The parts are read with properties — `Year`, `Month`, `Day`, `Hour` and so
on. `DayOfWeek` numbers the days the ISO 8601 way, **1 for Monday** through 7 for Sunday.

The constructors take their fields from largest to smallest: `LocalDate( y, mo, d )`,
`LocalTime( h, mi, s, ms )`, `DateTime( y, mo, d )` or `DateTime( y, mo, d, h, mi, s, ms )`, and
for a span, `TimeSpan( h, mi, s )` or `TimeSpan( d, h, mi, s, ms )`. `TimeSpan` also has
`FromDays`, `FromHours`, `FromMinutes`, `FromSeconds` and `FromMilliseconds`.

A call whose argument count no constructor takes is refused: `chrono.TimeSpan( 0, 1, 30, 0 )` — four
arguments, where the constructors take three or five — is
`TKO0632: no overload of 'timespan.constructor' matches these arguments`.

## Validity

```tiko
{{#include ../examples/ch26/validity.tiko}}
```

```text
{{#include ../examples/ch26/validity.out}}
```

There is no 30 February, and chrono does not pretend there is. A constructor given an
out-of-range part does not roll the extra days into March; it returns the **Invalid** value of
its type, and `IsValid` says so. Rolling over would make a typo and a real date look the same
one line later.

Invalid behaves like a NaN in floating point:

- **It absorbs arithmetic.** Adding days, months or a span to an Invalid value gives Invalid, so a
  chain of calculations can be checked once at the end.
- **It equals nothing, not even itself.** `feb30 = feb30` is false. Test with `IsValid`, never
  by comparing with `Invalid( )`.
- **`CompareTo` returns -2** when either side is Invalid, which is not an ordering: -1, 0 and 1 are.
- **It prints as an empty string.** `ToIsoString( )` never fails; for Invalid it has nothing to say.

Arithmetic **never wraps**. Stepping one tick past `MaxValue( )` gives Invalid, not year 1.

A `LocalDate`, `Instant` or `DateTime` declared with no initialiser is Invalid, because no date is
a sensible default. A `TimeSpan` and a `LocalTime` start at zero and at midnight, which are real
values.

## Offsets and instants

```tiko
{{#include ../examples/ch26/offsets.tiko}}
```

```text
{{#include ../examples/ch26/offsets.out}}
```

A `DateTime` is a reading of a wall clock, and it is in one of three states:

- **UTC**, offset 0, printed with a `Z`.
- **An offset** from UTC, in minutes, up to 18 hours either way: `-300` is five hours behind UTC,
  printed `-05:00`.
- **Unspecified**: the time on *some* clock, with nothing to say which. `HasOffset` is false
  and the text has no suffix.

An `Instant` is a single point in time, the same everywhere. An unspecified `DateTime` cannot
become one without a guess, so **`ToInstant( )` on it is Invalid**. `AssumeUtc( )` makes the
guess, and makes it visible in the code.

Two methods put an offset on a `DateTime`, and they do different things:

| Call | Keeps | Changes |
|---|---|---|
| `WithOffset( m )` | the wall-clock reading | the moment it refers to |
| `ToOffset( m )` | the moment | the wall-clock reading |

`WithOffset` says "this 09:00 was read in Toronto". `ToOffset` says "what did the clocks in
Kolkata read at that moment?" The last line of the listing shows the difference: relabelling
Toronto's 09:00 as Kolkata's names a moment ten and a half hours earlier.

To compare readings taken in different places, convert them to `Instant` first. Two `DateTime`
values for the same moment in different offsets are different readings; their instants are equal.

```admonish danger title="Pitfall"
**`WithOffset` where `ToOffset` was meant** compiles, runs, and moves every timestamp by the
difference between the two offsets. If the value already has an offset and the goal is to show it
somewhere else, the call is `ToOffset`.
```

## Dates as text

### ISO 8601

```tiko
{{#include ../examples/ch26/isotext.tiko}}
```

```text
{{#include ../examples/ch26/isotext.out}}
```

`ToIsoString( )` writes the ISO 8601 form, and **one value has exactly one string**: a capital
`T`, a four-digit year, `Z` for UTC, `±HH:MM` for an offset, nothing for unspecified. A fraction
of a second is written with all seven digits or not at all, so the strings are all the same width
and sort in time order as plain text — the property that matters in a log file or a database key.

Parsing accepts more than it writes. `TryParseIso` takes the basic format without separators
(`20250304T143005Z`), ISO week dates (`2025-W10-2`, the Tuesday of week 10), ordinal dates
(`2025-063`, the 63rd day), a space in place of the `T` as RFC 3339 and SQL databases write it,
and a comma as the decimal point. It refuses anything else: there is no guessing at `03/04/2025`,
no two-digit years, and no `24:00`, which ISO allows but which means the same as the next day's
`00:00`.

Every type has the same pair:

- **`TryParseIso( text, result )`** returns `true` and sets `result`, or returns `false` and sets
  `result` to Invalid. The result is always written, so a stale value is never left behind. It
  never raises a runtime error.
- **`ParseIso( text )`** returns the value, or Invalid. Use it for text known to be good, such as
  a literal in the program.

A `TimeSpan` reads and writes ISO 8601 durations: `P1DT2H3M4.5S` is one day, two hours, three
minutes and four and a half seconds. `P1W` is accepted as seven days. `P1M` is refused, because a
month is not a fixed length of time — the same reason there is no `TimeSpan.FromMonths`.

`DateTime.TryParse` is `TryParseIso` under another name; it is not a lenient parser.

### Custom patterns

```tiko
{{#include ../examples/ch26/patterns.tiko}}
```

```text
{{#include ../examples/ch26/patterns.out}}
```

`ToString( pattern )` builds the text from pattern letters:

| Letters | Field | For 2025-03-04 14:30:05 +01:00 |
|---|---|---|
| `yyyy`, `yy` | year | `2025`, `25` |
| `M`, `MM`, `MMM`, `MMMM` | month | `3`, `03`, `Mar`, `March` |
| `d`, `dd`, `ddd`, `dddd` | day, weekday name | `4`, `04`, `Tue`, `Tuesday` |
| `H`, `HH`, `h`, `hh` | hour, 24- and 12-hour | `14`, `14`, `2`, `02` |
| `mm`, `ss` | minute, second | `30`, `05` |
| `fff`, `FFF` | fraction; `F` drops trailing zeros | |
| `tt` | AM or PM | `PM` |
| `zzz`, `K` | offset; `K` writes `Z` for UTC and nothing when unspecified | `+01:00` |

Text in single quotes is copied as it is, and so is any character that is not a letter. The names
are **always English**, whatever the machine's language, so the output depends only on the value
and the pattern — what a file or a protocol needs. A pattern of one character is a named format:
`"o"` round-trip ISO, `"s"` sortable, `"u"` universal, `"R"` RFC 1123 for HTTP headers (converted
to GMT first, as the listing shows), `"d"` the date, `"T"` the time.

**A letter that is not a pattern letter is an error, not a literal.** The `T` of an ISO timestamp
has to be quoted, `'T'`; written bare, `ToString` returns an empty string and `TryFormat` returns
`false`. A typo in a pattern shows up at once instead of in the output a week later.

`TryParseExact( text, pattern, result )` reads with a pattern, so a program says whether
`04.03.2025` is the fourth of March or the third of April. Fields that appear twice are checked
against each other: "Monday" does not parse beside a date that fell on a Tuesday.

For text a person will read on their own machine, `ToLocaleDateString`, `ToLocaleTimeString` and
`ToLocaleString` ask the operating system, in the user's language and order. Their output differs
from machine to machine, so never write it to a file or compare it.

Every chrono member that produces text without taking any — `ToIsoString`, `ToString( )`, the
locale family, `MonthName`, `WeekdayName` and the zone names — returns a `ustring`. A Spanish
"miércoles" therefore prints intact whatever the console's code page, and assigning the result to
a `string` still works, as UTF-8.

## Calendar arithmetic

```tiko
{{#include ../examples/ch26/calendar.tiko}}
```

```text
{{#include ../examples/ch26/calendar.out}}
```

Adding time comes in two kinds, and the names say which:

- **Exact**: `Add( span )`, `AddDays`, `AddHours`, `AddMinutes`, `AddSeconds`. `AddDays( 1 )` is
  exactly 86 400 seconds later.
- **Calendar**: `AddMonths` and `AddYears`, and on `DateTime` also `AddCalendarDays`,
  `AddCalendarMonths` and `AddCalendarYears`. These work on the calendar's fields and then build
  a date from them.

A month has no fixed length, so **month arithmetic clamps at the end of the month**: 31 January
plus one month is 28 February. That is the only sensible answer, but it loses information. Going
back a month from there gives 28 January, not 31; and two steps of one month end on 28 March,
where one step of two months ends on 31 March. Add the whole amount in one call rather than
building it up a step at a time. `AddYears` is `AddMonths` of twelve, so 29 February 2024 plus a
year is 28 February 2025.

The difference between `AddDays` and `AddCalendarDays` shows only across a daylight-saving change.
`AddDays( 1 )` is 24 hours later, and the wall-clock time moves by an hour. `AddCalendarDays( 1 )`
keeps the wall-clock time and works out the new offset, so it is 23 or 25 hours later. "24 hours
from now" is `AddDays`; "the same time tomorrow" is `AddCalendarDays`.

The period helpers keep the offset and set the time:

- `StartOfDay`, `StartOfWeek`, `StartOfMonth`, `StartOfYear` are the first tick of the period.
  `StartOfWeek` takes the first day of the week, and defaults to Monday.
- `EndOfDay`, `EndOfMonth`, `EndOfYear` are the **last tick**, `23:59:59.9999999`, not the start
  of the next period. Compare against them with `<=`.
- `NextWeekday( n )` and `PrevWeekday( n )` are strictly later and earlier: the next Tuesday after
  a Tuesday is a week away.

```admonish danger title="Pitfall"
**The ISO week belongs to the ISO week-year, not to `Year`.** 29 December 2025 is in week 1 of
2026. A program that prints `Year` beside `IsoWeek` writes "week 1 of 2025" for it, a date a
year off. Print `IsoWeekYear` with `IsoWeek`, always.
```

### Spans and differences

```tiko
{{#include ../examples/ch26/spans.tiko}}
```

```text
{{#include ../examples/ch26/spans.out}}
```

A `TimeSpan` has two families of readers. **`TotalHours`** and its siblings give the whole span
in one unit, with a fraction: 26.05 hours. **`Hours`** and its siblings give the pieces: the 2 in
"1 day, 2 hours". Mixing them up gives numbers that look plausible and are wrong. The pieces of a
negative span are all negative, so they always add back up to the whole.

Subtracting gives a difference of the right kind:

| Expression | Gives |
|---|---|
| `instant - instant`, `datetime - datetime` | `TimeSpan` |
| `localtime - localtime` | `TimeSpan` |
| `localdate - localdate` | a count of days, as a number |
| `instant + span`, `datetime - span` | the same type as the left side |

The flight in the listing leaves at 09:00, five hours behind UTC, and lands at 21:40 UTC. Both
are converted to instants when parsed, so the subtraction is correct without any offset
arithmetic in the program.

## A worked example: ages and birthdays

```tiko
{{#include ../examples/ch26/age-calc.tiko}}
```

```text
{{#include ../examples/ch26/age-calc.out}}
```

An age is the difference in years, less one if this year's birthday has not come yet. `AddYears`
does the hard part: it lands on the birthday in the target year, and for someone born on
29 February it clamps to the 28th in a year with no 29th. Whether a leap-day birthday falls on
28 February or 1 March in other years is a rule that varies by country; this code chooses the 28th
because that is what `AddYears` gives, and a program that must follow a particular law should
write that rule out.

The fixed `today` keeps the output the same on every run. A real program would use
`chrono.WallClock.Today( )`.

## Time zones

```tiko
{{#include ../examples/ch26/zone.tiko}}
```

```text
{{#include ../examples/ch26/zone.out}}
```

Time zones come from the **operating system**. `TimeZoneInfo.LocalOffsetAt( instant )` returns the
machine's offset from UTC, in minutes, **at that instant** — January and July can differ.
`TimeZoneInfo.LocalOffset( )` is the offset right now, which is the wrong one for converting a
timestamp from another season and the most common time-zone bug there is.
`IsDaylightSavingTime( instant )`, `SupportsDaylightSavingTime( )`, `StandardName( )` and
`DaylightName( )` complete the set. `WallClock.Now( )` records the offset it was read under, so it
converts back to the right instant even across a change.

The output of this listing is the same everywhere because it prints only facts that hold in every
zone; the offsets themselves depend on the machine.

### Named zones

chrono knows one zone, the machine's. **`std/tz`** knows them all, by their IANA names
(`America/New_York`, `Europe/London`), with their history: the date New York changes to daylight
time has moved several times, most recently in 2007, and a timestamp from any era converts by the
rules of its own day.

```tiko
{{#include ../examples/ch26/named-zones.tiko}}
```

```text
{{#include ../examples/ch26/named-zones.out}}
```

`TimeZone.FindById( name )` looks a zone up. On Linux and macOS `std/tz` reads the zone files the
system installs; **`#import "std/tzdata"`** builds a copy of the database into the program (about
250 KB), which is what makes the listing run on Windows, and is the fallback wherever a system's
files are missing.

A **`ZonedDateTime`** is an instant together with its zone. The instant is what it *is*; the
wall-clock reading is worked out from the zone's rules. That is why one value can be the earlier
01:30 of 2 November and another the later one: the readings are equal, the instants an hour apart.
Two ways of moving it in time match the two kinds of arithmetic in this chapter. `Add( span )`
adds elapsed time. `AddCalendarDays( n )` keeps the wall-clock reading and works the offset out
again, so the weekly call stays at 09:00 New York time across the change, and the first week is 167
hours long.

A wall-clock reading in a zone names **one** instant, **two** when the clocks go back, or **none**
when they go forward. `MapLocal` reports which. `FromLocal` takes a `Disambiguation` for the other
two cases: `dzCompatible` (the default) takes the earlier of two and moves a skipped reading forward
by the length of the gap; `dzEarlier` and `dzLater` choose; `dzReject` refuses, and `TryFromLocal`
reports it as `false`.

`ToIsoString` writes the zone after the offset, `2025-11-02T01:30:00-05:00[America/New_York]`,
and `ParseIso` reads it back to the same instant in the same zone. In a pattern, `VV` is the zone's
name and `v` its abbreviation at that instant. Store the name: `CST` is the abbreviation of three
different zones.

A program that must know an exact point in time still carries an `Instant` and stores it in UTC; a
zone is what turns it into a reading that a person in a particular place expects.

## Clocks

```tiko
{{#include ../examples/ch26/benchmark.tiko}}
```

```text
{{#include ../examples/ch26/benchmark.out}}
```

Three clocks answer three questions:

- **`WallClock`** — what time is it? `UtcNow( )` gives an `Instant`, `Now( )` a `DateTime` with
  the local offset, `Today( )` a `LocalDate`. The wall clock can **jump backwards**: the
  operating system corrects it, and users change it. `timer`, the classic function, reads the same
  clock, and neither should be used to measure how long something took.
- **`Stopwatch`** — how long did it take? It reads a monotonic clock that only ever moves forward.
  `StartNew( )` creates one running; `Elapsed` is a `TimeSpan` and `ElapsedMilliseconds` a
  number; `Restart( )` zeroes it and runs on. **`Stop_( )`** has a trailing underscore because
  `stop` is a statement. A stopwatch adds up the time it runs, so stopping and starting it again
  leaves the paused time out.
- **`CpuClock`** — how much processor time did it use? `ProcessTime( )` is the time the process
  has spent running, which a `sleep` does not add to. It moves in steps of about 15 milliseconds on
  Windows, so a short measurement reads zero.

The listing's output is a set of comparisons, not times, because times differ from run to run and
machine to machine. For a real measurement, run the work several times and keep the fastest, and
measure a build with optimisation on.

## The legacy bridge

```tiko
{{#include ../examples/ch26/legacy.tiko}}
```

```text
{{#include ../examples/ch26/legacy.out}}
```

Older code keeps a date as a `float64`: the whole part counts days from 30 December 1899 and the
fraction is the time of day. `#include "datetime.bi"` provides the functions for it —
`dateserial`, `timeserial`, `now`, `year`, `month`, `day`, `weekday` and the rest — and
`vbcompat.bi` adds `format`. They still work, and both styles can be used in one program.

`DateTime.FromSerial( serial )` and `.Serial` convert between the two. The conversion is exact
to the millisecond; below that, a `float64` holding a present-day date has no digits left to keep.

Three differences catch programs moving across:

- **`weekday( )` counts from Sunday = 1; `DayOfWeek` from Monday = 1.**
- **`dateserial` rolls over**: month 13, day 40 of 2025 is 9 February 2026. The chrono
  constructors refuse it.
- **A serial has no offset.** `now` returns local time with nothing to say so; `WallClock.Now( )`
  records the offset.

The other common epochs are one call away: `Instant.FromUnixSeconds` and `UnixSeconds` for Unix
time, `FromFileTime` and `FileTime` for Windows `FILETIME`, `FromOleDate` and `OleDate` for
COM, and `FromJulianDay` and `JulianDay`.

## A worked example: merging logs

```tiko
{{#include ../examples/ch26/iso-log-times.tiko}}
```

```text
{{#include ../examples/ch26/iso-log-times.out}}
```

Three machines wrote these lines, each in its own offset. Read as text they are out of order: the
line stamped `09:15` was written after the one stamped `15:14`. Parsed into `Instant` values they
sort by the moment itself, and the gaps between them are plain subtractions. The line whose stamp
does not parse is reported, not given a made-up time.

`Instant.TryParseIso` insists on an offset or a `Z` in its input, because a time with neither
cannot be placed on the UTC timeline. That is the check that keeps an unlabelled timestamp out of a
merged log.

## What it costs

- **The values are small and copied like numbers**: an `Instant`, `LocalTime` or `TimeSpan` is
  8 bytes of ticks, a `LocalDate` is a 4-byte day number, and a `DateTime` is 16 — its ticks and
  its offset.
- **Conversions are constant time.** Turning ticks into year, month and day is arithmetic with no
  loops, so the last date in the range costs the same as the first.
- **Formatting allocates the result string once; parsing allocates nothing.**
- **`Stopwatch` reads a high-resolution counter**; `CpuClock` asks the operating system, which
  costs more and is far coarser.

## Summary

- `#import "std/chrono"`: `LocalDate`, `LocalTime`, `DateTime`, `Instant`, `TimeSpan`. Immutable,
  100 ns ticks, years 1 to 9999, `DayOfWeek` 1 = Monday.
- Out-of-range parts give **Invalid**, which absorbs arithmetic, equals nothing and prints as `""`.
  Test with `IsValid`. Arithmetic never wraps.
- A `DateTime` is UTC, offset or unspecified. `WithOffset` relabels; `ToOffset` converts;
  `AssumeUtc` turns an unspecified reading into an `Instant`.
- `ToIsoString` writes one canonical form. `TryParseIso` accepts the ISO 8601 variants and refuses
  everything else; `ParseIso` returns Invalid on failure.
- `ToString( pattern )` and `TryParseExact` use invariant English. An unknown pattern letter is an
  error: quote literal letters.
- `AddDays` is exact; `AddMonths` and `AddYears` clamp at month end and do not reverse.
  `EndOf*` is the last tick. Print `IsoWeekYear` with `IsoWeek`.
- The machine's zone: `TimeZoneInfo.LocalOffsetAt( instant )`. Any zone by name: `#import "std/tz"`,
  `TimeZone.FindById`, and a `ZonedDateTime` for an instant in a zone; `#import "std/tzdata"` for
  the database inside the program. A reading names one instant, two or none: `MapLocal` and a
  `Disambiguation` policy.
- `Stopwatch` for elapsed time, `CpuClock` for processor time, `WallClock` for the time of day.
- `FromSerial`/`Serial` bridge to `datetime.bi`.

## Exercises

1. Write `WorkingDays( first, last )`, the number of Monday-to-Friday days from `first` up to but
   not including `last`, and check it on a week, a month and a year. {solution="ex26-01"}
2. Read a list of lap times written as ISO 8601 durations, report any that do not parse, and print
   the total and the mean. {solution="ex26-02"}
3. Extend `age-calc.tiko` to give an age in years, months and days.
4. Change `AgeOn` so that someone born on 29 February has their birthday on 1 March in years with no
   29 February. Which line has to change, and why is `AddYears` no longer enough?
5. `iso-log-times.tiko` prints its times in UTC. Print them instead in the offset of the first line
   of the log, using `DateTime.FromInstant`.
6. Print a table of the next ten changes of offset in `Europe/London`, `America/New_York` and
   `Australia/Sydney`, sorted by instant, each as its local reading before and after the change.
   Which zone changes in the opposite direction to the others, and why?
