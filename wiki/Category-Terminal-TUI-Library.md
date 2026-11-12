[Home](Home) › [All Categories](Categories) › **Terminal TUI Library**

# Terminal TUI Library

A **TUI** -- a *text user interface* -- is a program with a real screen layout that runs inside a terminal window. Instead of printing one line after another and scrolling away, it takes over the whole window and draws boxes, menus, lists, progress bars and charts out of text characters and colours, and it redraws them as things change. You drive it with the keyboard, and often the mouse. Familiar examples are `htop` and `btop` for system monitoring, the Midnight Commander file manager, and the installers and setup screens of many tools.

A TUI sits between a plain command-line program, which only prints text, and a graphical application with windows and buttons. It needs nothing but a terminal, so it works over a remote SSH connection and on a machine with no desktop at all.

std/tui is tiko's library for building one. You describe what the screen should look like, and the module works out what to draw, reads the keyboard and mouse, and puts the terminal back the way it found it when your program ends.

> 📘 **Working examples:** [hello.tiko](Modern-Tui-Example-Hello) · [form.tiko](Modern-Tui-Example-Form) · [dashboard.tiko](Modern-Tui-Example-Dashboard) — complete programs.

```freebasic
#import "std/numeric"
#import "std/tui"
using tui, numeric

type HelloApp extends TuiApp
    as int32 presses
    declare function Init( ) as TuiCmd override
    declare function Update( byref e as TuiEvent ) as TuiCmd override
    declare sub View( byref f as TuiFrame ) override
end type

function HelloApp.Init( ) as TuiCmd
    presses = 0
    return TuiNone( )
end function

function HelloApp.Update( byref e as TuiEvent ) as TuiCmd
    if( e.kind = TUIEVENT_KEY ) then
        if( e.key.code = TUIKEY_ESCAPE ) then return TuiQuit( 0 )
        presses += 1
        return TuiRedraw( )
    end if
    return TuiNone( )
end function

sub HelloApp.View( byref f as TuiFrame )
    dim as TuiBlock b
    b.borderKind = TUIBORDER_ROUNDED
    b.sides = TUISIDE_ALL
    b.AddTitle( " hello ", TuiStyleDefault( ), TUISIDE_TOP, TUIALIGN_CENTER )
    b.Render( f, f.Area( ) )

    dim as TuiParagraph p
    p.align = TUIALIGN_CENTER
    p.text = "keys pressed: " & str( presses )
    p.Render( f, b.Inner( f.Area( ) ) )
end sub

dim as HelloApp app
dim as TuiRunResult r = TuiRun( app, TuiTermOptionsDefault( ) )
```

The module is a library and nothing else: every line of it is tiko, with no compiler change and no runtime C. It drives the terminal by declaring the Win32 and libc entry points it needs. It runs on all of tiko's targets: windows-x86_64, linux-x86_64 and macos-arm64.

## What You Get

- **A cell grid that is double-buffered and diffed**, so an unchanged frame costs zero bytes and a changed one costs only what changed.
- **24-bit colour with an automatic downgrade ladder** -- truecolour, 256, ANSI-16 or mono, chosen from what the terminal actually reports.
- **Real key events**: named keys, Ctrl/Alt/Shift modifiers, function keys, and a VT parser that does not confuse Esc with the start of a sequence.
- **A mouse, on every platform**, including the wheel.
- **Resize as an event** rather than a poll.
- **Correct column widths** for CJK, combining marks and zero-width characters, from a generated Unicode 17.0.0 East Asian Width table.
- **A constraint layout solver** -- Length, Percent, Ratio, Min, Max, Fill -- that splits a rectangle deterministically.
- **Thirty-odd widgets**: blocks, paragraphs, lists, tables, tabs, gauges, text inputs, checkboxes, radio groups, selects, popups, menus, trees, braille line graphs, sparklines, bar charts and gradient meters.
- **An application loop** in the Elm/Bubbletea shape: Init, Update, View.
- **A terminal that is always restored**, including after a crash or a signal.

