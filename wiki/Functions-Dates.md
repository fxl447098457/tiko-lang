[Home](Home) › [Function Finder](Function-Finder) › **Dates and times**

# Dates and times

The functions to get the current time, add days and months, parse and print dates, grouped by what you want to do. The **From** column says what a program needs before it can call one:

- **built-in**: nothing; it is always available.
- `std/<Name>`: `#import "std/<Name>"`, then `using <Name>` to call it by its bare name.
- `datetime.bi`: `#include "datetime.bi"`.

Jump to: [Get the current date and time](#get-the-current-date-and-time) · [Time how long something takes](#time-how-long-something-takes) · [Make a date, a time or a date-time](#make-a-date-a-time-or-a-date-time) · [Read the year, month, day and time](#read-the-year-month-day-and-time) · [Add days, months and years](#add-days-months-and-years) · [Compare dates and count the days between](#compare-dates-and-count-the-days-between) · [Turn dates and durations into text](#turn-dates-and-durations-into-text) · [Read dates and durations from text](#read-dates-and-durations-from-text) · [Weekdays, weeks and quarters](#weekdays-weeks-and-quarters) · [Month and weekday names](#month-and-weekday-names) · [Jump to the start or end of a day, week, month or year](#jump-to-the-start-or-end-of-a-day-week-month-or-year) · [Leap years and month lengths](#leap-years-and-month-lengths) · [TimeSpan: make a duration](#timespan-make-a-duration) · [TimeSpan: totals and parts](#timespan-totals-and-parts) · [TimeSpan: arithmetic and comparison](#timespan-arithmetic-and-comparison) · [Work with UTC and time-zone offsets](#work-with-utc-and-time-zone-offsets) · [Use named time zones (std/tz)](#use-named-time-zones-stdtz) · [Show a date the way the user's machine writes it](#show-a-date-the-way-the-users-machine-writes-it) · [Convert to Unix time, FILETIME and other numbers](#convert-to-unix-time-filetime-and-other-numbers) · [Check a value is valid, and the range limits](#check-a-value-is-valid-and-the-range-limits) · [Set the system clock](#set-the-system-clock)

## Get the current date and time

| Function | What it does | From |
|---|---|---|
| [Date](Date) | Returns today's date as text in the form mm-dd-yyyy. | built-in |
| [Time](Time) | Returns the current time as text in the form hh:mm:ss. | built-in |
| [Now](Now) | Returns the current local date and time as a date serial. | `datetime.bi` |
| [WallClock.UtcNow](Modern-Chrono-WallClock-UtcNow) | Returns the current moment on the UTC timeline, read from the system clock. | `std/chrono` |
| [WallClock.Now](Modern-Chrono-WallClock-Now) | Returns the local date and time, with the UTC offset in force at this moment. | `std/chrono` |
| [WallClock.Today](Modern-Chrono-WallClock-Today) | Returns today's local date as a LocalDate. | `std/chrono` |
| [WallClock.TimeOfDay](Modern-Chrono-WallClock-TimeOfDay) | Returns the current local time of day as a LocalTime. | `std/chrono` |
| [WallClock.Resolution](Modern-Chrono-WallClock-Resolution) | Returns the smallest step the wall clock reports, as a TimeSpan. | `std/chrono` |
| [ZonedDateTime.Now](Modern-Tz-ZonedDateTime-Now) | Returns the current moment as it reads in a time zone. | `std/tz` |

## Time how long something takes

| Function | What it does | From |
|---|---|---|
| [Timer](Timer) | Returns the seconds since a fixed starting point, for measuring elapsed time. | built-in |
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

## Make a date, a time or a date-time

| Function | What it does | From |
|---|---|---|
| [DateSerial](Dateserial) | Returns the date serial for a year, month and day; out-of-range values roll over. | `datetime.bi` |
| [TimeSerial](Timeserial) | Returns the fraction of a day for an hour, minute and second, to add to a date serial. | `datetime.bi` |
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
| [ZonedDateTime.FromInstant](Modern-Tz-ZonedDateTime-FromInstant) | Returns a moment as it reads in a time zone. | `std/tz` |
| [ZonedDateTime.FromLocal](Modern-Tz-ZonedDateTime-FromLocal) | Returns a wall-clock reading in a zone; a policy settles a repeated or skipped one. | `std/tz` |
| [ZonedDateTime.TryFromLocal](Modern-Tz-ZonedDateTime-TryFromLocal) | Makes a wall-clock reading in a time zone, returning false when the policy refuses it. | `std/tz` |

## Read the year, month, day and time

| Function | What it does | From |
|---|---|---|
| [Year](Year) | Returns the year of a date serial. | `datetime.bi` |
| [Month](Month) | Returns the month of a date serial, 1 to 12. | `datetime.bi` |
| [Day](Day) | Returns the day of the month of a date serial. | `datetime.bi` |
| [Hour](Hour) | Returns the hour of a date serial, 0 to 23. | `datetime.bi` |
| [Minute](Minute) | Returns the minute of a date serial. | `datetime.bi` |
| [Second](Second) | Returns the second of a date serial. | `datetime.bi` |
| [DatePart](Datepart) | Returns one part of a date serial, such as its year, quarter, week or hour. | `datetime.bi` |
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

## Add days, months and years

| Function | What it does | From |
|---|---|---|
| [DateAdd](Dateadd) | Returns a date serial moved by a number of years, months, days, hours or other units. | `datetime.bi` |
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
| [ZonedDateTime.Add](Modern-Tz-ZonedDateTime-Add) | Adds elapsed time, whatever the clocks do meanwhile. | `std/tz` |
| [ZonedDateTime.Subtract](Modern-Tz-ZonedDateTime-Subtract) | Subtracts elapsed time, whatever the clocks do meanwhile. | `std/tz` |
| [ZonedDateTime.AddCalendarDays](Modern-Tz-ZonedDateTime-AddCalendarDays) | Returns the same wall-clock time a number of days later, across any change of offset. | `std/tz` |
| [ZonedDateTime.AddCalendarMonths](Modern-Tz-ZonedDateTime-AddCalendarMonths) | Returns the same wall-clock time some months later, clamping the day to the month's end. | `std/tz` |
| [ZonedDateTime.AddCalendarYears](Modern-Tz-ZonedDateTime-AddCalendarYears) | Returns the same wall-clock time some years later, clamping 29 February to the 28th. | `std/tz` |

## Compare dates and count the days between

| Function | What it does | From |
|---|---|---|
| [DateDiff](Datediff) | Counts the years, months, days or other units between two date serials. | `datetime.bi` |
| [LocalDate.DayNumber](Modern-Chrono-LocalDate-DayNumber) | Returns the days since 0001-01-01; subtract two to count the days between dates. | `std/chrono` |
| [Instant.CompareTo](Modern-Chrono-Instant-CompareTo) | Returns -1, 0 or 1 to order two moments, or -2 if either is Invalid. | `std/chrono` |
| [LocalDate.CompareTo](Modern-Chrono-LocalDate-CompareTo) | Returns -1, 0 or 1 to order two dates, or -2 if either is Invalid. | `std/chrono` |
| [LocalTime.CompareTo](Modern-Chrono-LocalTime-CompareTo) | Returns -1, 0 or 1 to order two times of day, or -2 if either is Invalid. | `std/chrono` |
| [ZonedDateTime.CompareTo](Modern-Tz-ZonedDateTime-CompareTo) | Compares two values by the moment they name: -1, 0 or 1. | `std/tz` |

## Turn dates and durations into text

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
| [ZonedDateTime.ToIsoString](Modern-Tz-ZonedDateTime-ToIsoString) | Writes the value as ISO 8601 text with the zone in brackets, which reads back exactly. | `std/tz` |
| [ZonedDateTime.ToString](Modern-Tz-ZonedDateTime-ToString) | Writes the value as ISO 8601 text, or through a pattern with VV for the zone id. | `std/tz` |
| [ZonedDateTime.TryFormat](Modern-Tz-ZonedDateTime-TryFormat) | Formats the value through a pattern, returning false for a bad pattern. | `std/tz` |

## Read dates and durations from text

| Function | What it does | From |
|---|---|---|
| [DateValue](Datevalue) | Returns the date serial for text written in the system's date format. | `datetime.bi` |
| [TimeValue](Timevalue) | Returns the date serial of a time written like 23:59:59 or 11:59:59PM. | `datetime.bi` |
| [IsDate](Isdate) | Returns true if the text can be read as a date in the system's date format. | `datetime.bi` |
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
| [ZonedDateTime.TryParseIso](Modern-Tz-ZonedDateTime-TryParseIso) | Reads ISO 8601 text with a [Zone/Id] annotation, returning false if it cannot. | `std/tz` |
| [ZonedDateTime.ParseIso](Modern-Tz-ZonedDateTime-ParseIso) | Reads ISO 8601 text with a [Zone/Id] annotation, or stops with an error. | `std/tz` |
| [ZonedDateTime.TryParseExact](Modern-Tz-ZonedDateTime-TryParseExact) | Reads text in a pattern that ends in VV, returning false if it does not match. | `std/tz` |
| [ZonedDateTime.ParseExact](Modern-Tz-ZonedDateTime-ParseExact) | Reads text in a pattern that ends in VV, or stops with an error. | `std/tz` |
| [OffsetPolicy](Modern-Tz-OffsetPolicy) | Chooses what parsing does when the text's offset and its zone disagree. | `std/tz` |

## Weekdays, weeks and quarters

| Function | What it does | From |
|---|---|---|
| [Weekday](Weekday) | Returns the day of the week, 1 to 7, counting from Sunday unless told otherwise. | `datetime.bi` |
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

## Month and weekday names

| Function | What it does | From |
|---|---|---|
| [MonthName](Monthname) | Returns the name of a month number in the system's language, or its abbreviation. | `datetime.bi` |
| [WeekdayName](Weekdayname) | Returns the name of a weekday number in the system's language, or its abbreviation. | `datetime.bi` |
| [DateTime.MonthName](Modern-Chrono-DateTime-MonthName) | Returns a month's name in the user's language, or its abbreviation. | `std/chrono` |
| [DateTime.WeekdayName](Modern-Chrono-DateTime-WeekdayName) | Returns a weekday's name in the user's language, 1 being Monday, or its abbreviation. | `std/chrono` |
| [TimeZone.AbbreviationAt](Modern-Tz-TimeZone-AbbreviationAt) | Returns the zone's abbreviation at a given moment, such as EST or CEST. | `std/tz` |
| [ZonedDateTime.Abbreviation](Modern-Tz-ZonedDateTime-Abbreviation) | Returns the zone's abbreviation at this moment, such as EDT. | `std/tz` |
| [TzRules.AbbreviationAt](Modern-Tz-TzRules-AbbreviationAt) | Returns the zone's abbreviation at a moment given in Unix seconds. | `std/tz` |

## Jump to the start or end of a day, week, month or year

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
| [ZonedDateTime.StartOfDay](Modern-Tz-ZonedDateTime-StartOfDay) | Returns the first moment of the date in the zone, which is not always midnight. | `std/tz` |

## Leap years and month lengths

| Function | What it does | From |
|---|---|---|
| [DateTime.IsLeapYear](Modern-Chrono-DateTime-IsLeapYear) | Returns true if a year is a leap year under the full Gregorian rule. | `std/chrono` |
| [DateTime.DaysInMonth](Modern-Chrono-DateTime-DaysInMonth) | Returns the number of days in a month of a given year. | `std/chrono` |
| [DateTime.DaysInYear](Modern-Chrono-DateTime-DaysInYear) | Returns 365 or 366, the number of days in a year. | `std/chrono` |
| [DateTime.WeeksInYear](Modern-Chrono-DateTime-WeeksInYear) | Returns 52 or 53, the number of ISO weeks in a year. | `std/chrono` |

## TimeSpan: make a duration

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

## TimeSpan: totals and parts

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

## TimeSpan: arithmetic and comparison

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

## Work with UTC and time-zone offsets

| Function | What it does | From |
|---|---|---|
| [DateTime.WithOffset](Modern-Chrono-DateTime-WithOffset) | Attaches a UTC offset in minutes, keeping the clock reading and changing the moment. | `std/chrono` |
| [DateTime.ToOffset](Modern-Chrono-DateTime-ToOffset) | Converts to another UTC offset, keeping the moment and changing the clock reading. | `std/chrono` |
| [DateTime.OffsetMinutes](Modern-Chrono-DateTime-OffsetMinutes) | Returns the UTC offset in minutes; check HasOffset first, as no offset reads 32767. | `std/chrono` |
| [DateTime.HasOffset](Modern-Chrono-DateTime-HasOffset) | Returns true if the date-time carries a UTC offset. | `std/chrono` |
| [DateTime.IsUtc](Modern-Chrono-DateTime-IsUtc) | Returns true if the offset is zero; a date-time with no offset is not UTC. | `std/chrono` |
| [DateTime.ToInstant](Modern-Chrono-DateTime-ToInstant) | Returns the moment the date-time names, or Invalid if it has no offset. | `std/chrono` |
| [DateTime.AssumeUtc](Modern-Chrono-DateTime-AssumeUtc) | Returns the moment the date-time names if its clock reading is taken as UTC. | `std/chrono` |
| [DateTime.AssumeLocal](Modern-Chrono-DateTime-AssumeLocal) | Returns the moment the date-time names if its clock reading is taken as local time. | `std/chrono` |
| [DateTime.ToLocal](Modern-Chrono-DateTime-ToLocal) | Returns the same moment shown at the machine's local UTC offset. | `std/chrono` |
| [DateTime.FromInstant](Modern-Chrono-DateTime-FromInstant) | Returns the date-time a moment shows on a clock with the given UTC offset. | `std/chrono` |
| [TimeZoneInfo.LocalOffsetAt](Modern-Chrono-TimeZoneInfo-LocalOffsetAt) | Returns the local zone's UTC offset in minutes at a given moment, DST included. | `std/chrono` |
| [TimeZoneInfo.TryLocalOffsetAt](Modern-Chrono-TimeZoneInfo-TryLocalOffsetAt) | Gets the local zone's UTC offset at a given moment, returning false for an Invalid moment. | `std/chrono` |
| [TimeZoneInfo.LocalOffset](Modern-Chrono-TimeZoneInfo-LocalOffset) | Returns the local zone's UTC offset in minutes right now. | `std/chrono` |
| [TimeZoneInfo.IsDaylightSavingTime](Modern-Chrono-TimeZoneInfo-IsDaylightSavingTime) | Returns true if daylight saving time is in force in the local zone at a given moment. | `std/chrono` |
| [TimeZoneInfo.SupportsDaylightSavingTime](Modern-Chrono-TimeZoneInfo-SupportsDaylightSavingTime) | Returns true if the local zone observes daylight saving time at all. | `std/chrono` |
| [TimeZoneInfo.StandardName](Modern-Chrono-TimeZoneInfo-StandardName) | Returns the OS's name for the local zone's standard time. | `std/chrono` |
| [TimeZoneInfo.DaylightName](Modern-Chrono-TimeZoneInfo-DaylightName) | Returns the OS's name for the local zone's daylight saving time. | `std/chrono` |
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

## Use named time zones (std/tz)

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

## Show a date the way the user's machine writes it

| Function | What it does | From |
|---|---|---|
| [DateTime.ToLocaleDateString](Modern-Chrono-DateTime-ToLocaleDateString) | Returns the date as the machine's locale writes it, for display only. | `std/chrono` |
| [DateTime.ToLocaleTimeString](Modern-Chrono-DateTime-ToLocaleTimeString) | Returns the time of day as the machine's locale writes it, for display only. | `std/chrono` |
| [DateTime.ToLocaleString](Modern-Chrono-DateTime-ToLocaleString) | Returns the date and time as the machine's locale writes them, for display only. | `std/chrono` |

## Convert to Unix time, FILETIME and other numbers

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
| [ZonedDateTime.ToInstant](Modern-Tz-ZonedDateTime-ToInstant) | Returns the moment a ZonedDateTime names. | `std/tz` |
| [ZonedDateTime.ToDateTime](Modern-Tz-ZonedDateTime-ToDateTime) | Returns the wall-clock reading with its offset as a chrono DateTime. | `std/tz` |
| [ZonedDateTime.ToWall](Modern-Tz-ZonedDateTime-ToWall) | Returns the wall-clock reading alone, as a DateTime with no offset. | `std/tz` |

## Check a value is valid, and the range limits

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
| [TimeZone.IsValid](Modern-Tz-TimeZone-IsValid) | Returns true if the time zone refers to a zone; a dim'd TimeZone does not. | `std/tz` |
| [ZonedDateTime.Invalid](Modern-Tz-ZonedDateTime-Invalid) | Returns an Invalid ZonedDateTime, the value arithmetic gives outside the years 1 to 9999. | `std/tz` |
| [ZonedDateTime.IsValid](Modern-Tz-ZonedDateTime-IsValid) | Returns true unless the ZonedDateTime is Invalid. | `std/tz` |
| [TzRules.IsValid](Modern-Tz-TzRules-IsValid) | Returns true if the rules were read; a dim'd TzRules has none. | `std/tz` |
| [TZ_MIN_UNIX and TZ_MAX_UNIX](Modern-Tz-Constants) | Gives the range std/tz works in, 0001-01-01 to 9999-12-31, in Unix seconds. | `std/tz` |

## Set the system clock

| Function | What it does | From |
|---|---|---|
| [SetDate](Setdate) | Sets the system date from text like mm-dd-yyyy; needs admin rights, 0 means success. | built-in |
| [SetTime](Settime) | Sets the system time from text like hh:mm:ss; needs admin rights, 0 means success. | built-in |

## See Also

- [Date and Time (Chrono) guide](Category-Date-and-Time-Chrono)
- [Time Zones guide](Category-Time-Zones)
- [Date and Time Functions](Category-Date-and-Time-Functions)
- [Date and time functions overview](Date-and-Time-Functions)

---

[Home](Home) · [Function Finder](Function-Finder) · [Keyword Index](Keyword-Index)

<!-- Generated by tools/wikifinder/finder.py. Edit the data, not this page. -->
