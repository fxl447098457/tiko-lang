[Home](Home) › [Math Library](Category-Math-Library) › [Math Library](Category-Math-Library) › **CurrentLocaleFormat**

# CurrentLocaleFormat

Returns a NumFormat holding this machine's decimal and thousands separators.

## Syntax

```freebasic
CurrentLocaleFormat( ) as NumFormat
```

## Notes

- Fills a `NumFormat` from the OS: `decimalSep` and `groupSep`, from the user's Region settings on Windows and from `LC_ALL` / `LC_NUMERIC` / `LANG` on Linux and macOS. A separator the OS does not supply keeps its default.
- Grouping stays off; set `grouping = true` to use `groupSep`.
- The process locale is not changed, so `ToString` and `str` are unaffected.
- **Its result depends on the machine**, so it must not be written to a file or asserted on -- it is for presenting a number to the person at the keyboard.
- `ToString` is the locale-independent one, and is what round-trips.

## Examples

```freebasic
#import "std/numeric"
using numeric

dim f as NumFormat = CurrentLocaleFormat( )

'' Machine-dependent, so this asserts shape rather than content
print len( f.decimalSep ) > 0                 '' -1 (true)
print len( f.groupSep ) > 0                   '' -1 (true)

'' ToString is the one that does NOT vary, and round-trips
print ToString( 1.5 )        '' 1.5
```

---

**Library:** [Math Library](Category-Math-Library)  
**Category:** [Math Library](Category-Math-Library)  
**Documented under:** Members