And one thing you do not get, which is worth knowing before you start: there is no retained widget tree. Widgets are values you rebuild every frame. See [The Immediate-Mode Bargain](#the-immediate-mode-bargain) below -- it is the single idea the rest follows from.

## The Three Examples

Working programs, not sketches:

| Program | What it shows |
| --- | --- |
| [hello.tiko](Modern-Tui-Example-Hello) | the smallest complete program -- one box, a keypress counter, a clean exit |
| [form.tiko](Modern-Tui-Example-Form) | focus traversal across text inputs, a checkbox, a radio group and a select, with a confirm dialog on submit |
| [dashboard.tiko](Modern-Tui-Example-Dashboard) | a btop-style screen: braille history plots, gradient meters, a scrolling process table with a scrollbar, a status bar, mouse support and a 250 ms tick |

Save one and build it:

```text
tiko hello.tiko
```

With a packaged toolchain no `-i` and no `-p` are needed: the modules and the runtime are in it. Run the program from a **real terminal** -- redirected output is rejected with an honest error rather than a dashboard drawn into a pipe.

Read dashboard.tiko if you read only one. Everything on this page appears in it.

## The Immediate-Mode Bargain

There is no widget tree, no layout invalidation and no dirty-flag propagation. Every frame you describe the whole screen from your own state; the module diffs that description against the last one and writes only the difference.

```freebasic
sub MyApp.View( byref f as TuiFrame )
    dim as TuiParagraph p          '' a LOCAL. Built and thrown away.
    p.text = "hits: " & str( hits )
    p.Render( f, f.Area( ) )
end sub
```

What you gain: a frame is a pure function of your state, so it is reproducible, testable without a terminal, and impossible to leave stale.

What it costs, and the rule that follows from it: **widgets that hold focus or editing state must outlive the frame.** A TuiParagraph can be a local because nothing points at it afterwards. A TuiTextInput cannot: the focus ring holds a TuiWidget PTR, and a local dies at END SUB. Make focusable widgets **fields of your app** -- a form written with its inputs as locals cannot Tab to any of them.

```freebasic
type FormApp extends TuiApp
    as TuiTextInput   nameBox      '' FIELDS -- they live as long as the app
    as TuiCheckbox    agree
    as TuiFocusRing   ring

    as TuiTextInputState nameState    '' state is caller-owned; see below
end type
```

Widget **state** structs (TuiTextInputState, TuiListState, TuiTableState, TuiSelectState, TuiTreeState, TuiTextAreaState) are always owned by you and pointed at by the widget. The widget never allocates or frees them. That is what lets a widget be a throwaway value while the scroll position survives.

## The Application Loop

Three methods. Update never draws; View never mutates. That separation is the only rule, and it is what makes a frame reproducible from state.

```freebasic
type TuiApp extends Object
    declare abstract function Init( ) as TuiCmd
    declare abstract function Update( byref e as TuiEvent ) as TuiCmd
    declare abstract sub View( byref f as TuiFrame )
    declare virtual sub Shutdown( )
    declare virtual destructor( )
end type

declare function TuiRun( byref app as TuiApp, _
                         byval opts as TuiTermOptions ) as TuiRunResult
```

TuiRunResult is `Result( of long, TuiError )`. It carries the application's exit code, or the error that stopped it from **starting** -- a program whose stdout is a pipe gets TUIERR_NOTATTY here and can print an honest message.

```freebasic
dim as TuiRunResult r = TuiRun( app, TuiTermOptionsDefault( ) )
if( r.IsOk( ) = false ) then
    print "myapp: " & r.Failure( ).Message( )     '' safe: TuiRun has
    end 1                                         '' already restored
end if
end r.Value( )
```

**Init returns a command, and it has to.** TuiTick is one-shot -- Update re-arms it in response to the tick it fired -- so the first tick can only come from Init, which is the only thing that runs before the first poll. An Init that returns `TuiNone( )` simply schedules nothing.

```freebasic
function DashApp.Init( ) as TuiCmd
    LoadEverything( )
    return TuiTick( 250 )        '' start animating
end function

function DashApp.Update( byref e as TuiEvent ) as TuiCmd
    if( e.kind = TUIEVENT_TICK ) then
        Sample( )
        return TuiTick( 250 )    '' RE-ARM. One-shot, remember.
    end if
    return TuiNone( )
end function
```

The loop, in order: poll for an event with a budget; drain every further pending event without rendering; deliver a due tick; render once if anything changed and the frame deadline has passed.

**Draining matters.** A held arrow key or a mouse drag delivers faster than the frame rate. The loop applies every pending event and renders once, so the frame reflects the latest state rather than lagging behind a queue it can never catch up with.

**Nothing dirty, nothing drawn.** An idle TUI blocks in the poll and uses no CPU.

## Commands

```text
TuiNone( )              do nothing
TuiRedraw( )            mark dirty; the next frame is rendered
TuiQuit( code )         leave the loop, return code (default 0)
TuiTick( ms )           deliver one TUIEVENT_TICK after ms. ONE-SHOT.
                        A negative delay clamps to 0.
TuiInvalidate( )        force a FULL repaint, not a diff
TuiSuspend( )           leave the terminal, raise SIGTSTP, come back
```

TuiCmd is a plain value -- `.kind` and `.arg` -- so an app can build one and pass it around before returning it.

TuiRunOptions tunes the loop:

```freebasic
dim as TuiRunOptions ro = TuiRunOptionsDefault( )
ro.fps = 30                  '' default 60
ro.quitOnCtrlC = FALSE       '' default TRUE
TuiRun( app, opts, ro )
```

`quitOnCtrlC` exists because raw mode clears ISIG: Ctrl+C never arrives as a signal, and never arrives as a key either unless the loop synthesises it.

## Running Without a Terminal

```freebasic
declare function TuiRenderOnce( byref app as TuiApp, _
                                byref scr as TuiScreen ) as string
```

One Init/View cycle against a screen with no terminal at all, returning the bytes the renderer would have written. This is how the module's own suites test applications, and how the benchmark measures frame cost:

```freebasic
dim as MyApp app
dim as TuiScreen scr
scr.Resize( 80, 24 )
app.Init( )

dim as string frame1 = TuiRenderOnce( app, scr )    '' non-empty
dim as string frame2 = TuiRenderOnce( app, scr )    '' EMPTY -- nothing
                                                   '' changed
```

Render the same state twice and the second frame is zero bytes. That is the diff's whole bargain, and it is worth asserting in your own tests.

## Terminal: Enter, Leave, Restore

TuiRun does all of this for you. Use TuiTerminal directly only when you are writing your own loop.

```freebasic
dim as TuiTerminal term
dim as TuiUnitResult er = term.Enter( TuiTermOptionsDefault( ) )
if( er.IsOk( ) = false ) then ...
defer term.Leave( )              '' AT PROCEDURE SCOPE. See below.

term.Write( someBytes )
term.Flush( )
```

TuiTermOptions, all boolean. TuiTermOptionsDefault turns on the first four:

```text
altScreen          ON   switch to the alternate screen, so the user's
                        scrollback survives
rawMode            ON   no line buffering, no echo, no signal keys
hideCursor         ON   hide the hardware cursor
bracketedPaste     ON   a paste arrives as one event, not N keystrokes
mouse              OFF  report mouse press, release, motion and wheel
focusEvents        OFF  report terminal focus in/out
```

**The mouse is opt-in, and this catches people.** A program that never asks will never receive a mouse event however much else is right:

```freebasic
dim as TuiTermOptions opts = TuiTermOptionsDefault( )
opts.mouse = TRUE                '' dashboard.tiko does exactly this
TuiRun( app, opts )
```

Mouse and focus events are off by default because a program that does not use them should not be making the terminal send them.

**The defer goes at procedure scope.** tiko's `defer` fires at the end of the enclosing block, so a `defer` written inside the IF that checked Enter would restore the terminal before your loop ran.

The module also installs a last-resort restore -- SetConsoleCtrlHandler on Windows, a signal handler on Linux and macOS -- so a crash or a Ctrl+Break does not leave the user's shell in raw mode with the cursor hidden. The leave sequence is pre-rendered into a fixed async-signal-safe buffer for exactly that path.

**Do not PRINT inside a session.** On Linux and macOS a stray PRINT can emit CSI 6n and block. Ordinary PRINT is safe only after TuiRun returns, which it does with the terminal fully restored.

**Capabilities** are detected once, from TERM, COLORTERM, WT_SESSION, the Windows build number and GetConsoleMode:

```text
dim as TuiCaps c = term.Caps( )
c.isTerminal        false when stdout is a pipe -- Enter fails in that case
c.depth             TUIDEPTH_MONO / _ANSI16 / _256 / _TRUECOLOR
c.mouse
c.bracketedPaste
c.focusEvents
c.unicode           false means fall back to ASCII borders and glyphs
```

TuiTerminal members: Enter, Leave, IsActive, Size, Caps, DetectCaps, Write, WriteText, Flush, Discard, Pending, TakeResize.

**On Windows, two console settings are not optional**, and the module handles both for you:

- **`SetConsoleOutputCP( 65001 )`.** Render( ) emits UTF-8 and Flush( ) sends it with WriteFile, which the console decodes in its *output* code page -- 437 or 1252 by default. Without this every non-ASCII glyph is mojibake, one cell per UTF-8 byte.
- **ENABLE_QUICK_EDIT_MODE cleared, ENABLE_EXTENDED_FLAGS set.** QuickEdit is on by default in most Windows consoles and consumes every mouse event for text selection, and clearing it is silently ignored unless EXTENDED_FLAGS is set in the same call. QuickEdit is the user's setting, so it is only cleared when you asked for the mouse, and Leave restores the whole saved mode word.

## Geometry

```text
TuiRect     x, y, w, h        the only rectangle
TuiPos      x, y
TuiSize     cols, rows
TuiMargin   left, top, right, bottom

TuiRectOf( x, y, w, h )
TuiSizeOf( cols, rows )
TuiMarginOf( l, t, r, b )
TuiMarginAll( n )

r.Right( )                  x + w
r.Bottom( )                 y + h
r.IsEmpty( )                w <= 0 or h <= 0
r.Contains( px, py )
r.Intersect( other )        the overlap, possibly empty
r.Inner( margin )           shrunk by a margin, never negative
r.Equals( other )
```

Everything is **0-based**. VT coordinates are 1-based, and the conversion happens in exactly one place, inside the renderer, where you never see it.

## Colour and Style

TuiColor is a tagged value of four bytes:

```text
TuiDefaultColor( )              "whatever the terminal's default is"
TuiAnsi( TUIC_BRIGHTBLUE )      one of the 16
TuiIndexed( 214 )               the 256-colour cube
TuiRgb( 235, 80, 80 )           24-bit

TuiBlack( ) TuiRed( ) TuiGreen( ) TuiYellow( ) TuiBlue( ) TuiMagenta( )
TuiCyan( ) TuiWhite( ) and the eight TuiBright*( ) forms

c.IsDefault( )  c.Equals( o )  c.Index( )
```

**The downgrade ladder runs at write time**, not at build time. You always write the colour you mean; the renderer reduces it to what the terminal can show:

```text
TUIDEPTH_TRUECOLOR    exact
TUIDEPTH_256          TuiRgbTo256 -- the 6x6x6 cube plus the grey ramp
TUIDEPTH_ANSI16       TuiRgbTo16
TUIDEPTH_MONO         luminance threshold, via TuiLuminance
```

TuiStyle is fg, bg, attrs and a **mask**:

```freebasic
dim as TuiStyle s = TuiStyleOf( TuiRgb( 200, 200, 200 ), _
                                TuiRgb( 20, 20, 30 ), _
                                TUIATTR_BOLD )
TuiStyleDefault( )

s.HasAttr( TUIATTR_UNDERLINE )
s.Equals( o )
s.Patch( over )         '' compose: `over` supplies only what it SETS
```

**Patch is the one to understand.** Assigning a style replaces it, so drawing with a style whose bg is default erases whatever was filled underneath. Patch merges using the mask, so a style that sets only fg leaves the background alone -- a focused text input drawn with an assigned secondary style punches a black hole through its own focus fill.

```freebasic
dim as TuiStyle hl = base.Patch( accent )    '' accent's fg over base's bg
```

Attributes are bitflags: TUIATTR_BOLD, _DIM, _ITALIC, _UNDERLINE, _BLINK, _REVERSE, _STRIKE, _HIDDEN.

TuiTheme is twelve named styles -- normal, dim_, accent, selected, disabled, border, borderFocused, title, success, warning, danger, info. There is no ambient theme singleton; you hold a theme and pass it where it is needed.

```freebasic
dim as TuiTheme th = TuiThemeDefault( )      '' colour
dim as TuiTheme mo = TuiThemeMono( )         '' attributes only
```

## The Buffer and the Frame

TuiScreen owns two buffers and the diff between them. TuiFrame is what View draws into.

```freebasic
scr.Resize( cols, rows )
dim as TuiFrame ptr f = scr.BeginFrame( )
'' ... draw ...
dim as string bytes = scr.Render( TUIDEPTH_TRUECOLOR )
scr.Invalidate( )                '' next Render is a full repaint
```

**Drawing on a frame cannot fail.** Everything is clipped; out-of-clip writes are dropped silently. There is no Result on any drawing call, which is why widget code reads the way it does.

```text
f.Area( )                                  the whole buffer
f.Clip( )                                  the current clip rect
f.SetCell( x, y, ch, st )
f.DrawText( x, y, s, st )                  returns COLUMNS advanced
f.FillRect( r, ch, st )
f.BlendStyle( r, over )                    Patch every cell in r
f.PushClip( r ) / f.PopClip( saved )
f.PushLayer( r ) / f.PopLayer( )           overlays: popups draw here
f.SetCursor( x, y ) / f.HideCursor( )
f.CursorVisible( ) / f.CursorPos( )
```

**A wide glyph occupies two cells**: the base cell carries the character with width 2 and the next cell is a continuation. The diff knows about this and never splits a pair.

DrawText returning columns rather than characters is deliberate -- it is what you add to x to place the next thing.

## Unicode Width

```text
TuiCharWidth( cp )              0, 1 or 2 columns for one codepoint
TuiStringWidth( s )             columns for a whole ustring
TuiTruncate( s, maxCols, ell )  cut to fit. THE ELLIPSIS DEFAULTS TO "..."
                                and counts toward maxCols -- pass "" for a
                                hard cut
TuiWrap( s, cols )              TuiStringArray of wrapped lines. The break
                                space stays on the line it broke after, so
                                a wrapped line can measure one column wider
                                than you expect
```

The table is generated from the Unicode 17.0.0 UCD: 123 wide ranges, 378 zero-width, 179 ambiguous. Wide and Fullwidth characters measure 2; Mn, Me and Cf measure 0.

**Ambiguous width is narrow by default**, which is right for Western terminals and wrong for a CJK locale. There is one global switch, and it is global on purpose -- a per-call parameter would be threaded through every widget:

```freebasic
TuiSetAmbiguousWide( TRUE )
TuiAmbiguousWide( )
```

**What this does not do**, stated plainly because the failure is silent: there is no UAX-29 grapheme clustering. An emoji ZWJ sequence measures as the sum of its parts, so a family emoji is over-measured and will overrun a box. A regional-indicator flag pair measures 2, which happens to be correct. Combining marks attach correctly; everything else that needs full clustering does not.

## Layout

A constraint solver over one rectangle, split horizontally or vertically. No CSS, no flexbox, no parser.

```freebasic
TuiLength( n )          '' exactly n cells
TuiPercent( n )         '' n% of the total
TuiRatio( num, den )
TuiAtLeast( n )            '' at least n
TuiAtMost( n )            '' at most n
TuiFill( weight )       '' share what is left, by weight (default 1)

dim as TuiConstraintArray cs
cs.Push( TuiLength( 3 ) )
cs.Push( TuiFill( ) )
cs.Push( TuiLength( 1 ) )
dim as TuiRectArray band = TuiSplitV( f.Area( ), cs )
'' band[0] header, band[1] body, band[2] status bar

TuiSplitH( area, cs )       '' side by side
TuiSplitV( area, cs )       '' stacked
TuiSolve( total, cs )       '' the raw sizes, if you want them yourself
```

Nest freely -- splitting a result again is how dashboard.tiko builds its two-column screen with three stacked panels on the left.

```text
TuiPad( r, margin )         shrink by a margin
TuiPadAll( r, n )           shrink by n on every side
TuiCenter( outer, w, h )    a w-by-h rect centred in outer
TuiAlignIn( outer, w, a )   left / centre / right within outer
```

**The remainder rule** is stated exactly so the result is deterministic: fixed constraints are satisfied first, Fill shares what is left by weight, and any odd cell left over by integer division goes to the earlier slots. Over-subscription shrinks right to left. The same constraints on the same width always give the same answer, on both platforms.

## Events

```text
TuiEvent
    .kind       TUIEVENT_KEY / _MOUSE / _RESIZE / _PASTE / _FOCUS / _TICK
    .key        TuiKey
    .mouse      TuiMouse
    .size       TuiSize, for RESIZE
    .text       ustring, for PASTE
    .focused    boolean, for FOCUS

TuiKey
    .code       TUIKEY_CHAR, or a named key
    .ch         the codepoint, when code = TUIKEY_CHAR
    .mods       TUIMOD_SHIFT / _ALT / _CTRL, bitwise
    .IsChar( )
    .HasMod( m )

TuiMouse
    .kind       TUIMOUSE_PRESS / _RELEASE / _MOVE / _WHEELUP / _WHEELDOWN
    .button     TUIBTN_LEFT / _MIDDLE / _RIGHT / _NONE
    .x, .y      0-based cell coordinates
    .mods
```

Named keys: ENTER, TAB, BACKSPACE, ESCAPE, UP, DOWN, LEFT, RIGHT, HOME, END, PAGEUP, PAGEDOWN, INSERT, DELETE, F1..F12.

```text
TuiKeyName( k )         "Ctrl+Shift+F5", for display and for logs
```

The usual keyboard shape:

```freebasic
function MyApp.Update( byref e as TuiEvent ) as TuiCmd
    select case e.kind
    case TUIEVENT_KEY
        if( e.key.code = TUIKEY_ESCAPE ) then return TuiQuit( 0 )
        if( e.key.IsChar( ) andalso ( e.key.ch = asc( "q" ) ) ) then
            return TuiQuit( 0 )
        end if
        ...
    case TUIEVENT_MOUSE
        select case e.mouse.kind
        case TUIMOUSE_WHEELDOWN : sel += 3
        case TUIMOUSE_PRESS
            if( bodyRect.Contains( e.mouse.x, e.mouse.y ) ) then ...
        end select
    case TUIEVENT_RESIZE
        return TuiRedraw( )      '' the loop has already resized the screen
    end select
    return TuiNone( )
end function
```

TuiInput is the parser, if you drive your own loop: Feed, NextEvent, PushEvent, Reset, Buffered, Queued, WaitingOnLoneEsc.

**Esc is ambiguous, and always will be.** A lone Esc and the start of a CSI sequence begin with the same byte, so the parser waits briefly before deciding. That is what WaitingOnLoneEsc reports, and why an Esc keypress is marginally slower than any other.

## Widgets

Every widget derives from the abstract TuiWidget, so a container can hold a mixed `Array( of TuiWidget ptr )`:

```freebasic
type TuiWidget extends Object
    declare abstract sub Render( byref f as TuiFrame, byval area as TuiRect )
    declare abstract function Kind( ) as ustring
    declare virtual function HandleEvent( byref e as TuiEvent ) as boolean
    declare virtual function SizeHint( byval avail as TuiRect ) as TuiSize
    declare virtual function CanFocus( ) as boolean
    declare virtual sub SetFocused( byval on_ as boolean )
    declare virtual destructor( )
end type
```

HandleEvent returns TRUE when it **consumed** the event. A container offers the event to its focused child first and only acts if the child declined.

**Focus** is a ring you build and drive:

```freebasic
ring.Add( @nameBox )
ring.Add( @agree )
ring.Next_( )                   '' Tab
ring.Prev( )                    '' Shift+Tab
ring.Focus( @agree )
ring.Current( )                 '' Optional( of TuiWidget ptr )
ring.Count( ) / ring.Clear( )
```

The ring calls SetFocused for you; it never owns or frees anything. **The ring holds pointers**, so everything you Add must outlive the frame.

## The Core Catalogue

### TuiBlock

A border with titles, and the Inner( ) rect inside it.

```freebasic
dim as TuiBlock b
b.borderKind = TUIBORDER_ROUNDED     '' NONE PLAIN ROUNDED DOUBLE THICK ASCII
b.sides = TUISIDE_ALL                '' or TOP or LEFT, bitwise
b.borderStyle = th.border
b.fill = TRUE : b.fillStyle = th.normal
b.AddTitle( " cpu ", th.accent, TUISIDE_TOP, TUIALIGN_LEFT )
b.AddTitle( " 12f ", th.dim_, TUISIDE_TOP, TUIALIGN_RIGHT )
'' NOTE THE ORDER: side, THEN align. A three-argument call sets the SIDE,
'' and passing an alignment there is accepted in silence.
b.Render( f, area )
dim as TuiRect inner = b.Inner( area )
```

Several titles on one border, each independently aligned. That is how the btop-style header row is built.

### TuiParagraph

Text, wrapped or not, aligned, scrollable.

```freebasic
p.text = "..." : p.wrap = TRUE : p.align = TUIALIGN_CENTER : p.scrollY = 0
```

An embedded `chr( 10 )` starts a new line. Wrapping is by TuiWrap, so it is width-correct for CJK.

### TuiList

A selection list with its own scroll.

```freebasic
dim as TuiListState st            '' YOURS. The list only points at it.
lst.items.Push( "one" ) : lst.items.Push( "two" )
lst.state = @st
lst.selectPrefix = "> "
lst.wrapSelection = TRUE
lst.Render( f, area )
```

Keys: Up, Down, PageUp, PageDown, Home, End. `st.selected = -1` means nothing is selected.

### TuiTable

Columns sized by the same constraints as the layout solver.

```freebasic
t.headers.Push( "Pid" ) : t.widths.Push( TuiLength( 7 ) )
t.headers.Push( "Program" ) : t.widths.Push( TuiFill( ) )
dim as TuiRow r : r.cells.Push( "25513" ) : r.cells.Push( "zed" )
t.rows.Push( r )
t.state = @tableState
t.showHeader = TRUE
```

### TuiTabs, TuiGauge, TuiSpinner, TuiScrollbar

These round out the set:

```freebasic
gauge.ratio = 0.42 : gauge.showLabel = TRUE
spinner.Advance( )                       '' call it on a tick
sc.total = 240 : sc.visible = 20 : sc.position = st.offset
```

**List, table and tree all clamp in Render**, not only in HandleEvent, so an application that owns its own keymap and sets `.selected` directly cannot walk the selection off the bottom of the window.

## Input Widgets

```text
TuiTextInput     one line, cursor, selection, password mode
TuiTextArea      many lines, optional gutter
TuiCheckbox
TuiRadioGroup    horizontal or vertical
TuiSelect        a dropdown that opens over whatever is beneath it
```

```freebasic
dim as TuiTextInputState st
TuiTextInputStateInit( st )          '' a SUB: it initialises in place
st.text = "initial text"

box.state = @st
box.placeholder = "your name"
box.normal = th.normal
box.focused_ = th.selected           '' MAKE THESE DIFFERENT, or focus is
box.Render( f, area )                '' invisible

print st.text                        '' read the value straight out
```

**Every form widget points at your storage**, and the shape varies by what it holds. TuiTextInput, TuiTextArea and TuiSelect take a `.state` pointer; TuiCheckbox takes a `boolean ptr checked` and TuiRadioGroup an `int32 ptr selected`, because their whole state is one value:

```freebasic
dim as boolean agreed
dim as int32 choice

chk.label = "I agree" : chk.checked = @agreed
rg.options.Push( "one" ) : rg.options.Push( "two" )
rg.selected = @choice
```

Editing keys: Left/Right, Ctrl+Left/Right by word, Home/End, Backspace, Delete, Shift+arrows to select, and typing replaces a selection. Cursor positions are **code units**; scroll is **columns**.

```text
TuiTextInput.SelectionStart / SelectionEnd / DeleteSelection / Insert
TuiSelect.IsOpen
TuiTextAreaStateInit( state )       also a sub, also in place. It leaves
                                    ONE EMPTY LINE: a text area with no
                                    lines has nowhere to put the cursor
```

**Secondary styles compose; they do not replace.** Placeholder, selection, the active radio option and the selected message-box button are all drawn with `base.Patch( ... )` so the widget's own background survives. If you write a new widget, follow that.

## Overlays and Chrome

```text
TuiPopup         a floating block, optionally modal, optionally dimming
TuiMessageBox    title, message, buttons, an INFO/WARNING/ERROR/QUESTION
                 kind, and Accepted( ) / Cancelled( )
TuiMenuBar       menus with drop-downs
TuiStatusBar     items aligned left or right along one row
TuiTree          collapsible nodes with depth, guides and its own scroll
```

```freebasic
dim as TuiMessageBox mb
mb.title = "Confirm" : mb.message = "Submit the form?"
mb.buttons.Push( "Yes" ) : mb.buttons.Push( "No" )
mb.msgKind = TUIMSG_QUESTION
mb.theme = th
mb.Render( f, f.Area( ) )
if( mb.Accepted( ) ) then ...

sb.Add( " q quit ", th.danger, TUIALIGN_LEFT )
sb.Add( "3/24 ", th.accent, TUIALIGN_RIGHT )      '' hard against the edge

tree.Add( "src", 0, TRUE, 1 )        '' label, depth, hasChildren, userId
tree.Add( "main.tiko", 1, FALSE, 2 )
tree.state = @treeState
```

**A popup draws outside its area on purpose** -- that is what an overlay is. It pushes a layer, and the layer is what makes the cells beneath it restorable when the popup closes. The same is true of an open TuiSelect dropdown.

## Charts

TuiCanvas is a braille sub-cell surface: each terminal cell holds a 2x4 dot grid, so a 40x10 cell area is an 80x40 dot canvas.

```freebasic
dim as TuiCanvas cv = TuiCanvas( 40, 10 )        '' CELLS
cv.Dot( 12, 7, TuiRgb( 120, 220, 160 ) )
cv.Line_( 0, 0, 79, 39, TuiRgb( 200, 80, 80 ) )
cv.Blit( f, area )

cv.DotWidth( ) / DotHeight( ) / CellCols( ) / CellRows( ) / Pattern( cx, cy )
```

The braille block uses the **historical dot order**, which is not raster order -- U+2800 plus a bit set where bit 6 is the bottom-left dot, not the fourth in reading order. Pattern( ) exposes the byte if you want to check it.

```text
TuiGraph        one or more series, braille / block / bar, auto-scaled
TuiSparkline    a single row of block characters
TuiBarChart     labelled bars, horizontal or vertical
TuiMeter        a gradient bar with optional partial-cell precision
```

```freebasic
g.graphKind = TUIGRAPH_BRAILLE
g.autoScale = FALSE : g.minY = 0 : g.maxY = 100
dim as TuiSeries s
for i as int32 = 0 to 199 : s.data.Push( SomeValue( i ) ) : next
s.color = TuiRgb( 120, 220, 160 )
g.series.Push( s )
g.Render( f, area )

m.ratio = 0.62
m.from_ = TuiRgb( 80, 220, 120 ) : m.to_ = TuiRgb( 235, 80, 80 )
m.partialCells = TRUE            '' eighth-block sub-cell precision
m.meterStyle = TUIMETER_SEGMENTED
```

**The rightmost sample is the newest.** A history plot pushes and drops from the front; the graph draws left to right.

## Performance

The module's bench program draws a 200x50 screen -- 10,000 cells, a braille graph and fifty gradient meters -- for sixty frames on windows-x86_64 with default options. It writes 833,656 bytes over the sixty changing frames, none over sixty unchanged ones, and takes about 4.2 ms per changing frame.

## Testing Your Own Application

TuiRenderOnce needs no terminal, so an app's View is directly testable:

```freebasic
dim as MyApp app
dim as TuiScreen scr
scr.Resize( 40, 10 )
app.Init( )
app.someField = 42
dim as string frame = TuiRenderOnce( app, scr )
'' assert against `frame`, or read cells out of scr.Front( )
```

Update is a plain function of an event, so feed it one:

```freebasic
dim as TuiEvent k
k.kind = TUIEVENT_KEY : k.key.code = TUIKEY_DOWN
assert( app.Update( k ).kind = TUICMD_REDRAW )
```

**Believe the screen.** Tests like these assert what the module *produces*; they cannot see what a terminal then does with it, or state carried across calls. A cell-buffer dump cannot catch a wrong output code page, an SGR run leaking into the next frame, or a console that eats mouse events before your process sees them. When something looks wrong on screen and the tests are green, run the program and believe what it shows.

## Errors

Split by layer, deliberately:

| Layer | How it reports |
| --- | --- |
| terminal setup, teardown and I/O | `Result( of T, TuiError )` |
| all drawing | never fails -- out-of-clip writes are dropped |
| lookups, such as `TuiFocusRing.Current` | `Optional( of T )` |

```text
TuiError.code               TUIERR_NONE / _NOTATTY / _RAWMODE / _IO /
                            _UNSUPPORTED / _SIZE
TuiError.detail             what was being attempted
TuiError.Message( )         a formatted line, including the OS error
```

## Files

`#import "std/tui"` imports the module whole. Its files, in pkg/std/tui/:

| File | Holds |
| --- | --- |
| tui.tiko | the umbrella |
| tuicore.tiko | geometry, colour, style, theme |
| tuiterm.tiko | terminal, capabilities, raw mode, restore |
| tuibuffer.tiko | cells, buffer, frame, screen, the diff |
| tuiinput.tiko | events, the VT grammar, PollEvent |
| tuiwidth.tiko | Unicode column widths, truncate, wrap |
| tuiwidthtab.tiko | the generated Unicode width table |
| tuilayout.tiko | the constraint solver |
| tuiwidget.tiko | the widget protocol, focus ring, buttons, stack |
| tuiwidgets.tiko | block, paragraph, list, table, tabs, gauge, spinner, scrollbar |
| tuidraw.tiko | canvas, graph, sparkline, bar chart, meter |
| tuiform.tiko | text input, text area, checkbox, radio, select |
| tuichrome.tiko | popup, message box, menu bar, status bar, tree |
| tuiapp.tiko | the application loop: TuiApp, TuiRun, TuiRenderOnce |

Every name belongs to the module and carries a Tui prefix. `using tui` at the top of your program is the normal thing to do.

## Naming Traps

tiko is case-insensitive and has a large statement vocabulary, so several obvious names are unavailable. These are the ones that bite:

| Name | Why it is unavailable | What the module uses |
| --- | --- | --- |
| `kind` | collides with the abstract `Kind( )` | `borderKind`, `graphKind`, `msgKind`, `meterStyle` |
| `end` | a statement | `TUIKEY_END` |
| `next` | a statement | `TuiFocusRing.Next_` |
| `line` | a statement | `TuiCanvas.Line_` |
| `min`, `max` | intrinsics | `TuiAtLeast`, `TuiAtMost` |
| `dim` | a statement | `dim_` on TuiTheme |
| `error` | an intrinsic | `TUIMSG_ERROR` |
| `focused` | collides in some widgets | `focused_` |
| `from`, `to` | `to` is a keyword | `from_` and `to_` on TuiMeter |
| `open` | a statement | `open_` on TuiSelectState |
| `lines` | collides | `lines_` on TuiTextAreaState |

A capturing lambda cannot be given module-level storage, and it cannot be converted to a plain procedure pointer. That is why button callbacks come in two forms: TuiButton with a plain TuiOnClick pointer, and the generic `TuiButtonOf( of F )` for anything that captures.

## What This Module Does Not Do

Stated so you can plan around it rather than discover it:

- **No UAX-29 grapheme clustering.** Emoji ZWJ sequences measure wrong.
- **No CSS-like styling** or stylesheet language.
- **No images** -- no sixel, no kitty graphics protocol.
- **No terminfo parsing.** Capabilities come from environment variables and the console API, not from a terminfo database.
- **No accessibility layer.**
- **No async/thread bridge yet.** A channel-based input layer is deferred because its own first rule -- the terminal is not thread-safe -- cannot be tested without a terminal.

## Tests

The module's ten suites run in tiko-lang's test suite: tests/std/tui/ holds tuiapp, tuibuffer, tuicore, tuidraw, tuiform, tuiinput, tuilayout, tuiterm, tuiwidget and tuiwidth. tests/diagnostics/override-unused-generic.test pins the compiler fix that made the module build at all.

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Console and terminal](Functions-Console) lists them beside the rest of the area.

