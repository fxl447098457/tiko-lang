[Home](Home) › [Terminal TUI Library](Category-Terminal-TUI-Library) › [Terminal](Category-Terminal-TUI-Library) › **TuiWin32InputMode**

# TuiWin32InputMode

Returns the Windows console input mode that Enter would set for given options.

## Syntax

```freebasic
TuiWin32InputMode( byval current as DWORD, byval opts as TuiTermOptions ) as DWORD
```

## Description

Windows only. The console input mode Enter will install, as a pure function of the mode it found and the options asked for -- so it can be asserted without a console. It exists because of a defect: QuickEdit is on by default in most Windows consoles and CONSUMES EVERY MOUSE EVENT for text selection, and clearing ENABLE_QUICK_EDIT_MODE is silently ignored unless ENABLE_EXTENDED_FLAGS is set in the same call. The mouse never worked at all until this was found.

## Example

```freebasic
#import "std/tui"
using tui

#ifdef TIKO_OS_WINDOWS
    dim as DWORD found = ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or _
                         ENABLE_PROCESSED_INPUT or ENABLE_QUICK_EDIT_MODE

    dim as TuiTermOptions o = TuiTermOptionsDefault( )
    o.mouse = TRUE
    dim as DWORD m = TuiWin32InputMode( found, o )

    print ( m and ENABLE_MOUSE_INPUT ) <> 0 '' -1 (true)
    print ( m and ENABLE_EXTENDED_FLAGS ) <> 0 '' -1 (true)  -- or the next line
    print ( m and ENABLE_QUICK_EDIT_MODE ) = 0 '' -1 (true)  -- is ignored
    print ( m and ENABLE_LINE_INPUT ) = 0 '' -1 (true)  -- raw

    '' QuickEdit is the USER'S setting: without mouse it is left alone
    o.mouse = FALSE
    print ( TuiWin32InputMode( found, o ) and ENABLE_QUICK_EDIT_MODE ) <> 0
#endif
```

## See also

|   |   |   |   |
|---|---|---|---|
| [TuiTerminal](Modern-Tui-TuiTerminal) | [TuiTerminal.IsActive](Modern-Tui-TuiTerminal-IsActive) | [TuiTerminal.DetectCaps](Modern-Tui-TuiTerminal-DetectCaps) | [TuiTerminal.Flush](Modern-Tui-TuiTerminal-Flush) |
| [TuiTerminal.Enter](Modern-Tui-TuiTerminal-Enter) | [TuiTerminal.Size](Modern-Tui-TuiTerminal-Size) | [TuiTerminal.Write](Modern-Tui-TuiTerminal-Write) | [TuiTerminal.Discard](Modern-Tui-TuiTerminal-Discard) |
| [TuiTerminal.Leave](Modern-Tui-TuiTerminal-Leave) | [TuiTerminal.Caps](Modern-Tui-TuiTerminal-Caps) | [TuiTerminal.WriteText](Modern-Tui-TuiTerminal-WriteText) | [TuiTerminal.Pending](Modern-Tui-TuiTerminal-Pending) |

---

**Library:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Category:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Documented under:** Terminal  
**Working examples:** [hello.tiko](Modern-Tui-Example-Hello) · [form.tiko](Modern-Tui-Example-Form) · [dashboard.tiko](Modern-Tui-Example-Dashboard)


---

[Home](Home) · [Keyword Index](Keyword-Index)