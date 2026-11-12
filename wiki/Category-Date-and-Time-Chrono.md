[Home](Home) › [All Categories](Categories) › **Date and Time (Chrono)**

# Date and Time (Chrono)

```freebasic
#import "std/chrono"
using chrono

dim as DateTime d = DateTime( 2025, 3, 4, 14, 30, 5, 0 ).WithOffset( 330 )
print d.ToIsoString( )                     ' 2025-03-04T14:30:05+05:30
print d.ToString( "dddd, dd MMMM yyyy" )   ' Tuesday, 04 March 2025

print DateTime( 2025, 2, 30 ).IsValid      ' false -- not normalized away

dim as TimeSpan age = WallClock.UtcNow( ) - d.ToInstant( )
print age.TotalDays

dim as Stopwatch sw = Stopwatch.StartNew( )
' ... work ...
print sw.ElapsedMilliseconds
```

## Why It Exists

In the built-in date and time surface a date is a serial DOUBLE, resolution is one second, there is no duration type, no timezone concept, no ISO 8601, and no monotonic clock. DateSerial( 2025, 13, 40 ) does not fail -- it normalizes, so a bad date and a good one are indistinguishable afterwards. TIMER is the wall clock, which jumps backwards on an NTP correction, so every program that measures elapsed time with it is quietly wrong twice a year and occasionally in between.

This library ships ALONGSIDE all of that. Nothing in datetime.bi, vbcompat.bi, FORMAT or the runtime's existing date and time routines changed, and nothing here depends on them. The two meet at FromSerial / Serial, so a program migrates one function at a time. See migration.md for the member-by-member mapping.

NO COMPILER SUPPORT IS INVOLVED. This is a library: the runtime half is in tiko-rt (lib/rt/src/chrono/), the tiko types in the std/chrono module (pkg/std/chrono/). Nothing here is a keyword, and DateTime, Instant, WallClock and the rest stay available as your own identifiers: nothing is added to a program until it imports std/chrono, and the bare names only after 'using chrono'.

## The Tick

Everything measures in TICKS of 100 nanoseconds. A date-time is a count of ticks since 0001-01-01T00:00:00 in the proleptic Gregorian calendar.

```freebasic
range               year 1 .. year 9999
resolution          100 ns
representation      one LONGINT (DateTime adds a SHORT offset)
```

One integer, so these types pass in a register and copy trivially. There is no allocation anywhere in the value types and no destructor.

100 ns divides evenly into milliseconds and microseconds, and the epoch is far enough back that every interop epoch -- Unix, FILETIME, OLE, Julian day -- lands on a positive tick constant, so each conversion is one addition. That is the whole reason for both choices; rationale.md argues it against the alternatives.

## The Types

Five value types and four namespaces. Each type answers one question, and the split is deliberate -- a date and a time-of-day cannot be compared, subtracted, or passed to each other's functions.

```freebasic
TimeSpan      a fixed duration, signed. NOT a calendar period.
LocalDate     a date, no time, no offset
LocalTime     a time of day, no date, no offset: 0 .. a tick int16 of a day
Instant       an absolute point on the UTC timeline. No offset field,
              because an absolute point does not have one.
DateTime      a civil date-time PLUS a UTC offset

WallClock         what time is it (can jump)
Stopwatch     how int32 since (monotonic, never jumps)
CpuClock      how much CPU this process or thread burned
TimeZoneInfo  the OS zone: offset at an instant, DST, names
```

Roughly 260 members and 44 free operators.

DECLARATION ORDER IS LOAD-BEARING. tiko cannot forward-declare a UDT well enough to return one BY VALUE, so a type may only return types defined above it: TimeSpan, LocalDate, LocalTime, Instant, DateTime. That is why the Instant -> DateTime direction is spelled DateTime.FromInstant rather than Instant.ToUtc, and why DateTime.ToInstant is a member while its inverse is not.

WHICH ONE TO USE. If it is a timestamp -- when something happened, when it expires, anything compared across machines -- use Instant. If a human wrote it down or will read it, and the offset matters, use DateTime. If it is a birthday or a due date, use LocalDate. Storing a wall-clock reading and hoping the offset is obvious is the bug this type split exists to prevent.

## Immutable

Every operation returns a NEW value. Nothing modifies the receiver.

```freebasic
d = d.AddDays( 3 )              ' do
d.AddDays( 3 )                  ' does nothing -- result dropped
```

This is what java.time, NodaTime, Temporal, Rust and Go all converged on, and it is what makes it safe to pass one of these BYREF.

## Invalid Is Absorbing, AND Never Equal To Itself

There is no exception, no ERR( ), and no error code. Out-of-range construction and overflowing arithmetic both yield an Invalid value, and anything touching an Invalid value becomes Invalid. ARITHMETIC NEVER WRAPS.

```freebasic
DateTime( 2025, 2, 30 )         Invalid -- there is no such date
DateTime.MaxValue.AddTicks( 1 ) Invalid -- not MinValue
TimeSpan.Invalid + anything     Invalid
```

BEWARE: comparing an Invalid value with ANYTHING is false, INCLUDING with itself.

```freebasic
DateTime.Invalid = DateTime.Invalid       ' FALSE
DateTime.Invalid <> DateTime.Invalid      ' also FALSE
DateTime.Invalid.IsValid                  ' the only correct test
```

That is IEEE NaN's rule and it is here for IEEE NaN's reason: an equality that succeeded would let invalid values slip through a validation check that looks correct. Both <> and <= are written to return false when either side is Invalid, rather than falling out of a negated comparison.

CompareTo returns -2 for "not comparable", not 0. -2 is deliberately not an ordering, so a sort predicate written as 'CompareTo( ) < 0' does not silently treat Invalid as smallest.

The sentinel is LLONG_MIN, which lies outside every valid range, so a wrapped result can never collide with it. It costs TimeSpan exactly one value at the bottom: TimeSpan.MinValue is LLONG_MIN + 1.

DEFAULT CONSTRUCTION IS NOT UNIFORM, and this is the one asymmetry in the library:

```freebasic
dim as TimeSpan  s        ' zero
dim as LocalTime t        ' midnight
dim as LocalDate d        ' INVALID
dim as Instant   i        ' INVALID
dim as DateTime  x        ' INVALID, offset unspecified
```

Zero is a meaningful duration and a meaningful time of day, so those two default to it. There is no meaningful zeroth date or zeroth timestamp -- year 1 as a default is a value that reaches production -- so the other three default to Invalid. Do not rely on a defaulted DateTime, Instant or LocalDate being usable; test IsValid, which is what it is for.

## The Three Offset States

A DateTime carries the LOCAL wall-clock reading plus a UTC offset in minutes. It stores the wall reading, not the UTC instant, because that is what survives a round trip through ISO 8601 text without losing what the writer meant. C#'s DateTimeOffset and java.time's OffsetDateTime both do the same.

```freebasic
0                        explicitly UTC        renders as Z
-1080 .. 1080            a fixed offset        renders as +05:30
DT_OFFSET_UNSPECIFIED    naive; nobody said    renders bare
```

UNSPECIFIED IS A DISTINCT STATE FROM UTC. Conflating the two is the DateTimeKind.Unspecified mistake C# is stuck with. HasOffset says whether anyone said, IsUtc says whether the answer was zero, and ToInstant on a naive value is Invalid -- there is no defensible way to put a naive reading on the UTC timeline without guessing.

WithOffset REINTERPRETS: keeps the wall reading, changes the instant. ToOffset CONVERTS: keeps the instant, changes the wall reading.

```freebasic
DateTime( 2025, 3, 4, 12, 0, 0, 0 ).WithOffset( 60 )   ' 12:00+01:00
DateTime( 2025, 3, 4, 12, 0, 0, 0 ).WithOffset( 0 ) _
                                   .ToOffset( 60 )     ' 13:00+01:00
```

These are the pair people confuse. Neither is a safe default, which is why neither is implicit.

## The Members

Everything below is O(1) unless marked. The C kernel is branch-and-arithmetic with no loops over the range, so "convert 9999-12-31" costs what "convert 0001-01-01" costs. Text output allocates once; parsing allocates nothing.

TimeSpan -- a fixed duration

```freebasic
TimeSpan( )                                   zero
TimeSpan( ticks )
TimeSpan( h, mi, s )
TimeSpan( d, h, mi, s, ms )
.FromDays / FromHours / FromMinutes / FromSeconds /
  FromMilliseconds( float64 )                  rounds half away from zero
.FromMicroseconds( int64 )                  int64, not float64
.FromTicks( int64 )
.Zero / .MinValue / .MaxValue / .Invalid

.Ticks                                        int64
.TotalDays .TotalHours .TotalMinutes
  .TotalSeconds .TotalMilliseconds            float64, the whole span
.TotalMicroseconds                            int64
.Days .Hours .Minutes .Seconds
  .Milliseconds .Microseconds                 int32, the broken-down pieces
.IsValid .IsZero .IsNegative

.Negate .Duration                             Duration is absolute value
.Add .Subtract .Multiply( f ) .Divide( f )
.DivideBy( other )                            float64; NaN on zero or Invalid
.CompareTo( other )                           -1 0 1, or -2

.ToIsoString / .ToString                      P1DT2H3M4.5S, a ustring
.TryParseIso( s, result ) / .ParseIso( s )

operators: + - (binary and unary) * / = <> < > <= >=
           'double * span' as well as 'span * double'

TOTALS vs COMPONENTS. Total* is the whole span in that unit, fractionally.
The components are the pieces. For 1 day 2 hours 3 minutes: TotalHours is
26.05, Hours is 2.

COMPONENTS OF A NEGATIVE SPAN ARE ALL NEGATIVE, matching C#. -1h30m has
Hours = -1 and Minutes = -30, not -1 and +30, so the pieces always
reconstruct the whole.

THERE IS NO FromMonths, on purpose. A month has no fixed length, so it is
not a duration; that is AddMonths, which takes a LONG and lives on the
date types. Keeping the two kinds of arithmetic visibly separate is the
point.
```

