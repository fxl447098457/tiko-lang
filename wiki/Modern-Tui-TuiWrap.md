[Home](Home) › [Terminal TUI Library](Category-Terminal-TUI-Library) › [Unicode Width](Category-Terminal-TUI-Library) › **TuiWrap**

# TuiWrap

Breaks text into lines that fit a number of columns, keeping its line breaks.

## Syntax

```freebasic
TuiWrap( byref s as ustring, byval cols as int32 ) as TuiStringArray
```

## Description

Word-wraps to a column width, returning the lines. Embedded chr(10) starts a new line. This is what TuiParagraph uses, which is why paragraph wrapping is correct for CJK.

## Example

```freebasic
#import "std/tui"
using tui

dim as TuiStringArray lines_ = TuiWrap( "the quick brown fox jumps", 10 )
for each ln in lines_
    print "["; ln; "]"
next
'' [the quick ]
'' [brown fox ]
'' [jumps]
''
'' NOTE THE TRAILING SPACE: the break space stays on the line it broke after,
'' so a wrapped line can measure one column wider than you expect. Right-align
'' or box wrapped text and you will see it.

'' a newline is honoured, not swallowed
print TuiWrap( "a" & chr( 10 ) & "b", 40 ).Count( )     '' 2
```

## See also

[TuiCharWidth](Modern-Tui-TuiCharWidth) · [TuiStringWidth](Modern-Tui-TuiStringWidth) · [TuiTruncate](Modern-Tui-TuiTruncate) · [TuiSetAmbiguousWide](Modern-Tui-TuiSetAmbiguousWide) · [TuiAmbiguousWide](Modern-Tui-TuiAmbiguousWide)

---

**Library:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Category:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Documented under:** Unicode Width  
**Working examples:** [hello.tiko](Modern-Tui-Example-Hello) · [form.tiko](Modern-Tui-Example-Form) · [dashboard.tiko](Modern-Tui-Example-Dashboard)


---

[Home](Home) · [Keyword Index](Keyword-Index)