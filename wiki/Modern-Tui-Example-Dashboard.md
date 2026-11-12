[Home](Home) › [Terminal TUI Library](Category-Terminal-TUI-Library) › [Examples](Category-Terminal-TUI-Library) › **dashboard.tiko**

# dashboard.tiko

> **The btop-style screen, the module's success criterion.** A complete, working program from [Terminal TUI Library](Category-Terminal-TUI-Library).

Two columns, braille history plots, gradient meters per core, a scrolling process table with a scrollbar, a status bar, mouse support and a 250 ms tick. This is the layout the module was measured against; if you read one example, read this one.

## Build and run

```freebasic
tiko dashboard.tiko        ' windows-x86_64 on Windows, linux-x86_64 on Linux, macos-arm64 on macOS
```

Run it from a REAL TERMINAL. Redirected output is rejected with an honest error rather than a dashboard drawn into a pipe. tiko builds it with no diagnostics for windows-x86_64 and win64, and compiles it for linux-x86_64 with `-c` (built, not run: it is interactive).

## What to notice

- `Init` returns `TuiTick( 250 )`. NOTHING ELSE CAN ARM THE FIRST TICK -- TuiTick is one-shot and Update only re-arms it in response to a tick, so without this the graphs never move.
- `opts.mouse = TRUE` is set explicitly. `TuiTermOptionsDefault( )` leaves the mouse OFF, so a program that forgets this line never sees a mouse event.
- The whole layout is nested `TuiSplitH` and `TuiSplitV` calls, recomputed every frame. There is no layout tree and nothing to invalidate.
- `procRect` is remembered by the view for mouse hit-testing -- the one piece of frame-to-frame state an immediate-mode application actually needs.
- The process table's selection is driven by the app's OWN keymap, not the widget's. That is why TuiTable clamps in Render as well as in HandleEvent.

## Source