LocalDate -- a date

```freebasic
LocalDate( )                                  Invalid
LocalDate( y, mo, d )
.FromDayNumber( days ) / .MinValue / .MaxValue / .Invalid

.IsValid .DayNumber
.Year .Month .Day .DayOfWeek .DayOfYear
.IsoWeek .IsoWeekYear .Quarter
.IsFirstDayOfMonth .IsLastDayOfMonth

.AddDays( n ) .AddMonths( n ) .AddYears( n )
.StartOfMonth .EndOfMonth
.CompareTo

.ToIsoString / .ToString                      2025-03-04
.TryParseIso / .ParseIso  (+ USTRING overloads)

operators: - (gives a LONG day count) = <> < > <= >=
```

LocalTime -- a time of day

```freebasic
LocalTime( )                                  midnight
LocalTime( h, mi, s, ms )
.FromTicks / .Midnight / .Noon / .MaxValue / .Invalid

.IsValid .Ticks
.Hour .Minute .Second .Millisecond .Microsecond
.CompareTo

.ToIsoString / .ToString                      14:30:05.1234567
.TryParseIso / .ParseIso  (+ USTRING overloads)

operators: - (gives a TimeSpan) = <> < > <= >=
```

Instant -- a point on the UTC timeline

```freebasic
Instant( ) / Instant( ticks )
.FromTicks / .MinValue / .MaxValue / .Invalid
.IsValid .Ticks
.Add( span ) .Subtract( span ) .CompareTo

.FromUnixSeconds / FromUnixMilliseconds / FromUnixMicroseconds
.UnixSeconds / .UnixMilliseconds / .UnixMicroseconds

.ToIsoString / .ToString                      2025-03-04T14:30:05.1234567Z
.TryParseIso / .ParseIso  (+ USTRING overloads)

operators: instant + span, instant - span, instant - instant -> TimeSpan,
           = <> < > <= >=

Instant.TryParseIso REQUIRES AN OFFSET IN THE INPUT. A naive reading cannot
be placed on the UTC timeline without guessing, and refusing is the type
system doing its job rather than a limitation.
```

DateTime -- a civil date-time with an offset

```freebasic
construction and identity

DateTime( )                                   Invalid, offset unspecified
DateTime( y, mo, d )
DateTime( y, mo, d, h, mi, s, ms )
.FromTicks( t, offMin ) .FromDate( date ) .FromDateTime( date, time )
.FromInstant( instant, offMin )
.MinValue .MaxValue .Invalid
.IsValid .Ticks .OffsetMinutes .HasOffset .IsUtc

components

.Year .Month .Day .Hour .Minute .Second
.Millisecond .Microsecond .TickOfDay
.DayOfWeek .DayOfYear .IsoWeek .IsoWeekYear .Quarter
.IsFirstDayOfMonth .IsLastDayOfMonth
.GetDate -> LocalDate      .GetTimeOfDay -> LocalTime

offsets and instants

.WithOffset( offMin )   reinterpret   .ToOffset( offMin )   convert
.AssumeUtc -> Instant   .AssumeLocal -> Instant
.ToInstant -> Instant   .ToLocal -> DateTime

exact arithmetic -- ticks, no calendar

.Add( span ) .Subtract( span ) .AddTicks( n )
.AddDays .AddHours .AddMinutes .AddSeconds .AddMilliseconds   (float64)

calendar arithmetic -- LONG, not a TimeSpan

.AddMonths( n ) .AddYears( n )
.AddCalendarDays( n ) .AddCalendarMonths( n ) .AddCalendarYears( n )

calendar utilities

.IsLeapYear( y ) .DaysInMonth( y, mo ) .DaysInYear( y ) .WeeksInYear( y )
.StartOfDay .EndOfDay .StartOfMonth .EndOfMonth .StartOfYear .EndOfYear
.StartOfWeek( firstDay = DT_MONDAY )
.NextWeekday( dow ) .PrevWeekday( dow )

interop

.FromUnixSeconds .FromUnixMilliseconds
.UnixSeconds .UnixMilliseconds .UnixMicroseconds
.FromSerial( float64 ) / .Serial            datetime.bi serial
.FromFileTime( int64 ) / .FileTime       Win32 FILETIME
.FromOleDate( float64 ) / .OleDate          OLE automation date
.FromJulianDay( float64 ) / .JulianDay / .JulianDayNumber

text

.ToIsoString .ToString                     ToString( ) is ToIsoString( )
.TryParseIso .TryParse .ParseIso
.ToString( pattern ) .TryFormat( pattern, result )
.TryParseExact( s, pattern, result ) .ParseExact( s, pattern )
.ToLocaleDateString / ToLocaleTimeString / ToLocaleString( style )
.MonthName( mo [, abbrev] ) .WeekdayName( dow [, abbrev] )

USTRING overloads: .ToString( ustring ), .TryFormat, .TryParseIso,
.TryParse, .ParseIso, .TryParseExact, .ParseExact

operators: datetime + span, datetime - span, datetime - datetime ->
           TimeSpan, = <> < > <= >=
```

WallClock -- the wall clock

```freebasic
WallClock.UtcNow -> Instant
WallClock.Now -> DateTime          carries the offset in force AT THAT INSTANT
WallClock.Today -> LocalDate
WallClock.TimeOfDay -> LocalTime
WallClock.Resolution -> TimeSpan
```

Pages: [UtcNow](Modern-Chrono-WallClock-UtcNow) · [Now](Modern-Chrono-WallClock-Now) · [Today](Modern-Chrono-WallClock-Today) · [TimeOfDay](Modern-Chrono-WallClock-TimeOfDay) · [Resolution](Modern-Chrono-WallClock-Resolution)

Stopwatch -- the monotonic clock

```freebasic
Stopwatch( ) / Stopwatch.StartNew
.Start .Stop_ .Reset .Restart
.IsRunning .Elapsed -> TimeSpan .ElapsedMilliseconds .ElapsedTicks
Stopwatch.Frequency .GetTimestamp .IsHighResolution

'Stop_' has the trailing underscore because STOP is a tiko statement.
```

CpuClock -- consumed processor time

```freebasic
CpuClock.ProcessTime         user + kernel
CpuClock.ProcessUserTime
CpuClock.ProcessKernelTime   Invalid where the OS does not split it
CpuClock.ThreadTime          the total; no user/kernel split is exposed
CpuClock.IsSupported

Process time splits on both platforms -- GetProcessTimes on Windows,
getrusage on Unix, which is used in preference to
CLOCK_PROCESS_CPUTIME_ID precisely because it reports the two halves.
Thread time does not split on Unix (CLOCK_THREAD_CPUTIME_ID is one
number), so the C layer returns -1 for the kernel half and ThreadTime
reports the total rather than inventing a division.
```

Pages: [ProcessTime](Modern-Chrono-CpuClock-ProcessTime) · [ProcessUserTime](Modern-Chrono-CpuClock-ProcessUserTime) · [ProcessKernelTime](Modern-Chrono-CpuClock-ProcessKernelTime) · [ThreadTime](Modern-Chrono-CpuClock-ThreadTime) · [IsSupported](Modern-Chrono-CpuClock-IsSupported)

TimeZoneInfo -- the OS zone

```freebasic
TimeZoneInfo.LocalOffsetAt( instant )      the offset AT THAT INSTANT
TimeZoneInfo.TryLocalOffsetAt( instant, off )   false for an Invalid instant
TimeZoneInfo.LocalOffset                   the offset right now
TimeZoneInfo.IsDaylightSavingTime( instant )
TimeZoneInfo.SupportsDaylightSavingTime
TimeZoneInfo.StandardName / .DaylightName  display text: "Newfoundland Standard
                                           Time" on Windows, "NST" elsewhere

LocalOffsetAt EXISTS BECAUSE "the current offset" IS THE WRONG DEFAULT.
Converting a July timestamp with January's offset is the commonest timezone
bug there is, and an API offering only LocalOffset makes it the easy path.
```

Pages: [LocalOffsetAt](Modern-Chrono-TimeZoneInfo-LocalOffsetAt) · [TryLocalOffsetAt](Modern-Chrono-TimeZoneInfo-TryLocalOffsetAt) · [LocalOffset](Modern-Chrono-TimeZoneInfo-LocalOffset) · [IsDaylightSavingTime](Modern-Chrono-TimeZoneInfo-IsDaylightSavingTime) · [SupportsDaylightSavingTime](Modern-Chrono-TimeZoneInfo-SupportsDaylightSavingTime) · [StandardName](Modern-Chrono-TimeZoneInfo-StandardName) · [DaylightName](Modern-Chrono-TimeZoneInfo-DaylightName)

## EXACT ARITHMETIC vs CALENDAR ARITHMETIC

Three families, and the names say which is which.

```freebasic
AddDays( 1 )            exactly 86400 seconds. Does NOT keep the wall-clock
                        time across a DST boundary.
AddCalendarDays( 1 )    same wall-clock time tomorrow. Re-resolves a local
                        reading's offset, so across a DST boundary it is
                        23 or 25 hours of real time.
AddMonths( 1 )          calendar months, offset untouched.
AddCalendarMonths( 1 )  calendar months, offset re-resolved.
```

ONLY A LOCAL READING FOLLOWS THE OS ZONE: one whose offset is the zone's at its own instant, as WallClock.Now and ToLocal give. A UTC or other fixed-offset value keeps its offset, so AddCalendarDays( 1 ) on 2025-07-01T12:00Z is 2025-07-02T12:00Z on every machine. A DateTime carries no zone, so a fixed offset that happens to equal the zone's at that instant -- UTC on a London machine in winter -- is taken as local.