### Write a full-screen TUI app

| Function | What it does | From |
|---|---|---|
| [TuiApp](Modern-Tui-TuiApp) | Holds your app: you write Init to set up, Update to react and View to draw. | `std/tui` |
| [TuiApp.Init](Modern-Tui-TuiApp-Init) | Sets up your app and returns its first command, such as a tick to start animating. | `std/tui` |
| [TuiApp.Update](Modern-Tui-TuiApp-Update) | Reacts to one event and returns what the loop should do next; it never draws. | `std/tui` |
| [TuiApp.View](Modern-Tui-TuiApp-View) | Draws the whole screen from your app's state, changing nothing. | `std/tui` |
| [TuiApp.Shutdown](Modern-Tui-TuiApp-Shutdown) | Runs once as the loop ends, while the terminal is still taken. | `std/tui` |
| [TuiRun](Modern-Tui-TuiRun) | Runs your app full-screen and restores the terminal; returns the exit code or an error. | `std/tui` |
| [TuiRunOptions](Modern-Tui-TuiRunOptions) | Holds loop settings: frames per second and whether Ctrl+C quits. | `std/tui` |
| [TuiRunOptionsDefault](Modern-Tui-TuiRunOptionsDefault) | Returns the default loop settings: 60 frames per second, quit on Ctrl+C. | `std/tui` |
| [TuiTermOptions](Modern-Tui-TuiTermOptions) | Holds which terminal features to take: alternate screen, raw keys, mouse and more. | `std/tui` |
| [TuiTermOptionsDefault](Modern-Tui-TuiTermOptionsDefault) | Returns the usual terminal settings, with the mouse and focus events left off. | `std/tui` |

