# Offsets and time zones

A wall-clock reading such as 09:00 names a moment only once you know whose
clock it was read on. A `DateTime` carries that as an **offset** from UTC in
minutes, and an `Instant` is the moment itself.

```tiko
{{#include ../../examples/time/offsets.tiko}}
```

**Output**

```text
{{#include ../../examples/time/offsets.out}}
```

A `DateTime` is in one of three states: UTC (printed with `Z`), an offset
(`-05:00` is five hours behind UTC), or unspecified, where `HasOffset` is
false. An unspecified reading cannot become an `Instant` without a guess, so
`ToInstant( )` gives Invalid; `AssumeUtc( )` makes the guess and makes it
visible in the code.

Two methods put an offset on a `DateTime`, and they do different things:

| Call | Keeps | Changes |
|---|---|---|
| `WithOffset( m )` | the wall-clock reading | the moment it names |
| `ToOffset( m )` | the moment | the wall-clock reading |

```admonish danger title="Pitfall"
**`WithOffset` where `ToOffset` was meant** compiles, runs, and moves every
timestamp by the difference between the two offsets. To show a moment on
another clock, the call is `ToOffset`.
```

The machine's own zone comes from the operating system.
`TimeZoneInfo.LocalOffsetAt( instant )` is its offset **at that instant**, since
January and July can differ; `DateTime.FromInstant( instant, offset )` gives the
local reading. The example prints only facts that hold in every zone, because
the offset itself depends on where the program runs. For any other zone, by
its name, see [Named time zones](zones.md).

### Activities

1. Print the moment `2025-06-01T12:00:00Z` as it reads in Tokyo (+09:00).
2. Print `TimeZoneInfo.LocalOffsetAt` for a January and a July instant on your
   machine, and compare them.
