[Home](Home) › [All Categories](Categories) › **Time Zones**

# Time Zones

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz

dim as TimeZone ny = TimeZone.FindById( "America/New_York" )
dim as ZonedDateTime m = ZonedDateTime.FromLocal( chrono.DateTime( 2025, 3, 8, 9, 0, 0, 0 ), ny )

print m.ToIsoString( )                      ' 2025-03-08T09:00:00-05:00[America/New_York]
print m.AddCalendarDays( 1 ).ToIsoString( ) ' 2025-03-09T09:00:00-04:00[America/New_York]
print m.WithZoneSameInstant( TimeZone.FindById( "Europe/Paris" ) ).ToString( "HH:mm v" )   ' 15:00 CET
```

## Why It Exists

[std/chrono](Category-Date-and-Time-Chrono) knows one time zone: the machine's, through the operating system. It cannot say what time it is in Tokyo, or when New York's clocks change, and its `DateTime` carries a fixed offset that is right for one moment only. `std/tz` knows every zone by its IANA name, with the history of its rules, and gives a type for a moment in a zone, `ZonedDateTime`, whose offset follows the zone's rules wherever arithmetic takes it.

## Where Zones Come From

```freebasic
$TZDIR                   when set: a directory of compiled zone files
/usr/share/zoneinfo      Linux and macOS: the files the system installs
std/tzdata               the database inside the program, when it is imported
```

The first source that has an id wins. Windows has no zone files of its own, so a program that names zones there imports **std/tzdata**: about 250 KB holding tzdata 2026f, every zone and link. On Linux and macOS the system's files come first because the operating system keeps them current, and std/tzdata fills in what they lack -- Ubuntu, for one, does not install the old link names such as `US/Eastern`. "UTC" needs no database at all.

`TimeZone.DataVersion` says which release the program is reading, and `tzdata.Version` which one std/tzdata holds.

## Ids

An id is a name like `Europe/Paris`, `America/Argentina/Buenos_Aires` or `Etc/GMT+5`: letters, digits, `_`, `+` and `-` in segments joined by `/`. It is checked before any file is touched -- no `.`, no empty segment, no leading `/` -- so an id from user input cannot reach another file. It is matched without regard to case and comes back spelled as the database spells it. A link keeps the name asked for: `US/Eastern` is `US/Eastern`, with New York's rules.

`TimeZone.Local` is the machine's own zone, answered by the operating system so that it always agrees with `chrono.TimeZoneInfo`. Its id is the machine's IANA id where one can be found -- from `TZ` or `/etc/localtime` on Linux and macOS, and on Windows from the zone's Windows name through the Unicode CLDR table -- and "" otherwise.

## The Types

```freebasic
TimeZone        a zone: its offset, daylight flag, abbreviation and changes at any instant
ZonedDateTime   an instant in a zone: a moment plus the rules that give its reading
TzRules         one zone's rules read from a zone file or a POSIX TZ string, in Unix seconds
```

Offsets in std/tz are in **seconds**, not chrono's minutes: before standard time, local mean time had offsets like Amsterdam's +00:19:32.

## TimeZone

```freebasic
TimeZone.FindById( id )  .TryFindById( id, z )  .Utc  .FixedOffset( seconds )  .Local
TimeZone.AvailableIds  .DataVersion  .RegisterDatabase( p, n )
.IsValid  .Id  .IsFixed
.OffsetSecondsAt( i )  .OffsetAt( i )  .StandardOffsetAt( i )
.IsDaylightSavingTime( i )  .AbbreviationAt( i )
.TryNextTransition( i, t )  .TryPreviousTransition( i, t )
.MapLocal( wall, a, b )  .TryResolve( wall, policy, i )  .Resolve( wall, policy )
```

A **transition** is a change of offset. The Local zone has no table of them, so its transitions are found by scanning ten years a day at a time.

### Readings that happen twice, or never

When the clocks go back, an hour of readings happens twice; when they go forward, an hour never happens. `MapLocal` counts the moments a reading names -- 1, 2 or 0 -- and a **Disambiguation** policy picks one:

```freebasic
                 happened twice     never happened