### Handle keys and the mouse in a TUI

| Function | What it does | From |
|---|---|---|
| [TuiEvent](Modern-Tui-TuiEvent) | Holds one event: a key, mouse action, resize, paste, focus change or tick. | `std/tui` |
| [TuiKey](Modern-Tui-TuiKey) | Holds a key press: a character or a named key, plus Shift, Ctrl and Alt. | `std/tui` |
| [TuiKey.IsChar](Modern-Tui-TuiKey-IsChar) | Returns true if the key is a typed character rather than a named key. | `std/tui` |
| [TuiKey.HasMod](Modern-Tui-TuiKey-HasMod) | Returns true if the given modifier, Shift, Alt or Ctrl, was held. | `std/tui` |
| [TuiKeyName](Modern-Tui-TuiKeyName) | Returns a readable name for a key, such as "Ctrl+Shift+F5". | `std/tui` |
| [TuiMouse](Modern-Tui-TuiMouse) | Holds a mouse event: press, release, move or wheel, the button, and the cell. | `std/tui` |

### Redraw, quit and run timers

| Function | What it does | From |
|---|---|---|
| [TuiCmd](Modern-Tui-TuiCmd) | Holds a command for the loop: what to do, plus a delay or an exit code. | `std/tui` |
| [TuiNone](Modern-Tui-TuiNone) | Returns a command that does nothing, for events your app ignores. | `std/tui` |
| [TuiRedraw](Modern-Tui-TuiRedraw) | Returns a command that draws the next frame; only the cells that changed are sent. | `std/tui` |
| [TuiQuit](Modern-Tui-TuiQuit) | Returns a command that ends the loop, so TuiRun returns the given exit code. | `std/tui` |
| [TuiTick](Modern-Tui-TuiTick) | Returns a command that sends one tick event after a delay; return another to repeat. | `std/tui` |
| [TuiInvalidate](Modern-Tui-TuiInvalidate) | Returns a command that repaints the whole screen instead of only the changes. | `std/tui` |
| [TuiSuspend](Modern-Tui-TuiSuspend) | Returns a command that leaves the terminal, suspends the program, then comes back. | `std/tui` |
| [TuiClockMs](Modern-Tui-TuiClockMs) | Returns a clock in milliseconds that never goes backwards, the one the loop uses. | `std/tui` |