A wall reading that falls in a fall-back overlap keeps the offset it started with; one that falls in a spring-forward gap does not exist and moves forward by the gap, so 02:30 in a 02:00 -> 03:00 gap becomes 03:30.

"24 hours from now" is AddDays( 1 ). "Same time tomorrow" is AddCalendarDays( 1 ). They differ twice a year, and a program that means one and writes the other is correct in testing and wrong in October.

CALENDAR ARITHMETIC CLAMPS AT MONTH END, AND IS THEREFORE LOSSY:

```freebasic
2025-01-31 .AddMonths(  1 )              2025-02-28
2024-01-31 .AddMonths(  1 )              2024-02-29
2025-01-31 .AddMonths(  1 ).AddMonths( -1 )   2025-01-28   -- not 01-31
2025-01-31 .AddMonths(  2 )              2025-03-31
2025-01-31 .AddMonths(  1 ).AddMonths( 1 )    2025-03-28   -- not 03-31
```

Clamping is not associative and it is not reversible. Every library that does calendar arithmetic has this property; the alternative is rolling into the next month, which is worse. Add the larger step in one call rather than accumulating.

The time of day and the offset ride through AddMonths untouched. AddYears is AddMonths( n \* 12 ), so 2024-02-29.AddYears( 1 ) is 2025-02-28.

START/END HELPERS KEEP THE OFFSET AND SET THE TIME. EndOfDay, EndOfMonth and EndOfYear are the LAST TICK of that period -- 23:59:59.9999999 -- not the first tick of the next one. Compare with <= against them, or use the start of the next period with <.

StartOfWeek takes the first day of the week and defaults to Monday. NextWeekday and PrevWeekday are STRICTLY later and strictly earlier: asking a Tuesday for the next Tuesday gives a week forward, not a no-op. A weekday outside 1..7 is Invalid, not clamped.

DAY OF WEEK IS 1 = MONDAY, ISO 8601's numbering, which differs from datetime.bi's Weekday( ) where 1 = Sunday. The ISO week-number algorithm needs it, and two neighbouring conventions is one too many. This is the single most likely thing to trip a program moving over from datetime.bi.

ISO WEEK-YEAR IS NOT THE YEAR. 2025-12-29 is week 1 of ISO year 2026. Rendering IsoWeek beside Year instead of IsoWeekYear is the canonical bug in ISO week output, which is why both are exposed and neither is called "Week".

## ISO 8601 AND RFC 3339

EMISSION IS CANONICAL AND SINGLE-VALUED. One value produces exactly one string. All the variety ISO 8601 permits is accepted on input only.

```freebasic
Instant                 2025-03-04T14:30:05.1234567Z
DateTime, offset        2025-03-04T14:30:05.1234567+05:30
DateTime, UTC           2025-03-04T14:30:05.1234567Z
DateTime, unspecified   2025-03-04T14:30:05.1234567
LocalDate               2025-03-04
LocalTime               14:30:05.1234567
TimeSpan                P1DT2H3M4.5S
```

Extended format only, always with the separators. Uppercase T. Four-digit year, which is why the range stops at 9999. Offset is always +-HH:MM with the colon; UTC emits Z, never +00:00.

THE FRACTIONAL PART IS ALL SEVEN DIGITS OR NONE. Zero sub-second ticks emit no fraction at all; anything else emits exactly seven digits with no trailing-zero trimming. Fixed width is what makes these strings sort lexicographically, which is the property that matters once they land in a log or a database key.

An Invalid value emits the empty string. ToIsoString never fails; the maximum output is 33 bytes and the C core writes into a caller-supplied buffer.

A DURATION IS THE ONE EXCEPTION TO THE FIXED-WIDTH FRACTION -- P1DT2H3M4.5S, not 4.5000000S -- because a duration is not a sort key. Zero is PT0S, never a bare "P". A negative duration leads with the sign, outside the P: -PT2H.

The duration parser accepts weeks (P1W = 7 days) and, like the emitter, allows a fraction ON THE SECONDS FIELD ONLY. PnM and PnY ARE REJECTED: months and years are not fixed-length, which is the same reason there is no TimeSpan.FromMonths. A bare "P" is an error.

PARSING IS STRICT. No locale, no guessing, no partial acceptance, and trailing characters are an error. What is accepted beyond the canonical form:

```freebasic
basic format                20250304T143005Z    filenames, older protocols
ordinal date                2025-063
ISO week date               2025-W10-2
comma as decimal point      14:30:05,123        the ISO-preferred form
space instead of T          2025-03-04 14:30:05 RFC 3339 5.6, every SQL db
lowercase t and z           RFC 3339
hour-only offset            +05      and  +0530 without the colon
more than 7 fraction digits TRUNCATED, not rejected
```

That last one is the only lenient behaviour in the parser, and it is deliberate: rejecting a nanosecond timestamp would fail against Go and Rust output.

Rejected outright: two-digit years, ever -- there is no century-inference rule and there will not be one. 24:00 as end of day, which is legal ISO 8601 and a landmine; the next day's 00:00 says the same thing without the ambiguity. Negative and expanded years. Leap seconds (:60).

THE PARSE CONTRACT, for every type:

```freebasic
1. true and 'result' assigned on success.
2. false and 'result' = Invalid on failure. RESULT IS ALWAYS WRITTEN, so a
   caller who ignores the return value cannot read a stale value.
3. Never raises err( ), never throws, never writes to stderr.
4. Leading and trailing ASCII whitespace is trimmed first. Interior
   whitespace, other than the float32 RFC 3339 space, is an error.
5. Empty or all-whitespace input is a failure, not a zero value.
6. int8-oriented ASCII. A UTF-8 BOM is not skipped; it is an error.
```

ParseIso is TryParseIso with the boolean dropped -- it returns Invalid on failure and is for the cases where a literal is known good.

## Custom Patterns

ToString( pattern ) and TryParseExact. OUTPUT DEPENDS ONLY ON THE VALUE AND THE PATTERN -- names are invariant English, never the OS locale -- so this is the formatter to use for anything written to a file, a protocol or a log.

DATE                                        example, 2025-03-04

```freebasic
y      year, minimum digits               2025
yy     year, last two digits              25
yyyy   year, 4 digits padded              2025
yyyyy  year, 5 digits padded              02025
M MM   month, 1-2 / 2 digits              3 / 03
MMM    month abbreviation, English        Mar
MMMM   month name, English                March
d dd   day of month                       4 / 04
ddd    weekday abbreviation, English      Tue
dddd   weekday name, English              Tuesday
D DDD  day of year                        63 / 063
Q      quarter                            1      format-only
w ww   ISO week                           10     format-only
Y      ISO week-year                      2025   format-only
g      era                                A.D.   format-only
```

TIME                                        example, 14:30:05.1234567

```freebasic
H HH   hour 0-23                          14
h hh   hour 1-12                          2 / 02
m mm   minute                             30
s ss   second                             05
f..fffffff   fraction, 1-7 digits, zero-padded, ALWAYS SHOWN
F..FFFFFFF   fraction, trailing zeros and the whole field OMITTED if zero
t tt   AM/PM, invariant                   P / PM
```

OFFSET

```freebasic
z      sign + hours                       +5
zz     sign + 2-digit hours               +05
zzz    +-HH:MM                            +05:30
K      Z if UTC, +-HH:MM if offset, EMPTY if unspecified
```

K is the one for machine-readable output: it is what makes a pattern round-trip a naive DateTime correctly.

LITERALS. Single quotes delimit a literal run, '' inside is an apostrophe, and \\c escapes the next character. Any character that is not an ASCII letter is literal without quoting -- '-', '/', ':', '.', ',', space, digits.

AN UNRECOGNIZED ASCII LETTER IS A PATTERN ERROR, NOT A LITERAL. Silently passing an unknown letter through turns a typo into wrong output; failing turns it into a caught bug. An unterminated quote is an error too. On any pattern error ToString returns the empty string and TryFormat returns false -- which is why TryFormat exists, to separate "the pattern is broken" from "the value formatted to nothing".

A PATTERN OF EXACTLY ONE CHARACTER IS A NAMED FORMAT, not a field:

```freebasic
"o" "O"   round-trip ISO 8601      2025-03-04T14:30:05.1234567Z
"s"       sortable, no offset      2025-03-04T14:30:05
"u"       universal sortable       2025-03-04 14:30:05Z
"R"       RFC 1123, for HTTP       Tue, 04 Mar 2025 09:00:05 GMT
"d"       invariant short date     2025-03-04
"T"       invariant time           14:30:05
```

To format a single letter as a field, give a two-character pattern with a literal in it. This is a known wart inherited from the C# design; the shorthands earn it.

"R" emits GMT and English names regardless of locale AND regardless of the value's offset -- the value is converted to UTC first, which is what RFC 1123 requires and what the classic HTTP-header bug gets wrong.

PARSING A PATTERN is strict in the same way:

- The input must match exactly. No leading or trailing characters, and a

```freebasic
literal space matches exactly one space.
```

- Fixed-width fields (MM, dd, HH, yyyy, fff) consume exactly that many digits.

```freebasic
Variable-width fields (M, d, H) take 1-2 digits greedily.
```

- A variable-width numeric field immediately followed by another numeric field

```freebasic
is A PATTERN ERROR. "Md" cannot be parsed unambiguously, and failing at
pattern-compile time beats failing on the 3rd of December.
```

- Name fields match invariant English, case-insensitively. - Absent fields default to year 1, month 1, day 1, times 0, offset

```freebasic
unspecified.
```

- A field appearing twice with CONFLICTING values fails. Redundant but

```freebasic
consistent fields are accepted and CROSS-CHECKED: a pattern with both dddd
and yyyy-MM-dd fails if the named weekday is not that date's weekday.
```

- The assembled components go through the ordinary constructor, so 2025-02-30

```freebasic
fails there.
```