```freebasic
'' examples/dashboard.tiko -- the success criterion, as a running program.
''
'' The btop-style screen this module was measured against: a two-column layout,
'' braille history plots, gradient meters, a scrolling process table with a
'' scrollbar, and a status bar.
''
'' Build (windows-x86_64, linux-x86_64 or macos-arm64):
''     tiko dashboard.tiko
''
'' Keys: up/down move the process selection, q or Esc quits. The data is
'' synthetic -- this is a layout and rendering demonstration, not a system
'' monitor.

#import "std/numeric"
#import "std/tui"
using tui, numeric

const HISTORY = 240        '' samples kept for the braille plots
const NPROC   = 24

type DashApp extends TuiApp
	as TuiTheme theme
	as TuiDoubleArray cpuHistory, netDown, netUp
	as float64 coreLoad( 0 to 3 )
	as float64 memBar( 0 to 3 )
	as TuiRowArray procs
	as TuiTableState procState
	as TuiRect procRect          '' remembered by ViewProcs, for mouse hit-testing
	as int32 frameNo

	declare function Init( ) as TuiCmd override
	declare function Update( byref e as TuiEvent ) as TuiCmd override
	declare sub View( byref f as TuiFrame ) override

	declare sub Sample( )
	declare sub ViewCpu  ( byref f as TuiFrame, byval a as TuiRect )
	declare sub ViewMem  ( byref f as TuiFrame, byval a as TuiRect )
	declare sub ViewNet  ( byref f as TuiFrame, byval a as TuiRect )
	declare sub ViewProcs( byref f as TuiFrame, byval a as TuiRect )
end type

'' ---------------------------------------------------------------------------
sub DashApp.Sample( )
	frameNo += 1
	dim as float64 t = frameNo / 6.0

	'' one new sample per tick, oldest dropped -- the RIGHTMOST sample is the
	'' newest, which is what TuiGraph draws
	cpuHistory.Push( 48.0 + sin( t ) * 30.0 + sin( t * 2.7 ) * 12.0 )
	netDown.Push( 30.0 + sin( t / 1.7 ) * 22.0 )
	netUp.Push( 12.0 + cos( t / 1.1 ) * 9.0 )
	while( cpuHistory.Count( ) > HISTORY )
		cpuHistory.Remove( 0 )
		netDown.Remove( 0 )
		netUp.Remove( 0 )
	wend

	for i as int32 = 0 to 3
		coreLoad( i ) = 0.20 + ( sin( t + i * 0.8 ) + 1.0 ) * 0.3
	next
	memBar( 0 ) = 0.37 : memBar( 1 ) = 0.63
	memBar( 2 ) = 0.14 + ( sin( t / 3.0 ) + 1.0 ) * 0.05
	memBar( 3 ) = 0.01
end sub

function DashApp.Init( ) as TuiCmd
	theme = TuiThemeDefault( )
	frameNo = 0
	procState.selected = 0
	procState.offset = 0

	for i as int32 = 0 to HISTORY - 1
		cpuHistory.Push( 50.0 )
		netDown.Push( 30.0 )
		netUp.Push( 12.0 )
	next

	dim as ustring names_( 0 to 9 ) = { "screencap", "mdworker", "zed", "Google C", _
	                                    "iTerm2", "SiriSugg", "triald_s", "coreauth", _
	                                    "nearbyd", "WhatsApp" }
	for i as int32 = 0 to NPROC - 1
		dim as TuiRow r
		r.cells.Push( str( 25513 - i * 3 ) )
		r.cells.Push( names_( i mod 10 ) )
		r.cells.Push( iif( ( i mod 4 ) = 0, "root", "bobby" ) )
		r.cells.Push( str( 20 + ( i * 7 ) mod 300 ) & "M" )
		r.cells.Push( str( ( i * 13 ) mod 100 / 10.0 ) )
		procs.Push( r )
	next

	Sample( )

	'' ARM THE FIRST TICK. Nothing else can: TuiTick is one-shot and Update
	'' only re-arms it in response to a tick, so without this the graphs never
	'' move.
	return TuiTick( 250 )
end function

function DashApp.Update( byref e as TuiEvent ) as TuiCmd
	select case e.kind
	case TUIEVENT_KEY
		if( e.key.code = TUIKEY_ESCAPE ) then return TuiQuit( 0 )
		if( e.key.IsChar( ) andalso ( e.key.ch = asc( "q" ) ) ) then return TuiQuit( 0 )

		dim as int32 h = 10
		select case e.key.code
		case TUIKEY_UP       : procState.selected -= 1
		case TUIKEY_DOWN     : procState.selected += 1
		case TUIKEY_PAGEUP   : procState.selected -= h
		case TUIKEY_PAGEDOWN : procState.selected += h
		case TUIKEY_HOME     : procState.selected = 0
		case TUIKEY_END     : procState.selected = procs.Count( ) - 1
		case else            : return TuiNone( )
		end select
		if( procState.selected < 0 ) then procState.selected = 0
		if( procState.selected >= procs.Count( ) ) then procState.selected = procs.Count( ) - 1
		return TuiRedraw( )

	case TUIEVENT_TICK
		Sample( )
		'' TuiTick is ONE-SHOT: re-arm it.
		return TuiTick( 250 )

	case TUIEVENT_MOUSE
		'' wheel scrolls the process table, a click selects the row under the
		'' pointer. procRect is remembered by ViewProcs -- the one piece of
		'' frame-to-frame state an app needs for hit-testing.
		select case e.mouse.kind
		case TUIMOUSE_WHEELUP
			procState.selected -= 3
		case TUIMOUSE_WHEELDOWN
			procState.selected += 3
		case TUIMOUSE_PRESS
			if( procRect.Contains( e.mouse.x, e.mouse.y ) ) then
				dim as int32 row = e.mouse.y - procRect.y - 1     '' -1 for the header
				if( row >= 0 ) then procState.selected = procState.offset + row
			end if
		case else
			return TuiNone( )
		end select
		if( procState.selected < 0 ) then procState.selected = 0
		if( procState.selected >= procs.Count( ) ) then procState.selected = procs.Count( ) - 1
		return TuiRedraw( )

	case TUIEVENT_RESIZE
		return TuiRedraw( )
	end select

	return TuiNone( )
end function

'' ---------------------------------------------------------------------------
'' Layout: nested splits, recomputed every frame. There is no layout tree and
'' nothing to invalidate.
'' ---------------------------------------------------------------------------
sub DashApp.View( byref f as TuiFrame )
	dim as TuiConstraintArray outer
	outer.Push( TuiFill( ) )
	outer.Push( TuiLength( 1 ) )
	dim as TuiRectArray band = TuiSplitV( f.Area( ), outer )

	dim as TuiConstraintArray cols
	cols.Push( TuiPercent( 45 ) )
	cols.Push( TuiFill( ) )
	dim as TuiRectArray col = TuiSplitH( band[0], cols )

	dim as TuiConstraintArray leftRows
	leftRows.Push( TuiPercent( 40 ) )
	leftRows.Push( TuiFill( ) )
	leftRows.Push( TuiLength( 9 ) )
	dim as TuiRectArray lhs = TuiSplitV( col[0], leftRows )

	ViewCpu( f, lhs[0] )
	ViewMem( f, lhs[1] )
	ViewNet( f, lhs[2] )
	ViewProcs( f, col[1] )

	'' status bar: hints left, a counter hard against the right edge
	dim as TuiStatusBar sb
	sb.background = theme.dim_
	sb.Add( " up/dn select ", theme.normal, TUIALIGN_LEFT )
	sb.Add( " home/end ", theme.normal, TUIALIGN_LEFT )
	sb.Add( " click/wheel ", theme.normal, TUIALIGN_LEFT )
	sb.Add( " q quit ", theme.danger, TUIALIGN_LEFT )
	sb.Add( str( procState.selected + 1 ) & "/" & str( procs.Count( ) ) & " ", _
	        theme.accent, TUIALIGN_RIGHT )
	sb.Render( f, band[1] )
end sub

'' CPU: a braille history plot, plus one segmented gradient meter per core.
sub DashApp.ViewCpu( byref f as TuiFrame, byval a as TuiRect )
	dim as TuiBlock blk
	blk.borderKind = TUIBORDER_ROUNDED
	blk.sides = TUISIDE_ALL
	blk.borderStyle = theme.border

	'' Several titles on ONE border, independently aligned: hotkey and controls
	'' left, a clock right.
	blk.AddTitle( "1cpu", theme.accent, TUISIDE_TOP, TUIALIGN_LEFT )
	blk.AddTitle( "menu", theme.dim_, TUISIDE_TOP, TUIALIGN_LEFT )
	blk.AddTitle( "preset", theme.dim_, TUISIDE_TOP, TUIALIGN_LEFT )
	blk.AddTitle( str( frameNo ) & "f", theme.normal, TUISIDE_TOP, TUIALIGN_RIGHT )
	blk.Render( f, a )

	dim as TuiRect inner = blk.Inner( a )
	if( inner.IsEmpty( ) ) then exit sub

	dim as TuiConstraintArray cs
	cs.Push( TuiFill( 2 ) )
	cs.Push( TuiPercent( 40 ) )
	dim as TuiRectArray part = TuiSplitH( inner, cs )

	dim as TuiGraph g
	g.graphKind = TUIGRAPH_BRAILLE
	g.autoScale = FALSE
	g.minY = 0.0
	g.maxY = 100.0
	dim as TuiSeries s
	s.data = cpuHistory
	s.color = theme.accent.fg
	g.series.Push( s )
	g.Render( f, part[0] )

	for i as int32 = 0 to 3
		if( i >= part[1].h ) then exit for
		dim as TuiConstraintArray rc
		rc.Push( TuiLength( 3 ) )
		rc.Push( TuiFill( ) )
		rc.Push( TuiLength( 5 ) )
		dim as TuiRectArray cell = TuiSplitH( _
			TuiRectOf( part[1].x, part[1].y + i, part[1].w, 1 ), rc )

		dim as TuiParagraph lbl
		lbl.text = "C" & str( i )
		lbl.st = theme.dim_
		lbl.Render( f, cell[0] )

		'' The gradient runs along the bar's FULL length, so a given position
		'' keeps its colour as the value moves.
		dim as TuiMeter m
		m.ratio = coreLoad( i )
		m.from_ = TuiRgb( 80, 220, 120 )
		m.to_ = TuiRgb( 235, 80, 80 )
		m.trackColor = TuiRgb( 60, 60, 60 )
		m.meterStyle = TUIMETER_SEGMENTED
		m.segmentEvery = 3
		m.partialCells = TRUE
		m.Render( f, cell[1] )

		dim as TuiParagraph pct
		pct.text = str( int( coreLoad( i ) * 100 ) ) & "%"
		pct.align = TUIALIGN_RIGHT
		pct.st = theme.normal
		pct.Render( f, cell[2] )
	next
end sub

'' Memory: hatched meters.
sub DashApp.ViewMem( byref f as TuiFrame, byval a as TuiRect )
	dim as TuiBlock blk
	blk.borderKind = TUIBORDER_ROUNDED
	blk.sides = TUISIDE_ALL
	blk.borderStyle = theme.border
	blk.AddTitle( "2mem", theme.accent, TUISIDE_TOP, TUIALIGN_LEFT )
	blk.AddTitle( "disks", theme.dim_, TUISIDE_TOP, TUIALIGN_RIGHT )
	blk.Render( f, a )

	dim as TuiRect inner = blk.Inner( a )
	if( inner.IsEmpty( ) ) then exit sub

	dim as ustring labels( 0 to 3 ) = { "Used ", "Avail", "Cache", "Free " }
	for i as int32 = 0 to 3
		if( i * 2 >= inner.h ) then exit for
		dim as TuiConstraintArray rc
		rc.Push( TuiLength( 6 ) )
		rc.Push( TuiFill( ) )
		dim as TuiRectArray cell = TuiSplitH( _
			TuiRectOf( inner.x, inner.y + i * 2, inner.w, 1 ), rc )

		dim as TuiParagraph lbl
		lbl.text = labels( i )
		lbl.st = theme.dim_
		lbl.Render( f, cell[0] )

		dim as TuiMeter m
		m.ratio = memBar( i )
		m.from_ = TuiRgb( 220, 70, 70 )
		m.to_ = TuiRgb( 220, 70, 70 )
		m.trackColor = TuiRgb( 50, 50, 50 )
		m.meterStyle = TUIMETER_HATCHED
		m.partialCells = TRUE
		m.Render( f, cell[1] )
	next
end sub

'' Network: two braille series on one axis.
sub DashApp.ViewNet( byref f as TuiFrame, byval a as TuiRect )
	dim as TuiBlock blk
	blk.borderKind = TUIBORDER_ROUNDED
	blk.sides = TUISIDE_ALL
	blk.borderStyle = theme.border
	blk.AddTitle( "3net", theme.accent, TUISIDE_TOP, TUIALIGN_LEFT )
	blk.AddTitle( "en1", theme.dim_, TUISIDE_TOP, TUIALIGN_RIGHT )
	blk.Render( f, a )

	dim as TuiRect inner = blk.Inner( a )
	if( inner.IsEmpty( ) ) then exit sub

	dim as TuiGraph g
	g.graphKind = TUIGRAPH_BRAILLE
	g.autoScale = TRUE

	dim as TuiSeries dn
	dn.data = netDown
	dn.color = TuiRgb( 90, 160, 255 )
	g.series.Push( dn )

	dim as TuiSeries up
	up.data = netUp
	up.color = TuiRgb( 255, 160, 90 )
	g.series.Push( up )

	g.Render( f, inner )
end sub

'' The process table: solver-driven columns, a selected row, and a scrollbar.
sub DashApp.ViewProcs( byref f as TuiFrame, byval a as TuiRect )
	dim as TuiBlock blk
	blk.borderKind = TUIBORDER_ROUNDED
	blk.sides = TUISIDE_ALL
	blk.borderStyle = theme.borderFocused
	blk.AddTitle( "4proc", theme.accent, TUISIDE_TOP, TUIALIGN_LEFT )
	blk.AddTitle( "filter", theme.dim_, TUISIDE_TOP, TUIALIGN_LEFT )
	blk.AddTitle( "tree", theme.dim_, TUISIDE_TOP, TUIALIGN_RIGHT )
	blk.Render( f, a )

	dim as TuiRect inner = blk.Inner( a )
	if( inner.IsEmpty( ) ) then exit sub

	dim as TuiConstraintArray cs
	cs.Push( TuiFill( ) )
	cs.Push( TuiLength( 1 ) )
	dim as TuiRectArray part = TuiSplitH( inner, cs )
	procRect = part[0]

	dim as TuiTable t
	t.showHeader = TRUE
	t.headerStyle = theme.accent
	t.rowStyle = theme.normal
	t.selectedStyle = theme.selected
	t.state = @procState          '' caller-owned; the table never deletes it
	t.headers.Push( "Pid" )
	t.headers.Push( "Program" )
	t.headers.Push( "User" )
	t.headers.Push( "Mem" )
	t.headers.Push( "Cpu%" )
	t.widths.Push( TuiLength( 7 ) )
	t.widths.Push( TuiFill( ) )
	t.widths.Push( TuiLength( 7 ) )
	t.widths.Push( TuiLength( 6 ) )
	t.widths.Push( TuiLength( 6 ) )
	t.rows = procs
	t.Render( f, part[0] )

	dim as TuiScrollbar sc
	sc.vertical = TRUE
	sc.total = procs.Count( )
	sc.visible = part[0].h - 1
	sc.position = procState.offset
	sc.thumb = theme.accent
	sc.track = theme.dim_
	sc.Render( f, part[1] )
end sub

'' ---------------------------------------------------------------------------
dim as TuiTermOptions opts = TuiTermOptionsDefault( )
opts.mouse = TRUE

dim as DashApp app
dim as TuiRunResult r = TuiRun( app, opts )
if( r.IsOk( ) = false ) then
	print "dashboard: " & r.Failure( ).Message( )
	end 1
end if
```

---

**Library:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Other examples:** [hello.tiko](Modern-Tui-Example-Hello) · [form.tiko](Modern-Tui-Example-Form)



---

[Home](Home) · [Keyword Index](Keyword-Index)