### Show boxes, text, tabs and progress

| Function | What it does | From |
|---|---|---|
| [TuiBlock](Modern-Tui-TuiBlock) | Draws a border with titles and an optional fill; Inner gives the space inside. | `std/tui` |
| [TuiBlock.AddTitle](Modern-Tui-TuiBlock-AddTitle) | Adds a title to one side of the border, aligned left, centre or right. | `std/tui` |
| [TuiBlock.Inner](Modern-Tui-TuiBlock-Inner) | Returns the space inside the border, which is empty for a very small block. | `std/tui` |
| [TuiTitle](Modern-Tui-TuiTitle) | Holds one title on a block's border: its text, style and alignment. | `std/tui` |
| [TuiTitleOf](Modern-Tui-TuiTitleOf) | Returns a title value; the side argument comes before the alignment. | `std/tui` |
| [TuiBorderGlyphs](Modern-Tui-TuiBorderGlyphs) | Returns the characters for a border kind, such as plain ASCII for older consoles. | `std/tui` |
| [TuiBorderSet](Modern-Tui-TuiBorderSet) | Holds the six characters a border is drawn from: two lines and four corners. | `std/tui` |
| [TuiParagraph](Modern-Tui-TuiParagraph) | Draws text, wrapped or not, aligned left, centre or right, and scrollable. | `std/tui` |
| [TuiTabs](Modern-Tui-TuiTabs) | Draws a one-row strip of tab titles with the selected one highlighted. | `std/tui` |
| [TuiGauge](Modern-Tui-TuiGauge) | Draws a progress bar for a ratio from 0 to 1, labelled with the percentage. | `std/tui` |
| [TuiMeter](Modern-Tui-TuiMeter) | Draws a bar filled to a ratio whose colour shades from one end to the other. | `std/tui` |
| [TuiSpinner](Modern-Tui-TuiSpinner) | Draws a busy indicator that moves on one step each time you call Advance. | `std/tui` |
| [TuiSpinner.Advance](Modern-Tui-TuiSpinner-Advance) | Moves the spinner to its next frame, wrapping at the end. | `std/tui` |
| [TuiSpinnerDefaultFrames](Modern-Tui-TuiSpinnerDefaultFrames) | Fills an array with the default braille spinner frames. | `std/tui` |

### Show lists, tables and trees

| Function | What it does | From |
|---|---|---|
| [TuiList](Modern-Tui-TuiList) | Draws a scrolling list the user moves through with the arrow keys. | `std/tui` |
| [TuiListState](Modern-Tui-TuiListState) | Holds a list's selected item and scroll position; -1 means nothing is selected. | `std/tui` |
| [TuiTable](Modern-Tui-TuiTable) | Draws a scrolling table with headers, its columns sized like a layout. | `std/tui` |
| [TuiTableState](Modern-Tui-TuiTableState) | Holds a table's selected row and scroll position. | `std/tui` |
| [TuiRow](Modern-Tui-TuiRow) | Holds one table row: its cell texts in column order. | `std/tui` |
| [TuiTree](Modern-Tui-TuiTree) | Draws a tree of nodes that the user expands and collapses with the arrow keys. | `std/tui` |
| [TuiTree.Add](Modern-Tui-TuiTree-Add) | Appends a node at a depth; the deeper nodes after it become its children. | `std/tui` |
| [TuiTree.VisibleCount](Modern-Tui-TuiTree-VisibleCount) | Counts the nodes currently shown, leaving out those inside collapsed nodes. | `std/tui` |
| [TuiTreeNode](Modern-Tui-TuiTreeNode) | Holds one tree node: its label, depth, whether it has children, and your own id. | `std/tui` |
| [TuiTreeState](Modern-Tui-TuiTreeState) | Holds a tree's selected node and scroll position. | `std/tui` |
| [TuiScrollbar](Modern-Tui-TuiScrollbar) | Draws a scrollbar from a total, the number visible and the current position. | `std/tui` |

### Build forms and move focus between fields

| Function | What it does | From |
|---|---|---|
| [TuiTextInput](Modern-Tui-TuiTextInput) | Draws a one-line text box with a cursor, selection and optional password masking. | `std/tui` |
| [TuiTextInputState](Modern-Tui-TuiTextInputState) | Holds a text box's text, cursor, selection and scroll position. | `std/tui` |
| [TuiTextInputStateInit](Modern-Tui-TuiTextInputStateInit) | Sets a text box's state to empty with nothing selected; call it before first use. | `std/tui` |
| [TuiTextInput.Insert](Modern-Tui-TuiTextInput-Insert) | Inserts text at the cursor, replacing any selection first. | `std/tui` |
| [TuiTextInput.DeleteSelection](Modern-Tui-TuiTextInput-DeleteSelection) | Removes the selected text, or does nothing if none is selected. | `std/tui` |
| [TuiTextInput.SelectionStart](Modern-Tui-TuiTextInput-SelectionStart) | Returns where the selection starts, or the cursor position if nothing is selected. | `std/tui` |
| [TuiTextInput.SelectionEnd](Modern-Tui-TuiTextInput-SelectionEnd) | Returns where the selection ends, or the cursor position if nothing is selected. | `std/tui` |
| [TuiTextArea](Modern-Tui-TuiTextArea) | Draws a multi-line text editor with optional line numbers. | `std/tui` |
| [TuiTextAreaState](Modern-Tui-TuiTextAreaState) | Holds a text area's lines, cursor line and column, and scroll position. | `std/tui` |
| [TuiTextAreaStateInit](Modern-Tui-TuiTextAreaStateInit) | Sets a text area's state to one empty line; call it before first use. | `std/tui` |
| [TuiCheckbox](Modern-Tui-TuiCheckbox) | Draws a labelled checkbox that Space or Enter toggles, changing your own boolean. | `std/tui` |
| [TuiRadioGroup](Modern-Tui-TuiRadioGroup) | Draws a set of options where one is chosen, stored in your own variable. | `std/tui` |
| [TuiSelect](Modern-Tui-TuiSelect) | Draws a dropdown list of options that opens over whatever is below it. | `std/tui` |
| [TuiSelect.IsOpen](Modern-Tui-TuiSelect-IsOpen) | Returns true if the dropdown's list is showing. | `std/tui` |
| [TuiSelectState](Modern-Tui-TuiSelectState) | Holds a dropdown's chosen option, whether it is open, and the highlighted entry. | `std/tui` |
| [TuiButton](Modern-Tui-TuiButton) | Draws a button that calls your procedure when the user presses Enter on it. | `std/tui` |
| [TuiButtonOf](Modern-Tui-TuiButtonOf) | Draws a button whose handler is a lambda that captures variables. | `std/tui` |
| [TuiFocusRing](Modern-Tui-TuiFocusRing) | Holds the Tab order of your widgets and tells each one when it has focus. | `std/tui` |
| [TuiFocusRing.Add](Modern-Tui-TuiFocusRing-Add) | Adds a widget to the end of the Tab order; the widget must outlive the frame. | `std/tui` |
| [TuiFocusRing.Next_](Modern-Tui-TuiFocusRing-Next) | Moves focus to the next widget, wrapping at the end, as Tab does. | `std/tui` |
| [TuiFocusRing.Prev](Modern-Tui-TuiFocusRing-Prev) | Moves focus to the previous widget, wrapping at the start, as Shift+Tab does. | `std/tui` |
| [TuiFocusRing.Focus](Modern-Tui-TuiFocusRing-Focus) | Focuses a given widget, or returns false if it is not in the ring. | `std/tui` |
| [TuiFocusRing.Current](Modern-Tui-TuiFocusRing-Current) | Returns the focused widget, or no value if the ring is empty. | `std/tui` |
| [TuiFocusRing.Count](Modern-Tui-TuiFocusRing-Count) | Counts the widgets in the Tab order. | `std/tui` |
| [TuiFocusRing.Clear](Modern-Tui-TuiFocusRing-Clear) | Empties the Tab order; the widgets themselves are left alone. | `std/tui` |