FORMAT-ONLY PATTERNS ARE A PATTERN ERROR IN A PARSE, not a silent success: Q, w, ww (a week or quarter cannot reconstruct a date), Y (derived), g (no information in a range that is entirely A.D.), and the "R" and "u" constant formats (they convert to UTC). "o", "O", "s", "d" and "T" parse.

## Clocks

THREE CLOCKS, BECAUSE THEY ANSWER THREE DIFFERENT QUESTIONS.

WallClock is the wall clock: what time is it. IT CAN JUMP BACKWARDS -- NTP corrections, DST, a user setting the clock -- so it is the wrong tool for measuring elapsed time, and so is TIMER. WallClock.Now records the offset in force at that instant, so WallClock.Now( ).ToInstant( ) round-trips even across a DST change.

Stopwatch is the monotonic clock: how long since. It never jumps. It ACCUMULATES rather than recomputing from two stored timestamps, so start/stop/start is correct with no special cases -- Elapsed is a property over an accumulator, not a subtraction of endpoints.

CpuClock is consumed processor time, which a SLEEP does not advance. That is the whole point of having it: it separates "the operation took 3 seconds" from "the operation used 3 seconds of CPU". Granularity is coarse -- about 15.6 ms on Windows -- so a short measurement reads as zero rather than as a small number.

WallClock and CpuClock are NAMESPACES, not types, because tiko will not accept a TYPE with no data members. The call syntax is identical either way.

## Locale Output, AND Why It Is Segregated

ToLocaleDateString, ToLocaleTimeString, ToLocaleString, MonthName and WeekdayName ask the OS. Their output is whatever the machine says, in the user's language, in whatever order that locale writes dates.

```freebasic
lsShort   lsLong   lsFull        the style argument, default lsShort
```

ONLY lsShort IS A DISTINCT STYLE TODAY. Both backends branch on "is it short", so lsFull renders as lsLong -- DATE_LONGDATE on Windows, "%A %d %B %Y" through strftime on Unix. The third name is in the API because the OS surfaces can support it; do not write code that depends on the two differing.

THIS IS THE ONLY PART OF THE LIBRARY WHOSE OUTPUT IS NOT REPRODUCIBLE, and it is deliberately in its own corner of the API with "Locale" in every name. Use it for text a human reads on that machine. Use the pattern formatter for anything that is written down, parsed later, compared, or sent anywhere.

Its tests assert non-emptiness, valid UTF-8, ordering and distinctness, and nothing more -- exact-string assertions there would be either locale-pinned or dishonest.

Locale output is also the only part of the library that is routinely non-ASCII. It comes back as a ustring, so a name like "miércoles" reaches `print` and a Windows message box intact on any console code page.

## Strings: Ustring Out, Either Type In

TEXT THAT TAKES NO TEXT IN COMES BACK AS A USTRING: ToIsoString, ToString( ), the locale family and the zone names. There is one name for each, and no string twin to choose between.

Anything TAKING text overloads on its type: a string pattern or input gives a string back, a ustring one a ustring.

```freebasic
d.ToIsoString( )                  -> ustring
d.ToString( )                     -> ustring
DateTime.MonthName( 3 )           -> ustring
TimeZoneInfo.StandardName( )      -> ustring
d.ToString( "yyyy-MM-dd" )        pattern is a string  -> string
d.ToString( uPattern )            pattern is a ustring -> ustring
```

A ustring assigns to a string as UTF-8, so `dim as string s = d.ToIsoString( )` still works.

Parsing is byte-oriented ASCII throughout; the ustring parse overloads convert to UTF-8 and run the same C parser, which is exact for every input the parser accepts.

## Interop AND The datetime.bi Bridge

Six external epochs, each one addition away from the tick model:

```freebasic
Unix seconds/ms/us      Instant and DateTime, both directions
Win32 FILETIME          .FileTime / .FromFileTime      1601-01-01
OLE automation date     .OleDate / .FromOleDate        1899-12-30
Julian day              .JulianDay / .JulianDayNumber / .FromJulianDay
serial float64          .Serial / .FromSerial          datetime.bi

dim as float64 serial = DateSerial( 2025, 3, 4 )
dim as chrono.DateTime d = chrono.DateTime.FromSerial( serial )
dim as float64 back   = d.Serial
```

The serial bridge is LOSSY BELOW ABOUT A MILLISECOND -- a double carries ~15 significant digits and a present-day serial spends most of them on the integer part. Everything above millisecond resolution round-trips exactly, asserted over 1900-2100. Nothing else in this list is lossy.

migration.md maps every datetime.bi and AfxNova member to its equivalent, and says so plainly where there is none.

## The Rules That Are Easy To Get Wrong

Each has a defensible opposite, so each is a decision rather than an accident, and each is asserted in the suite.

```freebasic
Invalid = Invalid                false. Use IsValid.
CompareTo with an Invalid        -2, which is not an ordering
MaxValue.AddTicks( 1 )           Invalid, never a wrap
DateTime( 2025, 13, 1 )          Invalid, never normalized into 2026-01-01
dim as LocalDate d               Invalid -- but a defaulted TimeSpan and
                                 LocalTime are zero, which is a real value
naive.ToInstant( )               Invalid -- nobody said what the offset was
naive.AssumeUtc( )               the way to say it, and it names the
                                 assumption in the call
EndOfDay                         the last tick, 23:59:59.9999999
NextWeekday( sameDay )           a week forward, not a no-op
DayOfWeek                        1 = Monday, unlike Weekday( )
IsoWeekYear                      not Year, at either end of December
AddDays( 1 ) across DST          exactly 86400s; the wall time moves
AddMonths then reverse           does not return to the original day
TotalHours vs Hours              26.05 vs 2, for the same span
negative span components         all negative, so they reconstruct
TimeSpan.DivideBy( zero )        NaN, not Invalid -- it is a float64
ToString( "d" )                  the named int16-date format, not a field
ToLocaleString                   not reproducible; never write it to a file
```

TIME ZONES HERE ARE THE OS's: the machine's own zone. Every other zone, by its IANA name, is [Time Zones](Category-Time-Zones) (std/tz). AssumeLocal reads a wall reading in the OS zone: in a fall-back overlap it names the EARLIER instant, and in a spring-forward gap the reading moves forward by the gap. Programs that care about an exact point in time should carry an Instant and never round-trip through a naive DateTime.

## WHERE THIS DIFFERS FROM datetime.bi

1. OUT-OF-RANGE INPUT IS REFUSED, NOT NORMALIZED. DateSerial( 2025, 13, 40 )

```freebasic
rolls into the next year; DateTime( 2025, 13, 40 ) is Invalid. Normalizing
means a typo and a valid date are indistinguishable one line later.
```

2. PARSING IS STRICT AND HAS NO LOCALE. DateValue guesses field order from the

```freebasic
machine's locale, so "03/04/2025" means two different days in two countries.
TryParseIso refuses it, and TryParseExact makes you say which you meant.
```

3. DAY OF WEEK IS 1 = MONDAY, not 1 = Sunday.

4. THERE IS A DURATION TYPE. datetime.bi's answer to "how far apart" is a

```freebasic
subtraction of two doubles giving fractional days, which loses what unit it
is in as soon as it is stored.
```

5. RESOLUTION IS 100 ns, not 1 second, and it does not degrade with distance

```freebasic
from the epoch -- a serial double loses sub-second precision simply by being
a large number.
```

6. ELAPSED TIME HAS ITS OWN CLOCK. TIMER is the wall clock and jumps; Stopwatch

```freebasic
does not.
```

7. AN OFFSET IS CARRIED, AND ITS ABSENCE IS RECORDED. Now( ) returns local time

```freebasic
with no way to say so. WallClock.Now( ) records the offset it was taken under.
```

Nothing in datetime.bi changed, and both surfaces can be used in the same program. Where a datetime.bi call has no equivalent here, migration.md says so instead of inventing one.

AGAINST AfxNova's date and time helpers, the shape of the difference is the same, plus: nothing here is Windows-only or COM-bound, and the formatter is invariant by default with locale output as the opt-in rather than the reverse. comparison-matrix.md scores this library, datetime.bi, AfxNova, C#, java.time and NodaTime feature by feature.

## What Is NOT Here

Each is argued in rationale.md rather than left as an omission.

```freebasic
LEAP SECONDS. The tick line is a count; a leap second is a discontinuity
that needs a table which must be updated by hand and which no OS exposes
reliably. UTC-SLS and the smeared clocks are what production systems
actually run.

NAMED ZONES. They are std/tz: TimeZone, ZonedDateTime, the policies for a
reading that happens twice or never, and std/tzdata for the database itself.
See [Time Zones](Category-Time-Zones).

NON-GREGORIAN CALENDARS. Proleptic Gregorian, year 1 to 9999, and no
calendar abstraction to make room for others.

A LENIENT PARSER. There is no equivalent of DateValue's guessing. If the
input is not ISO 8601, name the pattern.
```

## Implementation

```freebasic
pkg/std/chrono/                 the whole tiko surface -- one #import
lib/rt/src/inc/chrono.ti        the tick representation and its constants
lib/rt/src/chrono/core.tiko      civil<->tick kernel, calendar primitives
lib/rt/src/chrono/iso.tiko       ISO 8601 emit and strict parse
lib/rt/src/chrono/pattern.tiko   pattern formatter and parser, invariant
lib/rt/src/chrono/clock.tiko     wall, monotonic and CPU clocks
lib/rt/src/chrono/zone.tiko      offsets, DST, locale formatting
```

The kernel in core.bas is PURE: no OS calls, no allocation, no locale, no static state. Everything platform-specific is in clock.bas and zone.bas, which is what makes the civil<->tick conversion testable exhaustively.

The tiko side is a module of value types with no compiler support of any kind. Its C entry points are reached through 'extern "C" declare ... alias' -- the pattern inc/string.bi already uses. Note that 'alias' alone is not enough inside a module: without the extern "C" the name is mangled through the module's chain.