dzCompatible     the earlier        moved forward by the gap    (the default)
dzEarlier        the earlier        moved back by the gap
dzLater          the later          moved forward by the gap
dzReject         refused            refused
```

## ZonedDateTime

```freebasic
ZonedDateTime.FromInstant( i, z )  .FromLocal( wall, z, policy )  .TryFromLocal( ... )  .Now( z )  .Invalid
.IsValid  .Zone  .OffsetSeconds  .Offset  .IsDaylightSavingTime  .Abbreviation
.Year .Month .Day .Hour .Minute .Second .Millisecond .DayOfWeek .DayOfYear
.ToInstant  .ToDateTime  .ToWall  .GetDate  .GetTimeOfDay
.WithZoneSameInstant( z )  .WithZoneSameLocal( z, policy )
.Add( span )  .Subtract( span )  .AddCalendarDays( n )  .AddCalendarMonths( n )  .AddCalendarYears( n )
.StartOfDay  .CompareTo( o )  =  <>  <  >  <=  >=
.ToIsoString  .ToString( pattern )  .TryFormat( pattern, s )
ZonedDateTime.TryParseIso( s, z, offsets, policy )  .ParseIso  .TryParseExact( s, pattern, z, ... )  .ParseExact
```

THE INSTANT IS WHAT IT IS; the wall-clock reading is worked out from the zone. So two values can show the same reading -- the earlier and the later 01:30 of a night the clocks go back -- and be an hour apart.

TWO KINDS OF ARITHMETIC, named apart: `Add( span )` is elapsed time, whatever the clocks do; `AddCalendarDays( n )` keeps the wall-clock reading, so "the same time tomorrow" is 23 or 25 hours away twice a year. A calendar step that lands on a repeated reading keeps the offset it had; one that lands on a skipped reading moves forward.

TWO WAYS TO CHANGE ZONE: `WithZoneSameInstant` converts (same moment, new reading); `WithZoneSameLocal` reinterprets (same reading, new moment).

`StartOfDay` is the first moment of the date, which is not always midnight: where the clocks went forward at midnight, the day began at 01:00.

`ToDateTime` gives a chrono `DateTime`, whose offset holds whole minutes: a historical offset with seconds is rounded and the moment kept.

### Text

```freebasic
2025-07-04T12:00:00-04:00[America/New_York]     ToIsoString
2025-07-04T12:00:00+00:00[UTC]                  UTC: an offset, not Z
1930-01-15T12:19:32+00:19:32[Europe/Amsterdam]  seconds only when there are some
```

`TryParseIso` needs the zone in brackets. Before it, an offset -- `Z`, `+05`, `+0530`, `+05:30`, or with seconds -- or none; a date alone means the start of that day. When the text's offset is not the zone's for that reading, an **OffsetPolicy** decides: `opReject` (the default) refuses it, `opUse` keeps the moment the offset names, `opPrefer` uses the offset where the zone allows it, and `opIgnore` reads the wall-clock time in the zone. A `Z` always names the moment.

In patterns, `VV` is the zone id and `v` its abbreviation; the other letters are std/chrono's. `TryParseExact` reads a pattern that ends in `VV`. An abbreviation cannot be read back: `CST` names three different zones.

## TzRules

```freebasic
TzRules.TryParse( bytes, r )  .TryParsePosix( "EST5EDT,M3.2.0,M11.1.0", r )
.IsValid  .Version  .TransitionCount  .PosixRule
.OffsetSecondsAt( t )  .StandardOffsetSecondsAt( t )  .IsDstAt( t )  .AbbreviationAt( t )
.TryNextTransition( t, r )  .TryPreviousTransition( t, r )
TZ_MIN_UNIX  TZ_MAX_UNIX
```

The engine under `TimeZone`: one zone's rules from the bytes of a compiled zone file -- versions 1 to 4, "fat" or "slim" -- or from a POSIX TZ string, with every time in Unix seconds. The bytes are treated as untrusted: a malformed file is `false`, never a crash, and files that count leap seconds are refused. Most programs never need it directly.

## std/tzdata

```freebasic
#import "std/tzdata"     ' nothing to call: the database is registered when the program starts
tzdata.Version( )        ' 2026f
```

## The Rules That Are Easy To Get Wrong

```freebasic
storing "EST" or "CST"           an abbreviation is not a zone: store the id (VV)
AddDays( 1 ) for "tomorrow"      elapsed time; AddCalendarDays( 1 ) keeps the clock
a reading in the night clocks    may name two moments or none: pass a policy, or
change                           use TryFromLocal with dzReject
Local on Windows, no std/tzdata  named zones, and Local's id, need the database
"Z" in text with a zone          names the moment; the zone gives its reading
```

## What Is NOT Here

LEAP SECONDS. Zone files that count them are refused.

LOCALIZED ZONE NAMES ("heure normale d'Europe centrale"). Abbreviations are the database's, the same everywhere.

READING AN ABBREVIATION BACK into a zone. One abbreviation names several zones.

## Implementation

```freebasic
pkg/std/tz/          tz.tiko (TzRules), tzif.tiko (zone files), tzposix.tiko (POSIX TZ),
                     tzzone.tiko (TimeZone), tzzonemap.tiko (local to instant),
                     tzzoned.tiko and tzzonedtext.tiko (ZonedDateTime), tzwindows.tiko
                     and tzwinmap.tiko (Windows zone names)