### Show pop-ups, dialogs, menus and status bars

| Function | What it does | From |
|---|---|---|
| [TuiPopup](Modern-Tui-TuiPopup) | Draws a floating panel over the screen, optionally modal and dimming what is behind. | `std/tui` |
| [TuiMessageBox](Modern-Tui-TuiMessageBox) | Draws a dialog with a title, a message and buttons, coloured by its kind. | `std/tui` |
| [TuiMessageBox.Accepted](Modern-Tui-TuiMessageBox-Accepted) | Returns true once Enter was pressed on a button; selected says which. | `std/tui` |
| [TuiMessageBox.Cancelled](Modern-Tui-TuiMessageBox-Cancelled) | Returns true once the dialog was dismissed with Esc. | `std/tui` |
| [TuiMenuBar](Modern-Tui-TuiMenuBar) | Draws a one-row menu bar whose menus drop down with Enter. | `std/tui` |
| [TuiMenuBar.IsOpen](Modern-Tui-TuiMenuBar-IsOpen) | Returns true if one of the menus is dropped down. | `std/tui` |
| [TuiMenu](Modern-Tui-TuiMenu) | Holds one menu of a menu bar: its label and its items. | `std/tui` |
| [TuiStatusBar](Modern-Tui-TuiStatusBar) | Draws one row of status items, some packed to the left and some to the right. | `std/tui` |
| [TuiStatusBar.Add](Modern-Tui-TuiStatusBar-Add) | Adds an item at the left or right; include any padding spaces in the text. | `std/tui` |
| [TuiStatusItem](Modern-Tui-TuiStatusItem) | Holds one status bar item: its text, style and alignment. | `std/tui` |
| [TuiStatusItemOf](Modern-Tui-TuiStatusItemOf) | Returns a status bar item from text, a style and an alignment. | `std/tui` |

### Draw graphs, charts and braille dots

| Function | What it does | From |
|---|---|---|
| [TuiGraph](Modern-Tui-TuiGraph) | Draws a line graph of one or more series, scaled to fit or to a fixed range. | `std/tui` |
| [TuiSeries](Modern-Tui-TuiSeries) | Holds one line of a graph: its values, newest last, plus a colour and name. | `std/tui` |
| [TuiSparkline](Modern-Tui-TuiSparkline) | Draws a one-row trend of values as block characters, one value per cell. | `std/tui` |
| [TuiBarChart](Modern-Tui-TuiBarChart) | Draws labelled bars, vertical or horizontal, scaled to the largest value. | `std/tui` |
| [TuiBar](Modern-Tui-TuiBar) | Holds one bar of a bar chart: its label, value and colour. | `std/tui` |
| [TuiCanvas](Modern-Tui-TuiCanvas) | Holds a braille drawing surface with a grid of 2 by 4 dots in every cell. | `std/tui` |
| [TuiCanvas.Dot](Modern-Tui-TuiCanvas-Dot) | Sets one dot in a colour; a dot outside the canvas is ignored. | `std/tui` |
| [TuiCanvas.Line_](Modern-Tui-TuiCanvas-Line) | Draws a straight line of dots between two points. | `std/tui` |
| [TuiCanvas.Clear](Modern-Tui-TuiCanvas-Clear) | Turns every dot off. | `std/tui` |
| [TuiCanvas.Blit](Modern-Tui-TuiCanvas-Blit) | Draws the canvas into an area of the frame as braille characters. | `std/tui` |
| [TuiCanvas.Resize](Modern-Tui-TuiCanvas-Resize) | Changes the canvas size in cells and clears it. | `std/tui` |
| [TuiCanvas.CellCols](Modern-Tui-TuiCanvas-CellCols) | Returns the canvas width in cells. | `std/tui` |
| [TuiCanvas.CellRows](Modern-Tui-TuiCanvas-CellRows) | Returns the canvas height in cells. | `std/tui` |
| [TuiCanvas.DotWidth](Modern-Tui-TuiCanvas-DotWidth) | Returns the canvas width in dots, two per cell. | `std/tui` |
| [TuiCanvas.DotHeight](Modern-Tui-TuiCanvas-DotHeight) | Returns the canvas height in dots, four per cell. | `std/tui` |
| [TuiCanvas.Pattern](Modern-Tui-TuiCanvas-Pattern) | Returns the braille dot pattern of one cell as a byte. | `std/tui` |

### Split the screen into panels

| Function | What it does | From |
|---|---|---|
| [TuiSplitV](Modern-Tui-TuiSplitV) | Splits a rectangle into rows stacked top to bottom, sized by constraints. | `std/tui` |
| [TuiSplitH](Modern-Tui-TuiSplitH) | Splits a rectangle into columns side by side, sized by constraints. | `std/tui` |
| [TuiLength](Modern-Tui-TuiLength) | Returns a constraint for exactly n cells. | `std/tui` |
| [TuiFill](Modern-Tui-TuiFill) | Returns a constraint that shares the space left over, by weight. | `std/tui` |
| [TuiPercent](Modern-Tui-TuiPercent) | Returns a constraint for a percentage of the whole space being split. | `std/tui` |
| [TuiRatio](Modern-Tui-TuiRatio) | Returns a constraint for a fraction of the whole space, such as one third. | `std/tui` |
| [TuiAtLeast](Modern-Tui-TuiAtLeast) | Returns a constraint for at least n cells, more if there is room. | `std/tui` |
| [TuiAtMost](Modern-Tui-TuiAtMost) | Returns a constraint for at most n cells. | `std/tui` |
| [TuiConstraint](Modern-Tui-TuiConstraint) | Holds one sizing rule for a split, such as a fixed length or a share of the rest. | `std/tui` |
| [TuiSolve](Modern-Tui-TuiSolve) | Returns the sizes that constraints give a total, adding up to exactly that total. | `std/tui` |
| [TuiCenter](Modern-Tui-TuiCenter) | Returns a rectangle of a given size centred in another, as for a dialog. | `std/tui` |
| [TuiAlignIn](Modern-Tui-TuiAlignIn) | Returns a rectangle of a given width at the left, centre or right of another. | `std/tui` |
| [TuiPad](Modern-Tui-TuiPad) | Returns a rectangle shrunk by a margin. | `std/tui` |
| [TuiPadAll](Modern-Tui-TuiPadAll) | Returns a rectangle shrunk by the same amount on every side. | `std/tui` |
| [TuiStack](Modern-Tui-TuiStack) | Holds child widgets laid out in a row or column; it deletes them when it goes. | `std/tui` |
| [TuiStack.Add](Modern-Tui-TuiStack-Add) | Adds a child widget made with New and the constraint that sizes it. | `std/tui` |
| [TuiStack.ChildRect](Modern-Tui-TuiStack-ChildRect) | Returns the rectangle a child got at the last Render, for mouse hit tests. | `std/tui` |

### Rectangles, sizes and margins

| Function | What it does | From |
|---|---|---|
| [TuiRect](Modern-Tui-TuiRect) | Holds a rectangle of cells: x, y, width and height, counted from 0. | `std/tui` |
| [TuiRectOf](Modern-Tui-TuiRectOf) | Returns a rectangle from x, y, width and height. | `std/tui` |
| [TuiRect.Contains](Modern-Tui-TuiRect-Contains) | Returns true if a cell is inside the rectangle; use it to hit-test the mouse. | `std/tui` |
| [TuiRect.Intersect](Modern-Tui-TuiRect-Intersect) | Returns the overlap of two rectangles, or an empty one if they do not touch. | `std/tui` |
| [TuiRect.Inner](Modern-Tui-TuiRect-Inner) | Returns the rectangle shrunk by a margin, empty rather than negative. | `std/tui` |
| [TuiRect.IsEmpty](Modern-Tui-TuiRect-IsEmpty) | Returns true if the rectangle has no width or no height. | `std/tui` |
| [TuiRect.Equals](Modern-Tui-TuiRect-Equals) | Returns true if two rectangles have the same position and size. | `std/tui` |
| [TuiRect.Right](Modern-Tui-TuiRect-Right) | Returns x plus the width: the first column past the right edge. | `std/tui` |
| [TuiRect.Bottom](Modern-Tui-TuiRect-Bottom) | Returns y plus the height: the first row below the bottom edge. | `std/tui` |
| [TuiPos](Modern-Tui-TuiPos) | Holds a cell position: x and y. | `std/tui` |
| [TuiSize](Modern-Tui-TuiSize) | Holds a size in columns and rows. | `std/tui` |
| [TuiSizeOf](Modern-Tui-TuiSizeOf) | Returns a size from columns and rows. | `std/tui` |
| [TuiMargin](Modern-Tui-TuiMargin) | Holds an inset for each side, in the order left, top, right, bottom. | `std/tui` |
| [TuiMarginOf](Modern-Tui-TuiMarginOf) | Returns a margin from left, top, right and bottom. | `std/tui` |
| [TuiMarginAll](Modern-Tui-TuiMarginAll) | Returns a margin of the same size on every side. | `std/tui` |