clock.bas and zone.bas each hold BOTH platform halves, chosen by #if. tiko-rt's build has no per-target source selection, so the split is made inside the file.

zone.bas resolves GetTimeZoneInformationForYear, which needs Windows 7, through GetProcAddress rather than importing it, so the binary's minimum OS is not raised for one function. When it is absent the static fallback still answers correctly for the current year.

## Tests

```freebasic
tests/vendor/fbc-tests/chrono/core.bas       ticks, components, construction, Invalid
tests/vendor/fbc-tests/chrono/spans.bas      TimeSpan, totals, components, operators
tests/vendor/fbc-tests/chrono/calendar.bas   calendar arithmetic and utilities
tests/vendor/fbc-tests/chrono/clocks.bas     WallClock, Stopwatch, CpuClock
tests/vendor/fbc-tests/chrono/iso.bas        ISO 8601 emit and parse, both directions
tests/vendor/fbc-tests/chrono/pattern.bas    every pattern letter at every run length
tests/vendor/fbc-tests/chrono/zones.bas      offsets, DST, locale invariants
tests/vendor/fbc-tests/chrono/utext.bas      the USTRING overloads
```

These are fbcunit suites, vendored in tiko-lang. The datetime.bi surface has 3 suites of its own in tests/vendor/fbc-tests/datetime/.

ASSERT YOUR TEST GENERATOR'S RANGE. Every fixed-seed sweep here originally drew its tick as 'clngint( ( seed shr 11 ) mod culngint( DT_MAX_TICKS ) )'. The shift leaves 53 bits, 2^53 is SMALLER than DT_MAX_TICKS, so the mod was a no-op and every "random" value landed in years 1-29. Five suites were affected and their coverage claims were overstated for four phases before it was caught. The correct form is 'clngint( seed mod culngint( DT_MAX_TICKS ) )'. Re-running found no implementation bugs -- the layers were right, the sweeps were just tiny.

## Dialects

-lang fb. The library is namespaced, uses properties and operator overloading throughout, and the USTRING overloads need tiko-lang's USTRING type.

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Dates and times](Functions-Dates) lists them beside the rest of the area.

### Get the current date and time

| Function | What it does | From |
|---|---|---|
| [WallClock.UtcNow](Modern-Chrono-WallClock-UtcNow) | Returns the current moment on the UTC timeline, read from the system clock. | `std/chrono` |
| [WallClock.Now](Modern-Chrono-WallClock-Now) | Returns the local date and time, with the UTC offset in force at this moment. | `std/chrono` |
| [WallClock.Today](Modern-Chrono-WallClock-Today) | Returns today's local date as a LocalDate. | `std/chrono` |
| [WallClock.TimeOfDay](Modern-Chrono-WallClock-TimeOfDay) | Returns the current local time of day as a LocalTime. | `std/chrono` |
| [WallClock.Resolution](Modern-Chrono-WallClock-Resolution) | Returns the smallest step the wall clock reports, as a TimeSpan. | `std/chrono` |

### Time how long something takes

| Function | What it does | From |
|---|---|---|
| [Stopwatch.StartNew](Modern-Chrono-Stopwatch-StartNew) | Creates a stopwatch that is already running. | `std/chrono` |
| [Stopwatch.Stopwatch](Modern-Chrono-Stopwatch-Stopwatch) | Creates a stopped stopwatch on the monotonic clock, which never jumps. | `std/chrono` |
| [Stopwatch.Start](Modern-Chrono-Stopwatch-Start) | Starts the stopwatch, or resumes it and keeps the time already measured. | `std/chrono` |
| [Stopwatch.Stop_](Modern-Chrono-Stopwatch-Stop) | Stops the stopwatch, freezing the elapsed time until it starts again. | `std/chrono` |
| [Stopwatch.Reset](Modern-Chrono-Stopwatch-Reset) | Stops the stopwatch and sets its elapsed time back to zero. | `std/chrono` |
| [Stopwatch.Restart](Modern-Chrono-Stopwatch-Restart) | Sets the elapsed time back to zero and keeps the stopwatch running. | `std/chrono` |
| [Stopwatch.IsRunning](Modern-Chrono-Stopwatch-IsRunning) | Returns true while the stopwatch is running. | `std/chrono` |
| [Stopwatch.Elapsed](Modern-Chrono-Stopwatch-Elapsed) | Returns the time measured so far as a TimeSpan. | `std/chrono` |
| [Stopwatch.ElapsedMilliseconds](Modern-Chrono-Stopwatch-ElapsedMilliseconds) | Returns the time measured so far in whole milliseconds. | `std/chrono` |
| [Stopwatch.ElapsedTicks](Modern-Chrono-Stopwatch-ElapsedTicks) | Returns the time measured so far in 100 ns ticks. | `std/chrono` |
| [Stopwatch.GetTimestamp](Modern-Chrono-Stopwatch-GetTimestamp) | Returns the raw monotonic counter; divide a difference by Frequency to get seconds. | `std/chrono` |
| [Stopwatch.Frequency](Modern-Chrono-Stopwatch-Frequency) | Returns how many counts per second the raw counter from GetTimestamp makes. | `std/chrono` |
| [Stopwatch.IsHighResolution](Modern-Chrono-Stopwatch-IsHighResolution) | Returns true if the platform counter is finer than the system tick. | `std/chrono` |
| [CpuClock.ProcessTime](Modern-Chrono-CpuClock-ProcessTime) | Returns the processor time this process has used so far, user and kernel together. | `std/chrono` |
| [CpuClock.ProcessUserTime](Modern-Chrono-CpuClock-ProcessUserTime) | Returns the processor time this process has spent running its own code. | `std/chrono` |
| [CpuClock.ProcessKernelTime](Modern-Chrono-CpuClock-ProcessKernelTime) | Returns the processor time the OS has spent working on behalf of this process. | `std/chrono` |
| [CpuClock.ThreadTime](Modern-Chrono-CpuClock-ThreadTime) | Returns the processor time the calling thread has used, user and kernel together. | `std/chrono` |
| [CpuClock.IsSupported](Modern-Chrono-CpuClock-IsSupported) | Returns true if the platform can report processor time. | `std/chrono` |

### Make a date, a time or a date-time

| Function | What it does | From |
|---|---|---|
| [DateTime](Modern-Chrono-DateTime-DateTime) | Creates a date-time from a year, month, day and optional time, or Invalid if none. | `std/chrono` |
| [LocalDate.LocalDate](Modern-Chrono-LocalDate-LocalDate) | Creates a date with no time of day from a year, month and day, or Invalid if none. | `std/chrono` |
| [LocalTime.LocalTime](Modern-Chrono-LocalTime-LocalTime) | Creates a time of day from hours, minutes, seconds and milliseconds; midnight if none. | `std/chrono` |
| [Instant.Instant](Modern-Chrono-Instant-Instant) | Creates a moment on the UTC timeline from a tick count; Invalid with no argument. | `std/chrono` |
| [Instant.FromTicks](Modern-Chrono-Instant-FromTicks) | Creates a moment from 100 ns ticks since 0001-01-01, or Invalid if out of range. | `std/chrono` |
| [DateTime.FromDate](Modern-Chrono-DateTime-FromDate) | Returns a date-time at midnight on the given date. | `std/chrono` |
| [DateTime.FromDateTime](Modern-Chrono-DateTime-FromDateTime) | Returns a date-time that joins a date and a time of day. | `std/chrono` |
| [LocalDate.FromDayNumber](Modern-Chrono-LocalDate-FromDayNumber) | Creates a date from a count of days since 0001-01-01. | `std/chrono` |
| [LocalTime.FromTicks](Modern-Chrono-LocalTime-FromTicks) | Creates a time of day from 100 ns ticks since midnight, or Invalid past a whole day. | `std/chrono` |
| [LocalTime.Midnight](Modern-Chrono-LocalTime-Midnight) | Returns the time of day 00:00:00. | `std/chrono` |
| [LocalTime.Noon](Modern-Chrono-LocalTime-Noon) | Returns the time of day 12:00:00. | `std/chrono` |

### Read the year, month, day and time

| Function | What it does | From |
|---|---|---|
| [DateTime.Year](Modern-Chrono-DateTime-Year) | Returns the year, 1 to 9999. | `std/chrono` |
| [DateTime.Month](Modern-Chrono-DateTime-Month) | Returns the month, 1 to 12. | `std/chrono` |
| [DateTime.Day](Modern-Chrono-DateTime-Day) | Returns the day of the month, starting at 1. | `std/chrono` |
| [DateTime.Hour](Modern-Chrono-DateTime-Hour) | Returns the hour, 0 to 23. | `std/chrono` |
| [DateTime.Minute](Modern-Chrono-DateTime-Minute) | Returns the minute, 0 to 59. | `std/chrono` |
| [DateTime.Second](Modern-Chrono-DateTime-Second) | Returns the second, 0 to 59. | `std/chrono` |
| [DateTime.Millisecond](Modern-Chrono-DateTime-Millisecond) | Returns the milliseconds within the second, 0 to 999. | `std/chrono` |
| [DateTime.Microsecond](Modern-Chrono-DateTime-Microsecond) | Returns the microseconds within the second, the milliseconds included. | `std/chrono` |
| [DateTime.TickOfDay](Modern-Chrono-DateTime-TickOfDay) | Returns the time of day as one number: 100 ns ticks since midnight. | `std/chrono` |
| [DateTime.GetDate](Modern-Chrono-DateTime-GetDate) | Returns the date part as a LocalDate, dropping the time and the offset. | `std/chrono` |
| [DateTime.GetTimeOfDay](Modern-Chrono-DateTime-GetTimeOfDay) | Returns the time-of-day part as a LocalTime. | `std/chrono` |
| [LocalDate.Year](Modern-Chrono-LocalDate-Year) | Returns the year, 1 to 9999. | `std/chrono` |
| [LocalDate.Month](Modern-Chrono-LocalDate-Month) | Returns the month, 1 to 12. | `std/chrono` |
| [LocalDate.Day](Modern-Chrono-LocalDate-Day) | Returns the day of the month, starting at 1. | `std/chrono` |
| [LocalTime.Hour](Modern-Chrono-LocalTime-Hour) | Returns the hour, 0 to 23. | `std/chrono` |
| [LocalTime.Minute](Modern-Chrono-LocalTime-Minute) | Returns the minute, 0 to 59. | `std/chrono` |
| [LocalTime.Second](Modern-Chrono-LocalTime-Second) | Returns the second, 0 to 59. | `std/chrono` |
| [LocalTime.Millisecond](Modern-Chrono-LocalTime-Millisecond) | Returns the milliseconds within the second, 0 to 999. | `std/chrono` |
| [LocalTime.Microsecond](Modern-Chrono-LocalTime-Microsecond) | Returns the microseconds within the second, the milliseconds included. | `std/chrono` |

