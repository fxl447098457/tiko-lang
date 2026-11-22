[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkApp**

# tkApp

Runs a tkControls program: start-up, the event loop, forms, fonts and the theme.

tkApp is the quick way to a running tkControls program. `tkApp_Init` starts SDL and SDL_ttf, picks the fonts and applies the theme; `tkApp_Run` shows the main form, runs the event loop until that form closes or `tkApp_Quit` is called, destroys every form and undoes `Init`. One application per process: a second `tkApp_Init` returns FALSE.

A **form** (`TK_FORM ptr`) is a window whose events arrive as callbacks: `tkForm_OnSize`, `OnPaint`, `OnKeyDown`, `OnClose`, `OnDestroy`, `OnThemeChanged` and `OnScaleChanged`. Each form is a [tkHost](tkHost) surface covered by one full-size **form widget**, `tkForm_Widget( f )`, and that widget is the parent you pass to every control's `Create`.

## Importing

```freebasic
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkButton"     ' each control you use

using tkApp
using tkHost
using tkButton
```

tkApp re-exports [tkHost](tkHost) and [tkTheme](tkTheme), and tkHost re-exports [tkPaint](tkPaint) with `vendor/SDL3/ttf` and `vendor/SDL3/image`, so `using tkHost`, `using tkPaint` and `using tkTheme` work without importing them yourself.

## Example

A form with one button that closes the program, adapted from the toolchain's `examples/tkControls/tkApp/`:

```freebasic
const IDC_OK = 1001
dim shared as TK_WIDGET ptr gOk

sub Ok_Click( byval hButton as TK_WIDGET ptr, byval id as long )
    tkApp_Quit( 0 )
end sub

sub Main_Size( byval f as TK_FORM ptr, byval cx as long, byval cy as long )
    tkWidget_SetPos( gOk, cx - tkForm_Scale( f, 100 ), cy - tkForm_Scale( f, 44 ), _
                     tkForm_Scale( f, 88 ), tkForm_Scale( f, 32 ) )
end sub

if tkApp_Init( ) = false then print "tkApp_Init: " & *SDL_GetError() : end 1
dim as TK_FORM ptr f = tkApp_NewForm( "Hello", 640, 400 )   ' DIPs; hidden until Run
tkForm_OnSize( f, @Main_Size )
gOk = tkButton_Create( tkForm_Widget( f ), IDC_OK )         ' themed, with the form's font
tkButton_SetText( gOk, "OK" )
tkButton_SetClickCallback( gOk, @Ok_Click )
end tkApp_Run( f )
```

`OnSize` sizes are window pixels; `tkForm_Scale( f, v )` turns a design value into pixels at the form's scale. The first `tkForm_Show` (which `tkApp_Run` calls) runs `OnSize` once and focuses the first tab stop.


## The application

There is one application per process, and its state is the module's.

| Procedure | What it does |
| --- | --- |
| `tkApp_Init( )` / `tkApp_Init( opts )` | Starts SDL (video) and SDL_ttf, resolves the font files, chooses the glyph and mono files and applies the theme `ThemeMode` asks for. Call it once, before any form exists. Returns FALSE when called a second time or when SDL or SDL_ttf fails to start. |
| `tkApp_IsInit( )` | TRUE between `tkApp_Init` and the end of `tkApp_Run` (or `tkApp_Shutdown`) |
| `tkApp_NewForm( title, cx, cy [, pOwner, forcedScale] )` | Creates a form, hidden. `cx` / `cy` are DIPs, scaled by the form's scale. Without `pOwner` it is a top-level window; with one it is a dialog owned by `pOwner`, at the owner's scale. `forcedScale` > 0 pins a top-level form's scale. Returns null before `Init`, when the window cannot be made, or when 64 forms are already open. |
| `tkApp_Run( mainForm )` | Shows the main form, runs the loop until it closes (or `tkApp_Quit`), destroys every form still open and undoes `Init`. Returns the exit code, or -1 before `Init` or with no form. |
| `tkApp_Quit( exitCode = 0 )` | Makes `tkApp_Run` return `exitCode`. It also ends any modal loop that is running. |
| `tkApp_FormCount( )` | The forms open now |
| `tkApp_GlyphFace( )` | The glyph font file `Init` chose (see [Fonts](#fonts)) |
| `tkApp_Options( )` | The options in force: those `Init` was given, with the UI files replaced by any fallback `Init` chose |
| `tkApp_DefaultFontDir( )` | Where a bare font file name is looked up when `FontDir` is empty: the program's own folder |
| `tkApp_FallbackFont( bMono [, bBold] )` | The file of the first installed family of a list of common UI (or monospace) families, through [tkFontList](tkFontList); `""` when none is installed |
| `tkApp_RunOnUI( proc [, payload] )` | **Any thread.** Queues `proc( payload )` for the UI thread, in call order. Returns FALSE when no application is running or `proc` is null. |
| `tkApp_IsUIThread( )` | TRUE on the thread that called `tkApp_Init` |
| `tkApp_SetTimer( ms, proc [, payload] )` | A timer that needs no form: `proc( id, payload )` runs on the UI thread every `ms` milliseconds. Returns the id, never 0 (0 means it failed: no application, a null proc, `ms` <= 0, or 64 timers already running). UI thread only. |
| `tkApp_KillTimer( id )` | Stops it; safe to call from the timer's own proc. A tick already queued is dropped. |
| `tkApp_SetTheme( t )` / `tkApp_Theme( )` | Sets the current [theme](tkTheme) and returns it (see below) |
| `tkApp_SetThemeMode( mode )` / `tkApp_ThemeMode( )` | `TKAPP_THEME_SYSTEM`, `_LIGHT`, `_DARK` or `_NONE`; any mode but `_NONE` is applied at once |
| `tkApp_Pump( )` | One turn of the loop without blocking |
| `tkApp_Shutdown( )` | `tkApp_Run`'s tear-down on its own: destroys every form, stops the timers and undoes `Init` |

**`TKAPP_OPTIONS`**

| Field | Default | Meaning |
| --- | --- | --- |
| `FontDir` | `""` | Where bare font file names are looked up; `""` is `tkApp_DefaultFontDir( )`. A folder you set ends in a path separator. |
| `FontUIFile` | `TK_FONT_UI` | The file of the UI roles. When it is not there, the first installed UI family. |
| `FontUIBoldFile` | `TK_FONT_UI_BOLD` | `TKFONT_UI_BOLD`. When it is not there, an installed bold UI family, then `FontUIFile`. |
| `FontUISize` | `10` | The point size of `TKFONT_UI`; the other roles are sized from it |
| `GlyphFontFile` | `""` | Tried first for the glyph roles when set; then the bundled `TK_FONT_ICONS` |
| `FontMonoFile` | `TK_FONT_MONO` | `TKFONT_MONO`. When it is not there, an installed monospace family, then `FontUIFile`. |
| `ThemeMode` | `TKAPP_THEME_SYSTEM` | `TKAPP_THEME_LIGHT`, `TKAPP_THEME_DARK`, or `TKAPP_THEME_NONE` to leave the controls' built-in colours |

## Fonts

`TKAPP_OPTIONS` names font **files**, not face names. By default they are the fonts tkControls bundles (`TK_FONT_UI`, `TK_FONT_UI_BOLD`, `TK_FONT_MONO`, `TK_FONT_ICONS`), which tiko copies beside every program, so `FontDir = ""` means the program's own folder. A bare file name is looked up in `FontDir`; a name with a path separator is used as it is, and so is a font or resource name registered with [tkHost](tkHost). A UI file that is not there falls back to an installed family (`tkApp_FallbackFont`, through [tkFontList](tkFontList), which skips `.ttc` collections); `GlyphFontFile`, when set, is tried before the bundled icon font. When no glyph file is there, the glyph roles use the UI file.

Each form opens the **role** fonts at its own scale on first use with `tkForm_Font( f, role )`, and frees them with the form:

| Role | Font |
| --- | --- |
| `TKFONT_UI` | `FontUIFile` at `FontUISize` |
| `TKFONT_UI_SMALL` | `FontUIFile`, one point smaller |
| `TKFONT_UI_BOLD` | `FontUIBoldFile` at `FontUISize` |
| `TKFONT_UI_LARGE` | `FontUIFile`, two points larger |
| `TKFONT_GLYPH`, `TKFONT_GLYPH_LARGE` | The glyph file (`tkApp_GlyphFace`), at `FontUISize` and two points larger |
| `TKFONT_MONO` | The monospace file at `FontUISize` |

The UI role is the surface's default font, so a control placed on a form uses it without being told. Hand other roles to a control yourself with its `ApplyFonts`, for example `tkButton_ApplyFonts( h, 0, tkForm_Font( f, TKFONT_GLYPH ) )`. `tkForm_SetRoleFont( f, role, file, pt )` replaces a role and returns the new font (null when the file cannot be opened); replacing `TKFONT_UI` also replaces the surface's default font. The old handle stays valid until the form goes, because the surface owns every font it opened; pass the new handle on to the controls that use it. `tkForm_RoleFile` and `tkForm_RolePoints` say which file and size a role uses.

## Forms

### Callbacks

Every callback receives the form first. A null proc clears a callback.

| Setter | Callback shape | Notes |
| --- | --- | --- |
| `tkForm_OnSize( f, p )` | `sub( f, cx, cy )` | The client size in window pixels. The first show runs it once before the form appears; after that, whenever the client size changes. |
| `tkForm_OnPaint( f, p )` | `sub( f, b as TK_PAINT ptr )` | Paints the form widget, under the controls, on a background already filled with the theme's `Window` colour. Without it the form shows that background. |
| `tkForm_OnKeyDown( f, p )` | `function( f, key, mods ) as boolean` | A key no control claimed: `key` is an `SDLK_*` keycode, `mods` the `SDL_Keymod` state. TRUE consumes it. |
| `tkForm_OnClose( f, p )` | `function( f ) as boolean` | The close button or `tkForm_Close`. FALSE cancels the close. |
| `tkForm_OnDestroy( f, p )` | `sub( f )` | As the form is destroyed, after the forms it owns and before its controls go |
| `tkForm_OnThemeChanged( f, p )` | `sub( f )` | After a theme switch, so a form that paints itself can pick up the new roles from `tkApp_Theme( )` |
| `tkForm_OnScaleChanged( f, p )` | `sub( f, fOld, fNew )` | After the form moved to a monitor with another scale (see [Scale changes](#scale-changes)) |

A key goes to the focused control first and bubbles up its parents while they refuse it. One no control claims goes to `OnKeyDown`; if that does not consume it, Esc ends a modal form with `TKAPP_IDCANCEL`, and a Tab nobody claimed moves the focus (the host's focus walk; Shift+Tab goes back).

A close (the close button, or `tkForm_Close`) asks `OnClose` first. If it is not cancelled:
- a modal form's loop ends with `TKAPP_IDCANCEL`;
- a modeless form is flagged and destroyed by the loop between events; when it is the main form, `tkApp_Run` then returns.

### Other procedures

| Procedure | What it does |
| --- | --- |
| `tkForm_Widget( f )` | The full-size form widget: the parent for the form's controls |
| `tkForm_Host( f )` | The form's [tkHost](tkHost) surface |
| `tkForm_Scale( f, v )` | A design value in pixels at the form's scale |
| `tkForm_Font( f, role )` | The role's font (see [Fonts](#fonts)); null for an unknown role |
| `tkForm_SetRoleFont( f, role, file, pt )` | Replaces a role's font |
| `tkForm_Show( f )` | Shows a form modelessly. The first call runs `OnSize` and focuses the first tab stop. |
| `tkForm_ShowModal( f )` | Runs the form modally until `tkForm_EndModal`, Esc or the close button, then destroys it and returns the code |
| `tkForm_EndModal( f, code )` | Ends a modal form's loop with `code`; does nothing to a form that is not modal |
| `tkForm_IsModal( f )` | |
| `tkForm_Close( f )` | Closes the form as the close button does, so `OnClose` is asked |
| `tkForm_FocusFirst( f )` | Focuses the first tab stop |
| `tkForm_Invalidate( f )` | Repaints the form |
| `tkForm_Destroy( f )` | Destroys the forms it owns, fires `OnDestroy`, then destroys the surface and every control on it |
| `tkForm_FromWidget( w )` | The form a widget lives on: its surface's form or, for a popup, the form of the surface's owner. A control callback receives only the widget; this is how it reaches the form. Null when there is none. |
| `tkForm_FromHost( h )` | The form whose surface is `h` |

## Theme, modal forms, background work

- **Theme.** `ThemeMode` (or `tkApp_SetThemeMode`) is `TKAPP_THEME_SYSTEM` (follows the OS light/dark setting live), `_LIGHT`, `_DARK` or `_NONE` (controls keep their built-in colours). `tkApp_SetTheme( t )` restyles every control whose colours are not pinned, gives every form the theme's `Window` colour as its background, repaints it and fires its `OnThemeChanged`. A form takes the current `Window` colour when it is made. See [tkTheme](tkTheme).
- **Modal forms.** `tkApp_NewForm( title, cx, cy, ownerForm )` makes a dialog owned by `ownerForm`. `tkForm_ShowModal` runs it until `tkForm_EndModal( f, code )`, Esc (`TKAPP_IDCANCEL`) or the close button (which asks `OnClose` first), then destroys the form and returns the code. The owner gets no input meanwhile. The first `ShowModal` runs `OnSize` once, as the first `Show` does.
- **The window.** `tkForm_SetStartPosition( f, TKFORM_POS_CENTER_SCREEN )` (or `_CENTER_OWNER`, or `_DEFAULT`) says where the form goes when it is first shown; later calls change nothing on screen. `_DEFAULT` leaves it to the system, except that an owned form starts centred over its owner, and `_CENTER_OWNER` on a form without an owner is `_CENTER_SCREEN`. On Linux the window manager may override it, and Wayland always places windows itself. Wayland has no always-on-top, and `tkForm_SetIcon` returns false where the compositor offers no window icons. `tkForm_SetResizable`, `tkForm_SetMinSize` / `tkForm_SetMaxSize` (the client, in design units, 0 for no limit; scaled with the form), `tkForm_SetWindowState` (`TKFORM_STATE_NORMAL`, `_MAXIMIZED`, `_MINIMIZED`; before the first show it is how the window first appears, after it applies at once, and maximized needs a resizable window), `tkForm_SetAlwaysOnTop` and `tkForm_SetIcon( f, file )` (any image SDL_image reads, or a resource name registered with [tkHost](tkHost); FALSE when it cannot be read) each have a getter. On Windows a form's icon is its title bar's: a program with an icon of its own (an `ICON` in its `.rc`) keeps that one in the taskbar and Alt+Tab, and a program without one shows the form's there too. A top-level form starts resizable, an owned one fixed.
- **Keys.** `OnKeyDown` receives the keys no control claimed; return TRUE to consume one. Tab is the host's focus walk. For shortcuts that work whichever control has the focus, attach a [tkKeys](tkKeys) map to `tkForm_Host( f )`.
- **Background work.** `tkApp_RunOnUI( proc, payload )` may be called from any thread: `proc( payload )` runs on the UI thread, in call order, wherever the loop is pumping (inside a modal form too). Only the payload pointer is copied. Work still queued when `tkApp_Run` returns is dropped.
- **Timers.** `tkApp_SetTimer( ms, proc, payload )` needs no form and returns an id (0 on failure); `tkApp_KillTimer` is safe from inside the timer's own proc. Timers belong to the application, not to a form.
- **Tests.** `tkApp_Pump` runs one non-blocking turn of the loop; `tkApp_Shutdown` is `Run`'s tear-down on its own.

### Background work

Controls are touched only on the UI thread, so a worker (a raw thread, or a `std/tasks` goroutine) never calls one. It hands each result back with `tkApp_RunOnUI`:

```freebasic
sub Ui_Progress( byval payload as any ptr )     ' the UI thread
    tkProgressBar_SetPos( gBar, cast( long, cast( integer, payload ) ) )
end sub

sub Worker( byval nSteps as long )              ' another thread
    for i as long = 1 to nSteps
        ' ... the work ...
        tkApp_RunOnUI( @Ui_Progress, cast( any ptr, cast( integer, i ) ) )
    next
end sub
```

- `tkApp_RunOnUI` queues an SDL event, and the queue keeps call order. tkApp watches the host's events wherever the loop is: in `tkApp_Run`, in `tkApp_Pump` and inside a modal form's loop, so queued work runs inside those too.
- It copies the payload pointer, never what it points at. The payload's lifetime is the caller's.
- Timer ticks arrive the same way, on the UI thread.

**Polling a channel instead.** To drain a `std/tasks` channel, poll it with `TryReceive` from a `tkApp_SetTimer` proc; a blocking `Receive` on the UI thread would stop the loop.

## Scale changes

Each form follows the scale of the monitor it is on. When a form moves to a monitor with another scale:
1. The surface takes the new scale, so `tkForm_Scale` agrees with it.
2. Every font the surface opened is re-sized, the role fonts included.
3. `TKM_SCALECHANGED` goes down the widget tree. The form widget gets it first: the form re-applies its minimum and maximum size and `OnScaleChanged` fires. Then every control on the form gets it.
4. The form widget is re-sized to the client, which runs `OnSize` when the size changed.

A font opened with `tkHost_OpenFont( tkForm_Host( f ), ... )` is re-sized with the role fonts. A font you own yourself must be opened again at the new scale in `OnScaleChanged`.

## Behaviour and limits

- **Controls start zero-sized.** Position them in `OnSize` with `tkWidget_SetPos`, scaling design values with `tkForm_Scale`.
- **Parent every control to `tkForm_Widget( f )`.** Keys no control claims bubble up to the form widget, which is how `OnKeyDown` sees them.
- **Keep your widget pointers.** A form does not look its controls up by id.
- **Fonts are automatic.** A control on a form takes the form's UI role as its default font; `ApplyFonts` overrides it.
- **The theme is automatic.** Every control is themed as it is created. Calling one of its colour setters pins its colours (see [tkTheme](tkTheme)).
- **Event hooks.** tkApp uses `tkHost_SetEventHook` for its own events and the OS theme; to watch SDL events yourself, use `tkHost_AddEventHook`, which is asked after tkApp's.
- **Limits.** At most 64 forms open and 64 timers running at a time.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKAPP_IDOK = 1
const TKAPP_IDCANCEL = 2

enum
    TKFORM_POS_DEFAULT = 0          ' the system's; an owned form starts centred over its owner
    TKFORM_POS_CENTER_SCREEN
    TKFORM_POS_CENTER_OWNER         ' a form with no owner: as CENTER_SCREEN
end enum

enum
    TKFORM_STATE_NORMAL = 0
    TKFORM_STATE_MAXIMIZED
    TKFORM_STATE_MINIMIZED
end enum

enum
    TKAPP_THEME_SYSTEM = 0
    TKAPP_THEME_LIGHT
    TKAPP_THEME_DARK
    TKAPP_THEME_NONE
end enum

enum
    TKFONT_UI = 0
    TKFONT_UI_SMALL
    TKFONT_UI_BOLD
    TKFONT_UI_LARGE
    TKFONT_GLYPH
    TKFONT_GLYPH_LARGE
    TKFONT_MONO
    TKFONT_COUNT
end enum
```

### Types

```freebasic
type TKAPP_OPTIONS
    FontDir        as ustring            ' "" = the bundled fonts' (see tkApp_DefaultFontDir)
    FontUIFile     as ustring = TK_FONT_UI
    FontUIBoldFile as ustring = TK_FONT_UI_BOLD
    FontUISize     as single = 10
    GlyphFontFile  as ustring            ' tried FIRST when set; then TK_FONT_ICONS
    FontMonoFile   as ustring = TK_FONT_MONO   ' then an installed mono family, then the UI file
    ThemeMode      as long = TKAPP_THEME_SYSTEM
end type

type TK_FORM_   ' per-instance state; reach it through the procedures

type TK_FORM as TK_FORM_
type TKFORM_SizeSub as sub( byval f as TK_FORM ptr, byval cx as long, byval cy as long )
type TKFORM_PaintSub as sub( byval f as TK_FORM ptr, byval b as TK_PAINT ptr )
type TKFORM_KeyFunc as function( byval f as TK_FORM ptr, byval key as long, byval mods as long ) as boolean
type TKFORM_CloseFunc as function( byval f as TK_FORM ptr ) as boolean
type TKFORM_Sub as sub( byval f as TK_FORM ptr )
type TKFORM_ScaleSub as sub( byval f as TK_FORM ptr, byval fOld as single, byval fNew as single )
type TKAPP_UIProc as sub( byval payload as any ptr )
type TKAPP_TimerProc as sub( byval id as long, byval payload as any ptr )
```

### Procedures

```freebasic
function tkApp_DefaultFontDir() as ustring
function tkApp_FallbackFont( byval bMono as boolean, byval bBold as boolean = false ) as ustring
function tkApp_GlyphFace() as ustring
function tkApp_Options() as TKAPP_OPTIONS
function tkApp_Init( byref opts as TKAPP_OPTIONS = TKAPP_OPTIONS() ) as boolean
function tkApp_IsInit() as boolean
function tkApp_IsUIThread() as boolean
function tkApp_RunOnUI( byval proc as TKAPP_UIProc, byval payload as any ptr = 0 ) as boolean
function tkApp_SetTimer( byval ms as long, byval proc as TKAPP_TimerProc, byval payload as any ptr = 0 ) as long
sub tkApp_KillTimer( byval id as long )
function tkApp_Theme() as TKTHEME_COLORS
function tkApp_SetTheme( byref t as TKTHEME_COLORS ) as TKTHEME_COLORS
sub tkApp_SetThemeMode( byval nMode as long )
function tkApp_ThemeMode() as long
sub tkApp_Quit( byval exitCode as long = 0 )
function tkApp_FormCount() as long
sub tkApp_Shutdown()
function tkForm_FromWidget( byval w as TK_WIDGET ptr ) as TK_FORM ptr
function tkForm_FromHost( byval h as TK_HOST ptr ) as TK_FORM ptr
function tkApp_NewForm( byref title as ustring, byval cx as long, byval cy as long, byval pOwner as TK_FORM ptr = nullptr, byval forcedScale as single = 0 ) as TK_FORM ptr
function tkForm_Widget( byval f as TK_FORM ptr ) as TK_WIDGET ptr
function tkForm_Host( byval f as TK_FORM ptr ) as TK_HOST ptr
function tkForm_Scale( byval f as TK_FORM ptr, byval v as long ) as long
function tkForm_Font( byval f as TK_FORM ptr, byval role as long ) as TTF_Font ptr
function tkForm_SetRoleFont( byval f as TK_FORM ptr, byval role as long, byref file as ustring, byval pt as single ) as TTF_Font ptr
function tkForm_RoleFile( byval f as TK_FORM ptr, byval role as long ) as ustring
function tkForm_RolePoints( byval f as TK_FORM ptr, byval role as long ) as single
sub tkForm_Show( byval f as TK_FORM ptr )
function tkForm_ShowModal( byval f as TK_FORM ptr ) as long
sub tkForm_EndModal( byval f as TK_FORM ptr, byval code as long )
function tkForm_IsModal( byval f as TK_FORM ptr ) as boolean
sub tkForm_Close( byval f as TK_FORM ptr )
sub tkForm_FocusFirst( byval f as TK_FORM ptr )
sub tkForm_Invalidate( byval f as TK_FORM ptr )
sub tkForm_SetStartPosition( byval f as TK_FORM ptr, byval where as long )
function tkForm_GetStartPosition( byval f as TK_FORM ptr ) as long
sub tkForm_SetResizable( byval f as TK_FORM ptr, byval bResizable as boolean )
function tkForm_GetResizable( byval f as TK_FORM ptr ) as boolean
sub tkForm_SetMinSize( byval f as TK_FORM ptr, byval cx as long, byval cy as long )
sub tkForm_SetMaxSize( byval f as TK_FORM ptr, byval cx as long, byval cy as long )
sub tkForm_GetMinSize( byval f as TK_FORM ptr, byref cx as long, byref cy as long )
sub tkForm_GetMaxSize( byval f as TK_FORM ptr, byref cx as long, byref cy as long )
sub tkForm_SetWindowState( byval f as TK_FORM ptr, byval nState as long )
function tkForm_GetWindowState( byval f as TK_FORM ptr ) as long
sub tkForm_SetAlwaysOnTop( byval f as TK_FORM ptr, byval bOnTop as boolean )
function tkForm_GetAlwaysOnTop( byval f as TK_FORM ptr ) as boolean
function tkForm_SetIcon( byval f as TK_FORM ptr, byref file as ustring ) as boolean
sub tkForm_Destroy( byval f as TK_FORM ptr )
sub tkForm_OnSize( byval f as TK_FORM ptr, byval p as TKFORM_SizeSub )
sub tkForm_OnPaint( byval f as TK_FORM ptr, byval p as TKFORM_PaintSub )
sub tkForm_OnKeyDown( byval f as TK_FORM ptr, byval p as TKFORM_KeyFunc )
sub tkForm_OnClose( byval f as TK_FORM ptr, byval p as TKFORM_CloseFunc )
sub tkForm_OnDestroy( byval f as TK_FORM ptr, byval p as TKFORM_Sub )
sub tkForm_OnThemeChanged( byval f as TK_FORM ptr, byval p as TKFORM_Sub )
sub tkForm_OnScaleChanged( byval f as TK_FORM ptr, byval p as TKFORM_ScaleSub )
sub tkApp_Pump()
function tkApp_Run( byval mainForm as TK_FORM ptr ) as long
```

### See also

- [tkControls](Category-tkControls)
- [tkHost](tkHost)
- [tkTheme](tkTheme)