### Style text: attributes and themes

| Function | What it does | From |
|---|---|---|
| [TuiStyle](Modern-Tui-TuiStyle) | Holds a text style: colours, attributes such as bold, and which of them it sets. | `std/tui` |
| [TuiStyleOf](Modern-Tui-TuiStyleOf) | Returns a style with a foreground, a background and optional attributes. | `std/tui` |
| [TuiStylePatch](Modern-Tui-TuiStylePatch) | Returns a partial style that sets only the parts you name, such as just bold. | `std/tui` |
| [TuiStyleDefault](Modern-Tui-TuiStyleDefault) | Returns the terminal's default style: default colours and no attributes. | `std/tui` |
| [TuiStyle.Patch](Modern-Tui-TuiStyle-Patch) | Returns this style with another laid over it, keeping whatever the other leaves unset. | `std/tui` |
| [TuiStyle.HasAttr](Modern-Tui-TuiStyle-HasAttr) | Returns true if the style has an attribute such as bold or underline. | `std/tui` |
| [TuiStyle.Equals](Modern-Tui-TuiStyle-Equals) | Returns true if two styles are identical, including which parts they set. | `std/tui` |
| [TuiTheme](Modern-Tui-TuiTheme) | Holds twelve named styles, such as normal, accent, selected and danger. | `std/tui` |
| [TuiThemeDefault](Modern-Tui-TuiThemeDefault) | Returns the stock colour theme. | `std/tui` |
| [TuiThemeMono](Modern-Tui-TuiThemeMono) | Returns a theme made from bold, dim, reverse and underline, with no colours. | `std/tui` |

### Pick colours

| Function | What it does | From |
|---|---|---|
| [TuiColor](Modern-Tui-TuiColor) | Holds a colour: the terminal's default, one of 16 or 256, or 24-bit RGB. | `std/tui` |
| [TuiRgb](Modern-Tui-TuiRgb) | Returns a 24-bit colour, reduced for you on terminals with fewer colours. | `std/tui` |
| [TuiAnsi](Modern-Tui-TuiAnsi) | Returns one of the 16 classic colours, which follow the user's terminal theme. | `std/tui` |
| [TuiIndexed](Modern-Tui-TuiIndexed) | Returns a colour from the 256-colour palette by its number. | `std/tui` |
| [TuiDefaultColor](Modern-Tui-TuiDefaultColor) | Returns the terminal's own default colour; as a background it does not paint. | `std/tui` |
| [TuiBlack](Modern-Tui-TuiBlack) | Returns the classic black, palette colour 0. | `std/tui` |
| [TuiRed](Modern-Tui-TuiRed) | Returns the classic red, palette colour 1. | `std/tui` |
| [TuiGreen](Modern-Tui-TuiGreen) | Returns the classic green, palette colour 2. | `std/tui` |
| [TuiYellow](Modern-Tui-TuiYellow) | Returns the classic yellow, palette colour 3. | `std/tui` |
| [TuiBlue](Modern-Tui-TuiBlue) | Returns the classic blue, palette colour 4. | `std/tui` |
| [TuiMagenta](Modern-Tui-TuiMagenta) | Returns the classic magenta, palette colour 5. | `std/tui` |
| [TuiCyan](Modern-Tui-TuiCyan) | Returns the classic cyan, palette colour 6. | `std/tui` |
| [TuiWhite](Modern-Tui-TuiWhite) | Returns the classic white, palette colour 7. | `std/tui` |
| [TuiBrightBlack](Modern-Tui-TuiBrightBlack) | Returns the classic bright black, palette colour 8. | `std/tui` |
| [TuiBrightRed](Modern-Tui-TuiBrightRed) | Returns the classic bright red, palette colour 9. | `std/tui` |
| [TuiBrightGreen](Modern-Tui-TuiBrightGreen) | Returns the classic bright green, palette colour 10. | `std/tui` |
| [TuiBrightYellow](Modern-Tui-TuiBrightYellow) | Returns the classic bright yellow, palette colour 11. | `std/tui` |
| [TuiBrightBlue](Modern-Tui-TuiBrightBlue) | Returns the classic bright blue, palette colour 12. | `std/tui` |
| [TuiBrightMagenta](Modern-Tui-TuiBrightMagenta) | Returns the classic bright magenta, palette colour 13. | `std/tui` |
| [TuiBrightCyan](Modern-Tui-TuiBrightCyan) | Returns the classic bright cyan, palette colour 14. | `std/tui` |
| [TuiBrightWhite](Modern-Tui-TuiBrightWhite) | Returns the classic bright white, palette colour 15. | `std/tui` |
| [TuiColor.Equals](Modern-Tui-TuiColor-Equals) | Returns true if two colours were built the same way with the same values. | `std/tui` |
| [TuiColor.Index](Modern-Tui-TuiColor-Index) | Returns the palette number of a 16-colour or 256-colour value. | `std/tui` |
| [TuiColor.IsDefault](Modern-Tui-TuiColor-IsDefault) | Returns true if the colour is the terminal's own default. | `std/tui` |
| [TuiLerpColor](Modern-Tui-TuiLerpColor) | Returns a colour part of the way between two others, for t from 0 to 1. | `std/tui` |
| [TuiDowngrade](Modern-Tui-TuiDowngrade) | Returns the colour that a terminal with fewer colours would show instead. | `std/tui` |
| [TuiDowngradeStyle](Modern-Tui-TuiDowngradeStyle) | Returns a style with both its colours reduced to what a terminal can show. | `std/tui` |
| [TuiRgbTo256](Modern-Tui-TuiRgbTo256) | Returns the nearest 256-palette colour number for red, green and blue values. | `std/tui` |
| [TuiRgbTo16](Modern-Tui-TuiRgbTo16) | Returns the nearest of the 16 classic colours for red, green and blue values. | `std/tui` |
| [TuiLuminance](Modern-Tui-TuiLuminance) | Returns how bright a colour looks, from 0.0 to 1.0. | `std/tui` |

### Measure, cut and wrap text by columns

| Function | What it does | From |
|---|---|---|
| [TuiStringWidth](Modern-Tui-TuiStringWidth) | Counts the columns a string takes on screen, wide characters as two. | `std/tui` |
| [TuiCharWidth](Modern-Tui-TuiCharWidth) | Returns the columns one character takes: 0, 1 or 2. | `std/tui` |
| [TuiTruncate](Modern-Tui-TuiTruncate) | Cuts a string to fit a number of columns, ending in "..." unless you pass "". | `std/tui` |
| [TuiWrap](Modern-Tui-TuiWrap) | Breaks text into lines that fit a number of columns, keeping its line breaks. | `std/tui` |
| [TuiSetAmbiguousWide](Modern-Tui-TuiSetAmbiguousWide) | Sets whether characters of ambiguous width count as two columns, for CJK terminals. | `std/tui` |
| [TuiAmbiguousWide](Modern-Tui-TuiAmbiguousWide) | Returns true if characters of ambiguous width count as two columns. | `std/tui` |

### Draw on the frame and write your own widgets

| Function | What it does | From |
|---|---|---|
| [TuiFrame](Modern-Tui-TuiFrame) | Holds the surface View draws on; drawing never fails and is clipped to fit. | `std/tui` |
| [TuiFrame.Area](Modern-Tui-TuiFrame-Area) | Returns the whole screen as a rectangle at 0, 0, the start of every layout. | `std/tui` |
| [TuiFrame.DrawText](Modern-Tui-TuiFrame-DrawText) | Draws a string at a cell and returns the number of columns it used. | `std/tui` |
| [TuiFrame.SetCell](Modern-Tui-TuiFrame-SetCell) | Writes one character cell, replacing the style that was there. | `std/tui` |
| [TuiFrame.FillRect](Modern-Tui-TuiFrame-FillRect) | Fills a rectangle with one character in one style. | `std/tui` |
| [TuiFrame.BlendStyle](Modern-Tui-TuiFrame-BlendStyle) | Lays a style over every cell of a rectangle, keeping the characters. | `std/tui` |
| [TuiFrame.Clip](Modern-Tui-TuiFrame-Clip) | Returns the rectangle that drawing is currently limited to. | `std/tui` |
| [TuiFrame.PushClip](Modern-Tui-TuiFrame-PushClip) | Limits drawing to a rectangle and returns the previous limit, to restore later. | `std/tui` |
| [TuiFrame.PopClip](Modern-Tui-TuiFrame-PopClip) | Restores the drawing limit that PushClip returned. | `std/tui` |
| [TuiFrame.PushLayer](Modern-Tui-TuiFrame-PushLayer) | Starts an overlay layer, as a popup or an open dropdown uses. | `std/tui` |
| [TuiFrame.PopLayer](Modern-Tui-TuiFrame-PopLayer) | Ends the overlay layer that PushLayer started. | `std/tui` |
| [TuiFrame.SetCursor](Modern-Tui-TuiFrame-SetCursor) | Shows the text cursor at a cell for this frame. | `std/tui` |
| [TuiFrame.HideCursor](Modern-Tui-TuiFrame-HideCursor) | Hides the text cursor for this frame, which is the default. | `std/tui` |
| [TuiFrame.CursorVisible](Modern-Tui-TuiFrame-CursorVisible) | Returns true if this frame asked to show the cursor. | `std/tui` |
| [TuiFrame.CursorPos](Modern-Tui-TuiFrame-CursorPos) | Returns the cell where the cursor was last put. | `std/tui` |
| [TuiWidget](Modern-Tui-TuiWidget) | Holds the base type every widget extends; you write Render and Kind for your own. | `std/tui` |
| [TuiWidget.Render](Modern-Tui-TuiWidget-Render) | Draws the widget into an area of the frame, changing no app state. | `std/tui` |
| [TuiWidget.HandleEvent](Modern-Tui-TuiWidget-HandleEvent) | Offers an event to the widget and returns true if the widget used it. | `std/tui` |
| [TuiWidget.Kind](Modern-Tui-TuiWidget-Kind) | Returns the widget's short type name, such as "Block". | `std/tui` |
| [TuiWidget.CanFocus](Modern-Tui-TuiWidget-CanFocus) | Returns true if the widget can take focus; false unless it is interactive. | `std/tui` |
| [TuiWidget.SetFocused](Modern-Tui-TuiWidget-SetFocused) | Tells the widget whether it has focus; the focus ring calls it for you. | `std/tui` |
| [TuiWidget.SizeHint](Modern-Tui-TuiWidget-SizeHint) | Returns the size the widget would like in the space given; layouts may ignore it. | `std/tui` |