### Add days, months and years

| Function | What it does | From |
|---|---|---|
| [AddDays](Modern-Chrono-AddDays) | Adds days of exactly 24 hours, so the clock time can shift across a DST change. | `std/chrono` |
| [AddCalendarDays](Modern-Chrono-AddCalendarDays) | Adds calendar days, keeping the same clock time across a DST change. | `std/chrono` |
| [AddMonths](Modern-Chrono-AddMonths) | Adds calendar months and leaves the UTC offset untouched. | `std/chrono` |
| [AddCalendarMonths](Modern-Chrono-AddCalendarMonths) | Adds calendar months, then works out the UTC offset again for the new date. | `std/chrono` |
| [Instant.Add](Modern-Chrono-Instant-Add) | Returns the date-time moved forward by a TimeSpan. | `std/chrono` |
| [Instant.Subtract](Modern-Chrono-Instant-Subtract) | Returns the date-time moved back by a TimeSpan, or Invalid past the earliest date. | `std/chrono` |
| [DateTime.AddTicks](Modern-Chrono-DateTime-AddTicks) | Returns the date-time moved by a number of 100 ns ticks. | `std/chrono` |
| [DateTime.AddMilliseconds](Modern-Chrono-DateTime-AddMilliseconds) | Returns the date-time moved by a number of milliseconds, fractions allowed. | `std/chrono` |
| [DateTime.AddSeconds](Modern-Chrono-DateTime-AddSeconds) | Returns the date-time moved by a number of seconds, fractions allowed. | `std/chrono` |
| [DateTime.AddMinutes](Modern-Chrono-DateTime-AddMinutes) | Returns the date-time moved by a number of minutes, fractions allowed. | `std/chrono` |
| [DateTime.AddHours](Modern-Chrono-DateTime-AddHours) | Returns the date-time moved by a number of hours, fractions allowed. | `std/chrono` |
| [DateTime.AddDays](Modern-Chrono-DateTime-AddDays) | Returns the date-time moved by days of exactly 24 hours, fractions allowed. | `std/chrono` |
| [DateTime.AddMonths](Modern-Chrono-DateTime-AddMonths) | Returns the date-time moved by whole months, clamping the day to the month's end. | `std/chrono` |
| [DateTime.AddYears](Modern-Chrono-DateTime-AddYears) | Returns the date-time moved by whole years; 29 February becomes the 28th if needed. | `std/chrono` |
| [DateTime.AddCalendarDays](Modern-Chrono-DateTime-AddCalendarDays) | Returns the same clock time a number of days later, even across a DST change. | `std/chrono` |
| [DateTime.AddCalendarMonths](Modern-Chrono-DateTime-AddCalendarMonths) | Returns the same clock time some months later, clamping the day to the month's end. | `std/chrono` |
| [DateTime.AddCalendarYears](Modern-Chrono-DateTime-AddCalendarYears) | Returns the same clock time some years later, with the UTC offset worked out again. | `std/chrono` |
| [LocalDate.AddDays](Modern-Chrono-LocalDate-AddDays) | Returns the date moved by a number of days. | `std/chrono` |
| [LocalDate.AddMonths](Modern-Chrono-LocalDate-AddMonths) | Returns the date moved by whole months, clamping the day to the month's end. | `std/chrono` |
| [LocalDate.AddYears](Modern-Chrono-LocalDate-AddYears) | Returns the date moved by whole years; 29 February becomes the 28th if needed. | `std/chrono` |

### Compare dates and count the days between

| Function | What it does | From |
|---|---|---|
| [LocalDate.DayNumber](Modern-Chrono-LocalDate-DayNumber) | Returns the days since 0001-01-01; subtract two to count the days between dates. | `std/chrono` |
| [Instant.CompareTo](Modern-Chrono-Instant-CompareTo) | Returns -1, 0 or 1 to order two moments, or -2 if either is Invalid. | `std/chrono` |
| [LocalDate.CompareTo](Modern-Chrono-LocalDate-CompareTo) | Returns -1, 0 or 1 to order two dates, or -2 if either is Invalid. | `std/chrono` |
| [LocalTime.CompareTo](Modern-Chrono-LocalTime-CompareTo) | Returns -1, 0 or 1 to order two times of day, or -2 if either is Invalid. | `std/chrono` |

### Turn dates and durations into text

| Function | What it does | From |
|---|---|---|
| [Instant.ToIsoString](Modern-Chrono-Instant-ToIsoString) | Returns the date-time as ISO 8601 text, with Z or the offset when it has one. | `std/chrono` |
| [Instant.ToString](Modern-Chrono-Instant-ToString) | Returns ISO 8601 text, or the date-time laid out by a pattern such as "yyyy-MM-dd". | `std/chrono` |
| [DateTime.TryFormat](Modern-Chrono-DateTime-TryFormat) | Formats the date-time with a pattern into a variable; returns false if the pattern is bad. | `std/chrono` |
| [LocalDate.ToIsoString](Modern-Chrono-LocalDate-ToIsoString) | Returns the date as text in the form 2026-08-13, or empty text if it is Invalid. | `std/chrono` |
| [LocalDate.ToString](Modern-Chrono-LocalDate-ToString) | Returns the date as ISO 8601 text, the same as ToIsoString. | `std/chrono` |
| [LocalTime.ToIsoString](Modern-Chrono-LocalTime-ToIsoString) | Returns the time of day as ISO 8601 text, such as 14:30:05. | `std/chrono` |
| [LocalTime.ToString](Modern-Chrono-LocalTime-ToString) | Returns the time of day as ISO 8601 text, the same as ToIsoString. | `std/chrono` |
| [TimeSpan.ToIsoString](Modern-Chrono-TimeSpan-ToIsoString) | Returns the duration as ISO 8601 text, such as PT1H30M. | `std/chrono` |
| [TimeSpan.ToString](Modern-Chrono-TimeSpan-ToString) | Returns the duration as ISO 8601 text, the same as ToIsoString. | `std/chrono` |

### Read dates and durations from text

| Function | What it does | From |
|---|---|---|
| [Instant.ParseIso](Modern-Chrono-Instant-ParseIso) | Reads ISO 8601 text into a date-time, or Invalid if it is not ISO 8601. | `std/chrono` |
| [Instant.TryParseIso](Modern-Chrono-Instant-TryParseIso) | Reads ISO 8601 text into a date-time; returns false and sets it Invalid on failure. | `std/chrono` |
| [DateTime.TryParse](Modern-Chrono-DateTime-TryParse) | Reads ISO 8601 text into a date-time, the same as TryParseIso. | `std/chrono` |
| [DateTime.ParseExact](Modern-Chrono-DateTime-ParseExact) | Reads text laid out by a pattern such as "dd/MM/yyyy", or Invalid if it does not match. | `std/chrono` |
| [DateTime.TryParseExact](Modern-Chrono-DateTime-TryParseExact) | Reads text laid out by a pattern into a date-time; returns false if it does not match. | `std/chrono` |
| [LocalDate.ParseIso](Modern-Chrono-LocalDate-ParseIso) | Reads ISO text such as 2026-08-13 into a date, or Invalid on failure. | `std/chrono` |
| [LocalDate.TryParseIso](Modern-Chrono-LocalDate-TryParseIso) | Reads ISO text into a date; returns false and sets it Invalid on failure. | `std/chrono` |
| [LocalTime.ParseIso](Modern-Chrono-LocalTime-ParseIso) | Reads ISO text such as 14:30:05 into a time of day, or Invalid on failure. | `std/chrono` |
| [LocalTime.TryParseIso](Modern-Chrono-LocalTime-TryParseIso) | Reads ISO text into a time of day; returns false and sets it Invalid on failure. | `std/chrono` |
| [TimeSpan.ParseIso](Modern-Chrono-TimeSpan-ParseIso) | Reads an ISO 8601 duration such as P1DT2H into a TimeSpan, or Invalid on failure. | `std/chrono` |
| [TimeSpan.TryParseIso](Modern-Chrono-TimeSpan-TryParseIso) | Reads an ISO 8601 duration; returns false and sets it Invalid on failure. | `std/chrono` |

### Weekdays, weeks and quarters

