[Home](Home) › [Terminal TUI Library](Category-Terminal-TUI-Library) › [Application Loop](Category-Terminal-TUI-Library) › **TuiRun**

# TuiRun

Runs your app full-screen and restores the terminal; returns the exit code or an error.

## Syntax

```freebasic
TuiRun( byref app as TuiApp, byval opts as TuiTermOptions ) as TuiRunResult
TuiRun( byref app as TuiApp, byval opts as TuiTermOptions, byval runOpts as TuiRunOptions ) as TuiRunResult
```

## Description

Enters the terminal, runs the loop, and restores everything on the way out -- including after a crash or a signal. It returns the application's exit code, or the TuiError that stopped it STARTING, so a program whose stdout is a pipe gets an honest message instead of a dashboard drawn into a file.

## Example

```freebasic
#import "std/tui"
using tui

dim as CounterApp app             '' see TuiApp for its definition
dim as TuiRunResult r = TuiRun( app, TuiTermOptionsDefault( ) )

'' PRINT is safe HERE and only here: TuiRun has fully restored the terminal
'' by the time it returns. Inside a session it is banned -- on Linux and macOS a stray
'' PRINT can emit CSI 6n and block.
if( r.IsOk( ) = false ) then
    print "myapp: " & r.Failure( ).Message( )
    end 1
end if
end r.Value( )
```

## See also

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| [TuiApp](Modern-Tui-TuiApp) | [TuiApp.Update](Modern-Tui-TuiApp-Update) | [TuiApp.Shutdown](Modern-Tui-TuiApp-Shutdown) | [TuiNone](Modern-Tui-TuiNone) | [TuiQuit](Modern-Tui-TuiQuit) | [TuiInvalidate](Modern-Tui-TuiInvalidate) |
| [TuiApp.Init](Modern-Tui-TuiApp-Init) | [TuiApp.View](Modern-Tui-TuiApp-View) | [TuiCmd](Modern-Tui-TuiCmd) | [TuiRedraw](Modern-Tui-TuiRedraw) | [TuiTick](Modern-Tui-TuiTick) | [TuiSuspend](Modern-Tui-TuiSuspend) |

---

**Library:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Category:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Documented under:** Application Loop  
**Working examples:** [hello.tiko](Modern-Tui-Example-Hello) · [form.tiko](Modern-Tui-Example-Form) · [dashboard.tiko](Modern-Tui-Example-Dashboard)


---

[Home](Home) · [Keyword Index](Keyword-Index)