### Render frames and test without a terminal

| Function | What it does | From |
|---|---|---|
| [TuiRenderOnce](Modern-Tui-TuiRenderOnce) | Runs Init and View once with no terminal and returns the bytes it would write. | `std/tui` |
| [TuiScreen](Modern-Tui-TuiScreen) | Holds two cell buffers and works out the bytes that turn one frame into the next. | `std/tui` |
| [TuiScreen.BeginFrame](Modern-Tui-TuiScreen-BeginFrame) | Clears the back buffer and returns the frame to draw into. | `std/tui` |
| [TuiScreen.Render](Modern-Tui-TuiScreen-Render) | Returns the bytes that change the last frame into the new one, then swaps buffers. | `std/tui` |
| [TuiScreen.Resize](Modern-Tui-TuiScreen-Resize) | Changes the screen size in cells and forces a full repaint. | `std/tui` |
| [TuiScreen.Invalidate](Modern-Tui-TuiScreen-Invalidate) | Makes the next Render clear and repaint the whole screen. | `std/tui` |
| [TuiScreen.Cols](Modern-Tui-TuiScreen-Cols) | Returns the screen width in cells. | `std/tui` |
| [TuiScreen.Rows](Modern-Tui-TuiScreen-Rows) | Returns the screen height in cells. | `std/tui` |
| [TuiScreen.Back](Modern-Tui-TuiScreen-Back) | Returns the buffer being drawn into, so a test can read its cells. | `std/tui` |
| [TuiScreen.Front](Modern-Tui-TuiScreen-Front) | Returns the buffer the terminal is taken to show: the last frame sent. | `std/tui` |
| [TuiBuffer](Modern-Tui-TuiBuffer) | Holds a grid of character cells, stored row by row. | `std/tui` |
| [TuiBuffer.At](Modern-Tui-TuiBuffer-At) | Returns a pointer to the cell at x, y, without checking the bounds. | `std/tui` |
| [TuiBuffer.InBounds](Modern-Tui-TuiBuffer-InBounds) | Returns true if x, y is inside the buffer. | `std/tui` |
| [TuiBuffer.Clear](Modern-Tui-TuiBuffer-Clear) | Fills every cell with a space in the given style. | `std/tui` |
| [TuiBuffer.Resize](Modern-Tui-TuiBuffer-Resize) | Changes the grid size and blanks every cell. | `std/tui` |
| [TuiBuffer.Count](Modern-Tui-TuiBuffer-Count) | Returns the number of cells: columns times rows. | `std/tui` |
| [TuiCell](Modern-Tui-TuiCell) | Holds one character cell: the character, its style and its width in columns. | `std/tui` |
| [TuiCell.SetChar](Modern-Tui-TuiCell-SetChar) | Sets the cell's character and works out its width in columns. | `std/tui` |
| [TuiCell.Equals](Modern-Tui-TuiCell-Equals) | Returns true if two cells have the same character, style and width. | `std/tui` |
| [TuiCellBlank](Modern-Tui-TuiCellBlank) | Returns a cell holding a space in the given style. | `std/tui` |

### Drive the terminal and parse input yourself

| Function | What it does | From |
|---|---|---|
| [TuiTerminal](Modern-Tui-TuiTerminal) | Holds the terminal itself, for writing your own loop: modes, size and output. | `std/tui` |
| [TuiTerminal.Enter](Modern-Tui-TuiTerminal-Enter) | Takes over the terminal with the options asked for; fails if output is not a terminal. | `std/tui` |
| [TuiTerminal.Leave](Modern-Tui-TuiTerminal-Leave) | Puts the terminal back the way Enter found it; safe to call more than once. | `std/tui` |
| [TuiTerminal.IsActive](Modern-Tui-TuiTerminal-IsActive) | Returns true between a successful Enter and its Leave. | `std/tui` |
| [TuiTerminal.Size](Modern-Tui-TuiTerminal-Size) | Returns the terminal's size in columns and rows, or an error if it reports none. | `std/tui` |
| [TuiTerminal.TakeResize](Modern-Tui-TuiTerminal-TakeResize) | Returns true once after each resize of the terminal, then false. | `std/tui` |
| [TuiTerminal.Write](Modern-Tui-TuiTerminal-Write) | Adds bytes to the output buffer; nothing is sent until Flush. | `std/tui` |
| [TuiTerminal.WriteText](Modern-Tui-TuiTerminal-WriteText) | Adds a string to the output buffer as UTF-8. | `std/tui` |
| [TuiTerminal.Flush](Modern-Tui-TuiTerminal-Flush) | Sends the buffered output in one write and empties the buffer. | `std/tui` |
| [TuiTerminal.Discard](Modern-Tui-TuiTerminal-Discard) | Throws the buffered output away without sending it. | `std/tui` |
| [TuiTerminal.Pending](Modern-Tui-TuiTerminal-Pending) | Counts the bytes buffered and not yet sent. | `std/tui` |
| [TuiTerminal.Caps](Modern-Tui-TuiTerminal-Caps) | Returns what the terminal can do, as detected once when it was entered. | `std/tui` |
| [TuiTerminal.DetectCaps](Modern-Tui-TuiTerminal-DetectCaps) | Detects what the terminal can do again, without entering it. | `std/tui` |
| [TuiCaps](Modern-Tui-TuiCaps) | Holds what a terminal can do: colour depth, mouse, paste, focus events, Unicode. | `std/tui` |
| [TuiError](Modern-Tui-TuiError) | Holds a terminal error: a code and what was being attempted. | `std/tui` |
| [TuiError.Message](Modern-Tui-TuiError-Message) | Returns a readable line saying what failed, including any system error number. | `std/tui` |
| [TuiInput](Modern-Tui-TuiInput) | Holds the parser that turns raw terminal bytes into events. | `std/tui` |
| [TuiInput.Feed](Modern-Tui-TuiInput-Feed) | Adds raw bytes from the terminal; an unfinished sequence is kept for later. | `std/tui` |
| [TuiInput.NextEvent](Modern-Tui-TuiInput-NextEvent) | Returns the next complete event, or no value yet; a lone Esc waits for a timeout. | `std/tui` |
| [TuiInput.PushEvent](Modern-Tui-TuiInput-PushEvent) | Adds an event to the back of the queue, to inject input yourself. | `std/tui` |
| [TuiInput.Queued](Modern-Tui-TuiInput-Queued) | Counts the parsed events waiting to be taken. | `std/tui` |
| [TuiInput.Buffered](Modern-Tui-TuiInput-Buffered) | Counts the bytes held that do not yet make a whole event. | `std/tui` |
| [TuiInput.Reset](Modern-Tui-TuiInput-Reset) | Throws away the held bytes and the queued events. | `std/tui` |
| [TuiInput.WaitingOnLoneEsc](Modern-Tui-TuiInput-WaitingOnLoneEsc) | Returns true if the parser holds an Esc it cannot yet tell from a key sequence. | `std/tui` |
| [TuiEnterSeq](Modern-Tui-TuiEnterSeq) | Returns the escape sequence that Enter writes for a set of options. | `std/tui` |
| [TuiLeaveSeq](Modern-Tui-TuiLeaveSeq) | Returns the escape sequence that Leave writes to undo those options. | `std/tui` |
| [TuiClearScreenSeq](Modern-Tui-TuiClearScreenSeq) | Returns the escape sequence that clears the terminal screen. | `std/tui` |
| [TuiCursorTo](Modern-Tui-TuiCursorTo) | Returns the escape sequence that moves the cursor to a cell counted from 0. | `std/tui` |
| [TuiShowCursorSeq](Modern-Tui-TuiShowCursorSeq) | Returns the escape sequence that shows or hides the cursor. | `std/tui` |
| [TuiSgr](Modern-Tui-TuiSgr) | Returns the escape sequence that changes the terminal from one style to another. | `std/tui` |
| [TuiSgrReset](Modern-Tui-TuiSgrReset) | Returns the escape sequence that resets every colour and attribute. | `std/tui` |
| [TuiWin32InputMode](Modern-Tui-TuiWin32InputMode) | Returns the Windows console input mode that Enter would set for given options. | `std/tui` |

<!-- finder:end -->

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