| Function | What it does | From |
|---|---|---|
| [DateTime.DayOfWeek](Modern-Chrono-DateTime-DayOfWeek) | Returns the day of the week, 1 for Monday to 7 for Sunday. | `std/chrono` |
| [DateTime.DayOfYear](Modern-Chrono-DateTime-DayOfYear) | Returns the day of the year, starting at 1. | `std/chrono` |
| [DateTime.IsoWeek](Modern-Chrono-DateTime-IsoWeek) | Returns the ISO week number, 1 to 53; pair it with IsoWeekYear. | `std/chrono` |
| [DateTime.IsoWeekYear](Modern-Chrono-DateTime-IsoWeekYear) | Returns the year the ISO week belongs to, which can differ from Year near New Year. | `std/chrono` |
| [DateTime.Quarter](Modern-Chrono-DateTime-Quarter) | Returns the calendar quarter, 1 to 4. | `std/chrono` |
| [LocalDate.DayOfWeek](Modern-Chrono-LocalDate-DayOfWeek) | Returns the day of the week, 1 for Monday to 7 for Sunday. | `std/chrono` |
| [LocalDate.DayOfYear](Modern-Chrono-LocalDate-DayOfYear) | Returns the day of the year, starting at 1. | `std/chrono` |
| [LocalDate.IsoWeek](Modern-Chrono-LocalDate-IsoWeek) | Returns the ISO week number, 1 to 53; pair it with IsoWeekYear. | `std/chrono` |
| [LocalDate.IsoWeekYear](Modern-Chrono-LocalDate-IsoWeekYear) | Returns the year the ISO week belongs to, which can differ from Year near New Year. | `std/chrono` |
| [LocalDate.Quarter](Modern-Chrono-LocalDate-Quarter) | Returns the calendar quarter, 1 to 4. | `std/chrono` |

### Month and weekday names

| Function | What it does | From |
|---|---|---|
| [DateTime.MonthName](Modern-Chrono-DateTime-MonthName) | Returns a month's name in the user's language, or its abbreviation. | `std/chrono` |
| [DateTime.WeekdayName](Modern-Chrono-DateTime-WeekdayName) | Returns a weekday's name in the user's language, 1 being Monday, or its abbreviation. | `std/chrono` |

### Jump to the start or end of a day, week, month or year

| Function | What it does | From |
|---|---|---|
| [DateTime.StartOfDay](Modern-Chrono-DateTime-StartOfDay) | Returns midnight at the start of the same day, keeping the offset. | `std/chrono` |
| [DateTime.EndOfDay](Modern-Chrono-DateTime-EndOfDay) | Returns the last tick of the same day, 23:59:59.9999999. | `std/chrono` |
| [DateTime.StartOfWeek](Modern-Chrono-DateTime-StartOfWeek) | Returns midnight on the first day of the week, Monday unless told otherwise. | `std/chrono` |
| [DateTime.StartOfMonth](Modern-Chrono-DateTime-StartOfMonth) | Returns midnight on the first day of the month. | `std/chrono` |
| [DateTime.EndOfMonth](Modern-Chrono-DateTime-EndOfMonth) | Returns the last tick of the last day of the month. | `std/chrono` |
| [DateTime.StartOfYear](Modern-Chrono-DateTime-StartOfYear) | Returns midnight on 1 January of the same year. | `std/chrono` |
| [DateTime.EndOfYear](Modern-Chrono-DateTime-EndOfYear) | Returns the last tick of 31 December of the same year. | `std/chrono` |
| [DateTime.NextWeekday](Modern-Chrono-DateTime-NextWeekday) | Returns the same time on the next given weekday, always strictly later. | `std/chrono` |
| [DateTime.PrevWeekday](Modern-Chrono-DateTime-PrevWeekday) | Returns the same time on the previous given weekday, always strictly earlier. | `std/chrono` |
| [DateTime.IsFirstDayOfMonth](Modern-Chrono-DateTime-IsFirstDayOfMonth) | Returns true if the date is the first day of its month. | `std/chrono` |
| [DateTime.IsLastDayOfMonth](Modern-Chrono-DateTime-IsLastDayOfMonth) | Returns true if the date is the last day of its month. | `std/chrono` |
| [LocalDate.StartOfMonth](Modern-Chrono-LocalDate-StartOfMonth) | Returns the first day of the date's month. | `std/chrono` |
| [LocalDate.EndOfMonth](Modern-Chrono-LocalDate-EndOfMonth) | Returns the last day of the date's month. | `std/chrono` |
| [LocalDate.IsFirstDayOfMonth](Modern-Chrono-LocalDate-IsFirstDayOfMonth) | Returns true if the date is the first day of its month. | `std/chrono` |
| [LocalDate.IsLastDayOfMonth](Modern-Chrono-LocalDate-IsLastDayOfMonth) | Returns true if the date is the last day of its month. | `std/chrono` |

### Leap years and month lengths

| Function | What it does | From |
|---|---|---|
| [DateTime.IsLeapYear](Modern-Chrono-DateTime-IsLeapYear) | Returns true if a year is a leap year under the full Gregorian rule. | `std/chrono` |
| [DateTime.DaysInMonth](Modern-Chrono-DateTime-DaysInMonth) | Returns the number of days in a month of a given year. | `std/chrono` |
| [DateTime.DaysInYear](Modern-Chrono-DateTime-DaysInYear) | Returns 365 or 366, the number of days in a year. | `std/chrono` |
| [DateTime.WeeksInYear](Modern-Chrono-DateTime-WeeksInYear) | Returns 52 or 53, the number of ISO weeks in a year. | `std/chrono` |

### TimeSpan: make a duration

| Function | What it does | From |
|---|---|---|
| [TimeSpan.TimeSpan](Modern-Chrono-TimeSpan-TimeSpan) | Creates a duration from ticks, or from hours, minutes and seconds, with or without days. | `std/chrono` |
| [TimeSpan.FromDays](Modern-Chrono-TimeSpan-FromDays) | Returns a duration of a number of days, fractions allowed. | `std/chrono` |
| [TimeSpan.FromHours](Modern-Chrono-TimeSpan-FromHours) | Returns a duration of a number of hours, fractions allowed. | `std/chrono` |
| [TimeSpan.FromMinutes](Modern-Chrono-TimeSpan-FromMinutes) | Returns a duration of a number of minutes, fractions allowed. | `std/chrono` |
| [TimeSpan.FromSeconds](Modern-Chrono-TimeSpan-FromSeconds) | Returns a duration of a number of seconds, fractions allowed. | `std/chrono` |
| [TimeSpan.FromMilliseconds](Modern-Chrono-TimeSpan-FromMilliseconds) | Returns a duration of a number of milliseconds, fractions allowed. | `std/chrono` |
| [TimeSpan.FromMicroseconds](Modern-Chrono-TimeSpan-FromMicroseconds) | Returns a duration of a whole number of microseconds. | `std/chrono` |
| [TimeSpan.FromTicks](Modern-Chrono-TimeSpan-FromTicks) | Returns a duration of an exact number of 100 ns ticks. | `std/chrono` |
| [TimeSpan.Zero](Modern-Chrono-TimeSpan-Zero) | Returns a duration of zero, the same as a new TimeSpan. | `std/chrono` |

### TimeSpan: totals and parts

| Function | What it does | From |
|---|---|---|
| [TimeSpan.TotalDays](Modern-Chrono-TimeSpan-TotalDays) | Returns the whole duration in days, with a fraction. | `std/chrono` |
| [TimeSpan.TotalHours](Modern-Chrono-TimeSpan-TotalHours) | Returns the whole duration in hours, with a fraction. | `std/chrono` |
| [TimeSpan.TotalMinutes](Modern-Chrono-TimeSpan-TotalMinutes) | Returns the whole duration in minutes, with a fraction. | `std/chrono` |
| [TimeSpan.TotalSeconds](Modern-Chrono-TimeSpan-TotalSeconds) | Returns the whole duration in seconds, with a fraction. | `std/chrono` |
| [TimeSpan.TotalMilliseconds](Modern-Chrono-TimeSpan-TotalMilliseconds) | Returns the whole duration in milliseconds, with a fraction. | `std/chrono` |
| [TimeSpan.TotalMicroseconds](Modern-Chrono-TimeSpan-TotalMicroseconds) | Returns the whole duration in whole microseconds. | `std/chrono` |
| [TimeSpan.Days](Modern-Chrono-TimeSpan-Days) | Returns the days part of the duration, negative for a negative span. | `std/chrono` |
| [TimeSpan.Hours](Modern-Chrono-TimeSpan-Hours) | Returns the hours part, 0 to 23, negative for a negative span. | `std/chrono` |
| [TimeSpan.Minutes](Modern-Chrono-TimeSpan-Minutes) | Returns the minutes part, 0 to 59, negative for a negative span. | `std/chrono` |
| [TimeSpan.Seconds](Modern-Chrono-TimeSpan-Seconds) | Returns the seconds part, 0 to 59, negative for a negative span. | `std/chrono` |
| [TimeSpan.Milliseconds](Modern-Chrono-TimeSpan-Milliseconds) | Returns the milliseconds part, 0 to 999, negative for a negative span. | `std/chrono` |
| [TimeSpan.Microseconds](Modern-Chrono-TimeSpan-Microseconds) | Returns the microseconds within the second, the milliseconds included. | `std/chrono` |
| [TimeSpan.Ticks](Modern-Chrono-TimeSpan-Ticks) | Returns the duration as a count of 100 ns ticks. | `std/chrono` |
| [TimeSpan.IsZero](Modern-Chrono-TimeSpan-IsZero) | Returns true if the duration is exactly zero, and false if it is Invalid. | `std/chrono` |
| [TimeSpan.IsNegative](Modern-Chrono-TimeSpan-IsNegative) | Returns true if the duration is below zero. | `std/chrono` |

### TimeSpan: arithmetic and comparison

| Function | What it does | From |
|---|---|---|
| [TimeSpan.Add](Modern-Chrono-TimeSpan-Add) | Returns the sum of two durations, or Invalid on overflow. | `std/chrono` |
| [TimeSpan.Subtract](Modern-Chrono-TimeSpan-Subtract) | Returns the difference of two durations, which may be negative. | `std/chrono` |
| [TimeSpan.Multiply](Modern-Chrono-TimeSpan-Multiply) | Returns the duration scaled by a factor, fractions allowed. | `std/chrono` |
| [TimeSpan.Divide](Modern-Chrono-TimeSpan-Divide) | Returns the duration divided by a number, or Invalid when dividing by zero. | `std/chrono` |
| [TimeSpan.DivideBy](Modern-Chrono-TimeSpan-DivideBy) | Returns how many times one duration fits in another, as a double. | `std/chrono` |
| [TimeSpan.Negate](Modern-Chrono-TimeSpan-Negate) | Returns the duration with its sign flipped. | `std/chrono` |
| [TimeSpan.Duration](Modern-Chrono-TimeSpan-Duration) | Returns the absolute value of the duration. | `std/chrono` |
| [TimeSpan.CompareTo](Modern-Chrono-TimeSpan-CompareTo) | Returns -1, 0 or 1 to order two durations, or -2 if either is Invalid. | `std/chrono` |

