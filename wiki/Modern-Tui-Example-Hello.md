[Home](Home) › [Terminal TUI Library](Category-Terminal-TUI-Library) › [Examples](Category-Terminal-TUI-Library) › **hello.tiko**

# hello.tiko

> **The smallest complete program.** A complete, working program from [Terminal TUI Library](Category-Terminal-TUI-Library).

One centred box, a keypress counter and a clean exit. Ninety lines, and every part of the module's shape is in it: a TuiApp with Init/Update/View, a TuiBlock with titles on two sides, a centred layout that re-centres itself on resize, and the TuiRun result checked before anything is printed.

## Build and run

```freebasic
tiko hello.tiko        ' windows-x86_64 on Windows, linux-x86_64 on Linux, macos-arm64 on macOS
```

Run it from a REAL TERMINAL. Redirected output is rejected with an honest error rather than a dashboard drawn into a pipe. tiko builds it with no diagnostics for windows-x86_64 and win64, and compiles it for linux-x86_64 with `-c` (built, not run: it is interactive).

## What to notice

- `Init` returns `TuiNone( )` -- this application wants no timer.
- `View` builds its widgets as LOCALS. That is correct here because nothing points at them afterwards; a focusable widget could not be a local.
- `TuiCenter` is recomputed every frame, so the box follows a resize with no resize handling beyond returning `TuiRedraw( )`.
- PRINT appears only AFTER `TuiRun` returns. Inside a session it is banned -- on Linux and macOS a stray PRINT can emit CSI 6n and block.

## Source

```freebasic
'' examples/hello.tiko -- the smallest complete TUI program.
''
'' Build (windows-x86_64, linux-x86_64 or macos-arm64):
''     tiko hello.tiko
''
'' Run it from a real terminal. Redirected output is rejected with an honest
'' error rather than a dashboard drawn into a pipe.

#import "std/numeric"
#import "std/tui"
using tui, numeric

'' ---------------------------------------------------------------------------
'' The model. Update mutates it, View reads it, and nothing else touches it.
'' ---------------------------------------------------------------------------
type HelloApp extends TuiApp
	as int32 presses
	as ustring lastKey
	as TuiTheme theme

	declare function Init( ) as TuiCmd override
	declare function Update( byref e as TuiEvent ) as TuiCmd override
	declare sub View( byref f as TuiFrame ) override
end type

function HelloApp.Init( ) as TuiCmd
	presses = 0
	lastKey = "(none yet)"
	theme = TuiThemeDefault( )
	return TuiNone( )
end function

function HelloApp.Update( byref e as TuiEvent ) as TuiCmd
	select case e.kind
	case TUIEVENT_KEY
		'' q or Esc quits. Ctrl+C never arrives as a key -- ISIG is cleared in
		'' raw mode -- so TuiRun handles it, not us.
		if( e.key.code = TUIKEY_ESCAPE ) then return TuiQuit( 0 )
		if( e.key.IsChar( ) andalso ( e.key.ch = asc( "q" ) ) ) then return TuiQuit( 0 )

		presses += 1
		lastKey = TuiKeyName( e.key )
		return TuiRedraw( )

	case TUIEVENT_RESIZE
		'' TuiRun has already resized and invalidated the screen.
		return TuiRedraw( )
	end select

	return TuiNone( )
end function

sub HelloApp.View( byref f as TuiFrame )
	'' one centred box, whatever the terminal size is
	dim as TuiRect box = TuiCenter( f.Area( ), 44, 7 )

	dim as TuiBlock frame_
	frame_.borderKind = TUIBORDER_ROUNDED
	frame_.sides = TUISIDE_ALL
	frame_.borderStyle = theme.border
	frame_.fill = TRUE
	frame_.fillStyle = theme.normal
	frame_.AddTitle( " hello ", theme.title, TUISIDE_TOP, TUIALIGN_CENTER )
	frame_.AddTitle( " q quits ", theme.dim_, TUISIDE_BOTTOM, TUIALIGN_RIGHT )
	frame_.Render( f, box )

	dim as TuiParagraph p
	p.align = TUIALIGN_CENTER
	p.st = theme.normal
	p.wrap = TRUE
	p.text = "keys pressed: " & str( presses ) & chr( 10 ) & _
	         "last: " & lastKey & chr( 10 ) & chr( 10 ) & _
	         "press q or Esc to quit"
	p.Render( f, frame_.Inner( box ) )
end sub

'' ---------------------------------------------------------------------------
dim as TuiTermOptions opts = TuiTermOptionsDefault( )

dim as HelloApp app
dim as TuiRunResult r = TuiRun( app, opts )

'' TuiRun has fully restored the terminal by the time it returns, so ordinary
'' PRINT is safe again HERE and only here. Inside a session it is banned: on
'' Linux and macOS a stray PRINT emits CSI 6n and can block.
if( r.IsOk( ) = false ) then
	print "hello: " & r.Failure( ).Message( )
	end 1
end if
end r.Value( )
```

---

**Library:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Other examples:** [form.tiko](Modern-Tui-Example-Form) · [dashboard.tiko](Modern-Tui-Example-Dashboard)



---

[Home](Home) · [Keyword Index](Keyword-Index)