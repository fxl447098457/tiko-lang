[Home](Home) › [Time Zones](Category-Time-Zones) › [Time Zones (std/tz)](Category-Time-Zones) › **TzRules.TryParse**

# TzRules.TryParse

Reads one zone's rules from the bytes of a compiled zone file, or returns false.

## Syntax

```freebasic
TzRules.TryParse( byval p as const ubyte ptr, byval n as longint, byref result as TzRules ) as boolean
TzRules.TryParse( byref bytes as string, byref result as TzRules ) as boolean
```

## Notes

- The file is what zic writes and Linux and macOS install, version 1 to 4. Both "fat" and "slim" files are read.
- The input is checked as untrusted: a malformed file is false, never a crash. Files that count leap seconds are refused.
- Most programs use [TimeZone](Modern-Tz-TimeZone-FindById), which finds and reads the files itself.

## Examples

```freebasic
#import "std/tz"
#import "std/tzdata"
#import "std/chrono"
using tz
dim as TzRules r
print TzRules.TryParse( "not a zone file", r )      '' false
```

---

**Library:** [Time Zones (std/tz)](Category-Time-Zones)  
**Category:** [Time Zones](Category-Time-Zones)  
**Documented under:** TzRules
