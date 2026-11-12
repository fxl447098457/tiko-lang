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

## Fonts

`TKAPP_OPTIONS` names font **files**, not face names. By default they are the fonts tkControls bundles (`TK_FONT_UI`, `TK_FONT_UI_BOLD`, `TK_FONT_MONO`, `TK_FONT_ICONS`), which tiko copies beside every program, so `FontDir = ""` means the program's own folder. A bare file name is looked up in `FontDir`; a name with a path separator is used as it is. A UI file that is not there falls back to an installed family (`tkApp_FallbackFont`, through [tkFontList](tkFontList)); `GlyphFontFile`, when set, is tried before the bundled icon font.

Each form opens the **role** fonts (`TKFONT_UI`, `_UI_SMALL` one point smaller, `_UI_BOLD`, `_UI_LARGE` two points larger, `_GLYPH`, `_GLYPH_LARGE`, `_MONO`) at its own scale on first use with `tkForm_Font( f, role )`, and frees them with the form. The UI role is the surface's default font, so a control placed on a form uses it without being told. Hand other roles to a control yourself with its `ApplyFonts`, for example `tkButton_ApplyFonts( h, 0, tkForm_Font( f, TKFONT_GLYPH ) )`. `tkForm_SetRoleFont` replaces a role; pass the new handle on to the controls that use it.

## Theme, modal forms, background work

- **Theme.** `ThemeMode` (or `tkApp_SetThemeMode`) is `TKAPP_THEME_SYSTEM` (follows the OS light/dark setting live), `_LIGHT`, `_DARK` or `_NONE` (controls keep their built-in colours). `tkApp_SetTheme( t )` restyles every control whose colours are not pinned, gives every form the theme's `Window` colour and fires `OnThemeChanged`. See [tkTheme](tkTheme).
- **Modal forms.** `tkApp_NewForm( title, cx, cy, ownerForm )` makes a dialog owned by `ownerForm`. `tkForm_ShowModal` runs it until `tkForm_EndModal( f, code )`, Esc (`TKAPP_IDCANCEL`) or the close button (which asks `OnClose` first), then destroys the form and returns the code. The owner gets no input meanwhile.
- **Keys.** `OnKeyDown` receives the keys no control claimed; return TRUE to consume one. Tab is the host's focus walk. For shortcuts that work whichever control has the focus, attach a [tkKeys](tkKeys) map to `tkForm_Host( f )`.
- **Background work.** `tkApp_RunOnUI( proc, payload )` may be called from any thread: `proc( payload )` runs on the UI thread, in call order, wherever the loop is pumping (inside a modal form too). Only the payload pointer is copied. Work still queued when `tkApp_Run` returns is dropped.
- **Timers.** `tkApp_SetTimer( ms, proc, payload )` needs no form and returns an id (0 on failure); `tkApp_KillTimer` is safe from inside the timer's own proc.
- **Tests.** `tkApp_Pump` runs one non-blocking turn of the loop; `tkApp_Shutdown` is `Run`'s tear-down on its own.

## Coming from PsApp

| [PsApp](PsApp) | tkApp |
| --- | --- |
| `app.Init( opts )`, `app.Run( f )`, `app.Quit` | `tkApp_Init( opts )`, `tkApp_Run( f )`, `tkApp_Quit` |
| `app.NewForm( title, cx, cy, ..., hParent )` | `tkApp_NewForm( title, cx, cy, pOwner, forcedScale )` |
| `app.RunOnUI`, `IsUIThread`, `SetTimer`, `KillTimer` | `tkApp_RunOnUI`, `tkApp_IsUIThread`, `tkApp_SetTimer`, `tkApp_KillTimer` |
| `app.SetTheme`, `Theme`, `SetThemeMode`, `ThemeMode`, `GlyphFace`, `Options` | `tkApp_SetTheme`, `tkApp_Theme`, `tkApp_SetThemeMode`, `tkApp_ThemeMode`, `tkApp_GlyphFace`, `tkApp_Options` |
| `PsApp_Instance( )` | none; `tkApp_IsInit( )` |
| `PsForm` members, `f->OnSize( p )` | `tkForm_*( f, ... )`, `tkForm_OnSize( f, p )` |
| `OnDpiChanged`, `PsForm.FromHwnd` | `tkForm_OnScaleChanged`, `tkForm_FromWidget` |
| `PSFONT_*`, `PSAPP_THEME_*`, `PSAPP_OPTIONS` | `TKFONT_*`, `TKAPP_THEME_*`, `TKAPP_OPTIONS` |

- Procedures instead of the `PsApplication` / `PsForm` classes.
- Fonts are files (`FontUIFile`, `FontUIBoldFile`, `GlyphFontFile`, `FontMonoFile` in `FontDir`), opened as `TTF_Font ptr`.
- Controls take the form's UI font by being on the form; there is no per-control font hand-out except through `ApplyFonts`.
- Parent controls to `tkForm_Widget( f )`, not to a window handle. There is no `Item( id )`: keep your widget pointers.
- Gone with Win32: COM and DPI-awareness options, GDI+, message filters, accelerator tables (use [tkKeys](tkKeys)), and the per-form `OnCommand`, `OnNotify`, `OnMessage`, `OnTimer` and `OnActivateApp` (use control callbacks and `tkApp_SetTimer`).

The [PsApp](PsApp) page remains the behaviour reference for everything not listed here.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKAPP_IDOK = 1
const TKAPP_IDCANCEL = 2

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
- [PsApp](PsApp), the PsControls module
