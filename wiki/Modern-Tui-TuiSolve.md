[Home](Home) › [Terminal TUI Library](Category-Terminal-TUI-Library) › [Layout](Category-Terminal-TUI-Library) › **TuiSolve**

# TuiSolve

Returns the sizes that constraints give a total, adding up to exactly that total.

## Syntax

```freebasic
TuiSolve( byval total as int32, byref cs as TuiConstraintArray ) as Array( of int32 )
```

## Description

The raw sizes, if you want to lay something out yourself. The rule is stated exactly so the result is deterministic: fixed constraints first, FILL shares the remainder by weight, odd cells go to the earlier slots, and over-subscription shrinks right to left. The same input always gives the same answer, on both platforms.

## Example

```freebasic
#import "std/containers"
#import "std/tui"
using tui, containers

dim as TuiConstraintArray cs
cs.Push( TuiLength( 3 ) )
cs.Push( TuiFill( ) )
cs.Push( TuiLength( 1 ) )

dim as Array( of int32 ) s = TuiSolve( 24, cs )
print s[0], s[1], s[2]            '' 3 20 1

dim as int32 total_ = 0
for each n in s : total_ += n : next
print total_                      '' 24 -- always exactly the total
```

## See also

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| [TuiConstraint](Modern-Tui-TuiConstraint) | [TuiPercent](Modern-Tui-TuiPercent) | [TuiAtLeast](Modern-Tui-TuiAtLeast) | [TuiFill](Modern-Tui-TuiFill) | [TuiSplitV](Modern-Tui-TuiSplitV) | [TuiPadAll](Modern-Tui-TuiPadAll) |
| [TuiLength](Modern-Tui-TuiLength) | [TuiRatio](Modern-Tui-TuiRatio) | [TuiAtMost](Modern-Tui-TuiAtMost) | [TuiSplitH](Modern-Tui-TuiSplitH) | [TuiPad](Modern-Tui-TuiPad) | [TuiCenter](Modern-Tui-TuiCenter) |

---

**Library:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Category:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Documented under:** Layout  
**Working examples:** [hello.tiko](Modern-Tui-Example-Hello) · [form.tiko](Modern-Tui-Example-Form) · [dashboard.tiko](Modern-Tui-Example-Dashboard)


---

[Home](Home) · [Keyword Index](Keyword-Index)