pkg/std/tzdata/      the database and the module that registers it
tools/tzdb/          build.sh and pack.py rebuild the database; windowszones.py the
                     Windows name table
```

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Dates and times](Functions-Dates) lists them beside the rest of the area.

### Get the current date and time

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.Now](Modern-Tz-ZonedDateTime-Now) | Returns the current moment as it reads in a time zone. | `std/tz` |

### Make a date, a time or a date-time

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.FromInstant](Modern-Tz-ZonedDateTime-FromInstant) | Returns a moment as it reads in a time zone. | `std/tz` |
| [ZonedDateTime.FromLocal](Modern-Tz-ZonedDateTime-FromLocal) | Returns a wall-clock reading in a zone; a policy settles a repeated or skipped one. | `std/tz` |
| [ZonedDateTime.TryFromLocal](Modern-Tz-ZonedDateTime-TryFromLocal) | Makes a wall-clock reading in a time zone, returning false when the policy refuses it. | `std/tz` |

### Read the year, month, day and time

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.Year](Modern-Tz-ZonedDateTime-Year) | Returns the year of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.Month](Modern-Tz-ZonedDateTime-Month) | Returns the month, 1 to 12 of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.Day](Modern-Tz-ZonedDateTime-Day) | Returns the day of the month of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.Hour](Modern-Tz-ZonedDateTime-Hour) | Returns the hour, 0 to 23 of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.Minute](Modern-Tz-ZonedDateTime-Minute) | Returns the minute of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.Second](Modern-Tz-ZonedDateTime-Second) | Returns the second of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.Millisecond](Modern-Tz-ZonedDateTime-Millisecond) | Returns the millisecond of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.DayOfWeek](Modern-Tz-ZonedDateTime-DayOfWeek) | Returns the weekday, 1 = Monday to 7 = Sunday of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.DayOfYear](Modern-Tz-ZonedDateTime-DayOfYear) | Returns the day of the year, 1 to 366 of the wall-clock reading in the zone. | `std/tz` |
| [ZonedDateTime.GetDate](Modern-Tz-ZonedDateTime-GetDate) | Returns the date of the wall-clock reading. | `std/tz` |
| [ZonedDateTime.GetTimeOfDay](Modern-Tz-ZonedDateTime-GetTimeOfDay) | Returns the time of day of the wall-clock reading. | `std/tz` |

### Add days, months and years

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.Add](Modern-Tz-ZonedDateTime-Add) | Adds elapsed time, whatever the clocks do meanwhile. | `std/tz` |
| [ZonedDateTime.Subtract](Modern-Tz-ZonedDateTime-Subtract) | Subtracts elapsed time, whatever the clocks do meanwhile. | `std/tz` |
| [ZonedDateTime.AddCalendarDays](Modern-Tz-ZonedDateTime-AddCalendarDays) | Returns the same wall-clock time a number of days later, across any change of offset. | `std/tz` |
| [ZonedDateTime.AddCalendarMonths](Modern-Tz-ZonedDateTime-AddCalendarMonths) | Returns the same wall-clock time some months later, clamping the day to the month's end. | `std/tz` |
| [ZonedDateTime.AddCalendarYears](Modern-Tz-ZonedDateTime-AddCalendarYears) | Returns the same wall-clock time some years later, clamping 29 February to the 28th. | `std/tz` |

### Compare dates and count the days between

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.CompareTo](Modern-Tz-ZonedDateTime-CompareTo) | Compares two values by the moment they name: -1, 0 or 1. | `std/tz` |

### Turn dates and durations into text

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.ToIsoString](Modern-Tz-ZonedDateTime-ToIsoString) | Writes the value as ISO 8601 text with the zone in brackets, which reads back exactly. | `std/tz` |
| [ZonedDateTime.ToString](Modern-Tz-ZonedDateTime-ToString) | Writes the value as ISO 8601 text, or through a pattern with VV for the zone id. | `std/tz` |
| [ZonedDateTime.TryFormat](Modern-Tz-ZonedDateTime-TryFormat) | Formats the value through a pattern, returning false for a bad pattern. | `std/tz` |

### Read dates and durations from text

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.TryParseIso](Modern-Tz-ZonedDateTime-TryParseIso) | Reads ISO 8601 text with a [Zone/Id] annotation, returning false if it cannot. | `std/tz` |
| [ZonedDateTime.ParseIso](Modern-Tz-ZonedDateTime-ParseIso) | Reads ISO 8601 text with a [Zone/Id] annotation, or stops with an error. | `std/tz` |
| [ZonedDateTime.TryParseExact](Modern-Tz-ZonedDateTime-TryParseExact) | Reads text in a pattern that ends in VV, returning false if it does not match. | `std/tz` |
| [ZonedDateTime.ParseExact](Modern-Tz-ZonedDateTime-ParseExact) | Reads text in a pattern that ends in VV, or stops with an error. | `std/tz` |
| [OffsetPolicy](Modern-Tz-OffsetPolicy) | Chooses what parsing does when the text's offset and its zone disagree. | `std/tz` |

### Month and weekday names

| Function | What it does | From |
|---|---|---|
| [TimeZone.AbbreviationAt](Modern-Tz-TimeZone-AbbreviationAt) | Returns the zone's abbreviation at a given moment, such as EST or CEST. | `std/tz` |
| [ZonedDateTime.Abbreviation](Modern-Tz-ZonedDateTime-Abbreviation) | Returns the zone's abbreviation at this moment, such as EDT. | `std/tz` |
| [TzRules.AbbreviationAt](Modern-Tz-TzRules-AbbreviationAt) | Returns the zone's abbreviation at a moment given in Unix seconds. | `std/tz` |

### Jump to the start or end of a day, week, month or year

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.StartOfDay](Modern-Tz-ZonedDateTime-StartOfDay) | Returns the first moment of the date in the zone, which is not always midnight. | `std/tz` |

### Work with UTC and time-zone offsets

| Function | What it does | From |
|---|---|---|
| [TimeZone.OffsetSecondsAt](Modern-Tz-TimeZone-OffsetSecondsAt) | Returns the zone's offset from UTC in seconds at a given moment. | `std/tz` |
| [TimeZone.OffsetAt](Modern-Tz-TimeZone-OffsetAt) | Returns the zone's offset from UTC at a given moment as a TimeSpan. | `std/tz` |
| [TimeZone.StandardOffsetAt](Modern-Tz-TimeZone-StandardOffsetAt) | Returns the zone's standard offset at a given moment, leaving daylight time out. | `std/tz` |
| [TimeZone.IsDaylightSavingTime](Modern-Tz-TimeZone-IsDaylightSavingTime) | Returns true if the zone's rules call that moment daylight time. | `std/tz` |
| [ZonedDateTime.OffsetSeconds](Modern-Tz-ZonedDateTime-OffsetSeconds) | Returns the offset from UTC in force at this moment, in seconds. | `std/tz` |
| [ZonedDateTime.Offset](Modern-Tz-ZonedDateTime-Offset) | Returns the offset from UTC in force at this moment as a TimeSpan. | `std/tz` |
| [ZonedDateTime.IsDaylightSavingTime](Modern-Tz-ZonedDateTime-IsDaylightSavingTime) | Returns true if the zone's rules call this moment daylight time. | `std/tz` |
| [TzRules.OffsetSecondsAt](Modern-Tz-TzRules-OffsetSecondsAt) | Returns the offset from UTC in seconds at a moment given in Unix seconds. | `std/tz` |
| [TzRules.StandardOffsetSecondsAt](Modern-Tz-TzRules-StandardOffsetSecondsAt) | Returns the standard offset in seconds at a moment in Unix seconds, leaving DST out. | `std/tz` |
| [TzRules.IsDstAt](Modern-Tz-TzRules-IsDstAt) | Returns true if the rules call a moment, given in Unix seconds, daylight time. | `std/tz` |

### Use named time zones (std/tz)

| Function | What it does | From |
|---|---|---|
| [TimeZone.FindById](Modern-Tz-TimeZone-FindById) | Returns the time zone with an IANA id such as Europe/Paris, or stops with an error. | `std/tz` |
| [TimeZone.TryFindById](Modern-Tz-TimeZone-TryFindById) | Looks up a time zone by IANA id, returning false when there is no such zone. | `std/tz` |
| [TimeZone.Utc](Modern-Tz-TimeZone-Utc) | Returns the UTC time zone, which needs no zone database. | `std/tz` |
| [TimeZone.FixedOffset](Modern-Tz-TimeZone-FixedOffset) | Returns a time zone that is always a fixed number of seconds ahead of UTC. | `std/tz` |
| [TimeZone.Local](Modern-Tz-TimeZone-Local) | Returns the machine's own time zone, answered by the operating system. | `std/tz` |
| [TimeZone.AvailableIds](Modern-Tz-TimeZone-AvailableIds) | Returns every zone id the first zone source holds, sorted. | `std/tz` |
| [TimeZone.DataVersion](Modern-Tz-TimeZone-DataVersion) | Returns the tz database release the first zone source holds, such as 2026f. | `std/tz` |
| [TimeZone.RegisterDatabase](Modern-Tz-TimeZone-RegisterDatabase) | Gives std/tz a zone database to fall back on, in the .tzdb format tools/tzdb makes. | `std/tz` |
| [TimeZone.Id](Modern-Tz-TimeZone-Id) | Returns the zone's id: its IANA name, UTC, or a fixed offset such as +05:30. | `std/tz` |
| [TimeZone.IsFixed](Modern-Tz-TimeZone-IsFixed) | Returns true if the zone is UTC or a fixed offset, with no rules that change. | `std/tz` |
| [TimeZone.TryNextTransition](Modern-Tz-TimeZone-TryNextTransition) | Finds the next moment the zone's offset changes after a given moment. | `std/tz` |
| [TimeZone.TryPreviousTransition](Modern-Tz-TimeZone-TryPreviousTransition) | Finds the last moment before a given moment when the zone's offset changed. | `std/tz` |
| [TimeZone.MapLocal](Modern-Tz-TimeZone-MapLocal) | Counts the moments a wall-clock reading names in the zone: 1, 2 or 0. | `std/tz` |
| [TimeZone.TryResolve](Modern-Tz-TimeZone-TryResolve) | Turns a wall-clock reading in the zone into one moment, under a Disambiguation policy. | `std/tz` |
| [TimeZone.Resolve](Modern-Tz-TimeZone-Resolve) | Returns the moment a wall-clock reading names in the zone, or stops with an error. | `std/tz` |
| [Disambiguation](Modern-Tz-Disambiguation) | Chooses what a wall-clock reading that happened twice, or never, should mean. | `std/tz` |
| [ZonedDateTime.Zone](Modern-Tz-ZonedDateTime-Zone) | Returns the time zone of a ZonedDateTime. | `std/tz` |
| [ZonedDateTime.WithZoneSameInstant](Modern-Tz-ZonedDateTime-WithZoneSameInstant) | Returns the same moment as it reads in another time zone. | `std/tz` |
| [ZonedDateTime.WithZoneSameLocal](Modern-Tz-ZonedDateTime-WithZoneSameLocal) | Returns the same wall-clock reading in another time zone, which is a different moment. | `std/tz` |
| [TzRules.TryParse](Modern-Tz-TzRules-TryParse) | Reads one zone's rules from the bytes of a compiled zone file, or returns false. | `std/tz` |
| [TzRules.TryParsePosix](Modern-Tz-TzRules-TryParsePosix) | Reads one zone's rules from a POSIX TZ string such as EST5EDT,M3.2.0,M11.1.0. | `std/tz` |
| [TzRules.Version](Modern-Tz-TzRules-Version) | Returns the zone file's format version, 1 to 4, or 0 for rules from a POSIX TZ string. | `std/tz` |
| [TzRules.TransitionCount](Modern-Tz-TzRules-TransitionCount) | Returns how many transitions the zone file lists, before its rule for later years. | `std/tz` |
| [TzRules.PosixRule](Modern-Tz-TzRules-PosixRule) | Returns the POSIX TZ rule that covers the years after the file's last transition. | `std/tz` |
| [TzRules.TryNextTransition](Modern-Tz-TzRules-TryNextTransition) | Finds the next change of offset after a moment, in Unix seconds. | `std/tz` |
| [TzRules.TryPreviousTransition](Modern-Tz-TzRules-TryPreviousTransition) | Finds the last change of offset before a moment, in Unix seconds. | `std/tz` |
| [tzdata.Version](Modern-Tz-Tzdata-Version) | Returns the release of the zone database std/tzdata puts in the program, such as 2026f. | `std/tzdata` |

### Convert to Unix time, FILETIME and other numbers

| Function | What it does | From |
|---|---|---|
| [ZonedDateTime.ToInstant](Modern-Tz-ZonedDateTime-ToInstant) | Returns the moment a ZonedDateTime names. | `std/tz` |
| [ZonedDateTime.ToDateTime](Modern-Tz-ZonedDateTime-ToDateTime) | Returns the wall-clock reading with its offset as a chrono DateTime. | `std/tz` |
| [ZonedDateTime.ToWall](Modern-Tz-ZonedDateTime-ToWall) | Returns the wall-clock reading alone, as a DateTime with no offset. | `std/tz` |

### Check a value is valid, and the range limits

| Function | What it does | From |
|---|---|---|
| [TimeZone.IsValid](Modern-Tz-TimeZone-IsValid) | Returns true if the time zone refers to a zone; a dim'd TimeZone does not. | `std/tz` |
| [ZonedDateTime.Invalid](Modern-Tz-ZonedDateTime-Invalid) | Returns an Invalid ZonedDateTime, the value arithmetic gives outside the years 1 to 9999. | `std/tz` |
| [ZonedDateTime.IsValid](Modern-Tz-ZonedDateTime-IsValid) | Returns true unless the ZonedDateTime is Invalid. | `std/tz` |
| [TzRules.IsValid](Modern-Tz-TzRules-IsValid) | Returns true if the rules were read; a dim'd TzRules has none. | `std/tz` |
| [TZ_MIN_UNIX and TZ_MAX_UNIX](Modern-Tz-Constants) | Gives the range std/tz works in, 0001-01-01 to 9999-12-31, in Unix seconds. | `std/tz` |

<!-- finder:end -->