### Work with UTC and time-zone offsets

| Function | What it does | From |
|---|---|---|
| [DateTime.WithOffset](Modern-Chrono-DateTime-WithOffset) | Attaches a UTC offset in minutes, keeping the clock reading and changing the moment. | `std/chrono` |
| [DateTime.ToOffset](Modern-Chrono-DateTime-ToOffset) | Converts to another UTC offset, keeping the moment and changing the clock reading. | `std/chrono` |
| [DateTime.OffsetMinutes](Modern-Chrono-DateTime-OffsetMinutes) | Returns the UTC offset in minutes; check HasOffset first, as no offset reads 32767. | `std/chrono` |
| [DateTime.HasOffset](Modern-Chrono-DateTime-HasOffset) | Returns true if the date-time carries a UTC offset. | `std/chrono` |
| [DateTime.IsUtc](Modern-Chrono-DateTime-IsUtc) | Returns true if the offset is zero; a date-time with no offset is not UTC. | `std/chrono` |
| [DateTime.ToInstant](Modern-Chrono-DateTime-ToInstant) | Returns the moment the date-time names, or Invalid if it has no offset. | `std/chrono` |
| [DateTime.AssumeUtc](Modern-Chrono-DateTime-AssumeUtc) | Returns the moment the date-time names if its clock reading is taken as UTC. | `std/chrono` |
| [DateTime.ToLocal](Modern-Chrono-DateTime-ToLocal) | Returns the same moment shown at the machine's local UTC offset. | `std/chrono` |
| [DateTime.FromInstant](Modern-Chrono-DateTime-FromInstant) | Returns the date-time a moment shows on a clock with the given UTC offset. | `std/chrono` |
| [TimeZoneInfo.LocalOffsetAt](Modern-Chrono-TimeZoneInfo-LocalOffsetAt) | Returns the local zone's UTC offset in minutes at a given moment, DST included. | `std/chrono` |
| [TimeZoneInfo.TryLocalOffsetAt](Modern-Chrono-TimeZoneInfo-TryLocalOffsetAt) | Gets the local zone's UTC offset at a given moment, returning false for an Invalid moment. | `std/chrono` |
| [TimeZoneInfo.LocalOffset](Modern-Chrono-TimeZoneInfo-LocalOffset) | Returns the local zone's UTC offset in minutes right now. | `std/chrono` |
| [TimeZoneInfo.IsDaylightSavingTime](Modern-Chrono-TimeZoneInfo-IsDaylightSavingTime) | Returns true if daylight saving time is in force in the local zone at a given moment. | `std/chrono` |
| [TimeZoneInfo.SupportsDaylightSavingTime](Modern-Chrono-TimeZoneInfo-SupportsDaylightSavingTime) | Returns true if the local zone observes daylight saving time at all. | `std/chrono` |
| [TimeZoneInfo.StandardName](Modern-Chrono-TimeZoneInfo-StandardName) | Returns the OS's name for the local zone's standard time. | `std/chrono` |
| [TimeZoneInfo.DaylightName](Modern-Chrono-TimeZoneInfo-DaylightName) | Returns the OS's name for the local zone's daylight saving time. | `std/chrono` |

### Show a date the way the user's machine writes it

| Function | What it does | From |
|---|---|---|
| [DateTime.ToLocaleDateString](Modern-Chrono-DateTime-ToLocaleDateString) | Returns the date as the machine's locale writes it, for display only. | `std/chrono` |
| [DateTime.ToLocaleTimeString](Modern-Chrono-DateTime-ToLocaleTimeString) | Returns the time of day as the machine's locale writes it, for display only. | `std/chrono` |
| [DateTime.ToLocaleString](Modern-Chrono-DateTime-ToLocaleString) | Returns the date and time as the machine's locale writes them, for display only. | `std/chrono` |

### Convert to Unix time, FILETIME and other numbers

| Function | What it does | From |
|---|---|---|
| [Instant.FromUnixSeconds](Modern-Chrono-Instant-FromUnixSeconds) | Returns the moment a number of seconds after 1970-01-01 UTC; negative is earlier. | `std/chrono` |
| [Instant.FromUnixMilliseconds](Modern-Chrono-Instant-FromUnixMilliseconds) | Returns the moment a number of milliseconds after 1970-01-01 UTC. | `std/chrono` |
| [Instant.FromUnixMicroseconds](Modern-Chrono-Instant-FromUnixMicroseconds) | Returns the moment a number of microseconds after 1970-01-01 UTC. | `std/chrono` |
| [Instant.UnixSeconds](Modern-Chrono-Instant-UnixSeconds) | Returns the whole seconds since 1970-01-01 UTC, dropping any fraction. | `std/chrono` |
| [Instant.UnixMilliseconds](Modern-Chrono-Instant-UnixMilliseconds) | Returns the milliseconds since 1970-01-01 UTC. | `std/chrono` |
| [Instant.UnixMicroseconds](Modern-Chrono-Instant-UnixMicroseconds) | Returns the microseconds since 1970-01-01 UTC. | `std/chrono` |
| [Instant.Ticks](Modern-Chrono-Instant-Ticks) | Returns the 100 ns ticks since 0001-01-01, counted on the value's own clock. | `std/chrono` |
| [LocalTime.Ticks](Modern-Chrono-LocalTime-Ticks) | Returns the time of day as 100 ns ticks since midnight. | `std/chrono` |
| [DateTime.Serial](Modern-Chrono-DateTime-Serial) | Returns the date-time as a date serial: days since 1899-12-30, with a fraction. | `std/chrono` |
| [DateTime.FromSerial](Modern-Chrono-DateTime-FromSerial) | Creates a date-time from a date serial, the days since 1899-12-30. | `std/chrono` |
| [DateTime.OleDate](Modern-Chrono-DateTime-OleDate) | Returns the date-time as an OLE automation date, the number Excel and ADO use. | `std/chrono` |
| [DateTime.FromOleDate](Modern-Chrono-DateTime-FromOleDate) | Creates a date-time from an OLE automation date. | `std/chrono` |
| [DateTime.FileTime](Modern-Chrono-DateTime-FileTime) | Returns the date-time as a Windows FILETIME: 100 ns ticks since 1601-01-01. | `std/chrono` |
| [DateTime.FromFileTime](Modern-Chrono-DateTime-FromFileTime) | Creates a UTC date-time from a Windows FILETIME. | `std/chrono` |
| [DateTime.JulianDay](Modern-Chrono-DateTime-JulianDay) | Returns the Julian day, a fractional day count whose days start at noon. | `std/chrono` |
| [DateTime.JulianDayNumber](Modern-Chrono-DateTime-JulianDayNumber) | Returns the whole Julian day number, without the fraction. | `std/chrono` |
| [DateTime.FromJulianDay](Modern-Chrono-DateTime-FromJulianDay) | Creates a date-time from a fractional Julian day. | `std/chrono` |

### Check a value is valid, and the range limits

| Function | What it does | From |
|---|---|---|
| [Instant.IsValid](Modern-Chrono-Instant-IsValid) | Returns true if the date-time is a real, in-range value; the only safe test. | `std/chrono` |
| [Instant.Invalid](Modern-Chrono-Instant-Invalid) | Returns the Invalid date-time, which never equals anything, itself included. | `std/chrono` |
| [Instant.MinValue](Modern-Chrono-Instant-MinValue) | Returns the earliest date-time, midnight on 0001-01-01. | `std/chrono` |
| [Instant.MaxValue](Modern-Chrono-Instant-MaxValue) | Returns the latest date-time, the last tick of 9999-12-31. | `std/chrono` |
| [LocalDate.IsValid](Modern-Chrono-LocalDate-IsValid) | Returns true if the date exists and is in range. | `std/chrono` |
| [LocalDate.Invalid](Modern-Chrono-LocalDate-Invalid) | Returns the Invalid date, which spreads to anything computed from it. | `std/chrono` |
| [LocalDate.MinValue](Modern-Chrono-LocalDate-MinValue) | Returns the earliest date, 0001-01-01. | `std/chrono` |
| [LocalDate.MaxValue](Modern-Chrono-LocalDate-MaxValue) | Returns the latest date, 9999-12-31. | `std/chrono` |
| [LocalTime.IsValid](Modern-Chrono-LocalTime-IsValid) | Returns true if the time of day is in range. | `std/chrono` |
| [LocalTime.Invalid](Modern-Chrono-LocalTime-Invalid) | Returns the Invalid time of day, which never equals anything, itself included. | `std/chrono` |
| [LocalTime.MaxValue](Modern-Chrono-LocalTime-MaxValue) | Returns the last tick of the day, 23:59:59.9999999. | `std/chrono` |
| [TimeSpan.IsValid](Modern-Chrono-TimeSpan-IsValid) | Returns true unless the duration overflowed or came from bad input. | `std/chrono` |
| [TimeSpan.Invalid](Modern-Chrono-TimeSpan-Invalid) | Returns the Invalid duration, which spreads to anything computed from it. | `std/chrono` |
| [TimeSpan.MinValue](Modern-Chrono-TimeSpan-MinValue) | Returns the most negative duration a TimeSpan can hold. | `std/chrono` |
| [TimeSpan.MaxValue](Modern-Chrono-TimeSpan-MaxValue) | Returns the longest duration a TimeSpan can hold. | `std/chrono` |

<!-- finder:end -->

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
