[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkHost**

# tkHost

Runs every tkControls widget: SDL windows, the widget tree, input, timers and fonts.

tkHost is the widget core under every tkControls control. It gives SDL the services Win32 gave a window for free: a tree of widgets in each window, hit testing, hover, mouse capture, focus and Tab order, timers, per-monitor scale, popups, modal dialogs, text input with the IME, cursors, the clipboard and file drops. It also ships the fonts tkControls draws with.

Most programs meet it only through [tkApp](tkApp): `tkWidget_SetPos` to lay out controls, `TK_WIDGET ptr` as every control's handle. Read on if you write your own widget or run without tkApp.

## Importing

```freebasic
#import "vendor/tkControls/tkHost"

using tkHost
using tkPaint
```

Every tkControls module imports tkHost publicly, so after any control's `#import`, `using tkHost` works without a line of its own. tkHost re-exports [tkPaint](tkPaint), which re-exports `vendor/SDL3/ttf` and `vendor/SDL3/image`.

## Example

A program without tkApp, with one widget of its own that paints a box and counts clicks:

```freebasic
dim shared as long gClicks

function Box_Proc( byval w as TK_WIDGET ptr, byval m as TK_MSG ptr ) as boolean
    select case m->msg
    case TKM_PAINT
        dim as TKRECT rc
        tkRect_Set( rc, 0, 0, w->cw, w->ch )
        m->pPaint->SetBackColor( iif( tkHost_GetFocus( w->pHost ) = w, tkRGB( 38, 79, 120 ), tkRGB( 44, 49, 58 ) ) )
        m->pPaint->PaintRect( @rc )
        dim as ustring caption = "clicks: " & gClicks
        m->pPaint->SetForeColor( tkRGB( 255, 255, 255 ) )
        m->pPaint->PaintText( caption, @rc, TK_DT_CENTER )
        return true
    case TKM_LBUTTONDOWN
        tkHost_SetFocus( w->pHost, w )      ' a widget takes the focus itself
        gClicks += 1
        tkWidget_Invalidate( w )
        return true
    case TKM_SETFOCUS, TKM_KILLFOCUS
        tkWidget_Invalidate( w )
        return true
    end select
    return false                            ' refused: keys and the wheel go on to the parent
end function

SDL_Init( SDL_INIT_VIDEO ) : TTF_Init( )
dim as TK_HOST ptr h = tkHost_Create( "tkHost", 400, 240, tkHost_FontDir() & TK_FONT_UI )
dim as TK_WIDGET ptr box = tkWidget_Create( h, 100, @Box_Proc, 0 )
box->isFocusable = true
tkWidget_SetPos( box, tkHost_Scale( h, 20 ), tkHost_Scale( h, 20 ), tkHost_Scale( h, 200 ), tkHost_Scale( h, 60 ) )
tkHost_Show( h )
tkHost_Run( h )                             ' blocks until the window closes
tkHost_Destroy( h )
TTF_Quit( ) : SDL_Quit( )
```

## Surfaces

Every OS window is a `TK_HOST`, called a surface, with its own renderer, widget tree, focus, capture and hot widget:

| Kind | Made by | Notes |
| --- | --- | --- |
| `TK_SURF_MAIN` | `tkHost_Create( title, w, h, defaultFont, forcedScale )` | `w`, `h` in design units: the window comes out `w * scale` pixels |
| `TK_SURF_POPUP`, `TK_SURF_TOOLTIP` | `tkHost_CreatePopup( owner, x, y, w, h, kind )` | owner window pixels (`tkHost_PlacePopup` computes them against an anchor rect). Created hidden and empty; make one per open and `tkHost_Close` it per dismissal |
| `TK_SURF_DIALOG` | `tkHost_CreateDialog( owner, title, w, h, bBorderless )` | pixels; run it with `tkHost_RunModal`, end it with `tkHost_EndModal( dlg, result )` |

A press outside a popup closes it and is consumed; Esc closes the top popup; a popup also closes when the application loses focus. A borderless dialog gets a draggable caption band with `tkHost_SetDragRect`. `tkHost_Run` blocks in the event loop until the surface quits; `tkHost_Pump` drains the queue without blocking and repaints what changed. `tkHost_Close` hides a surface at once and destroys it after the current event; `tkHost_Destroy` destroys it now, with its popups and widgets.

Fields a host program sets on a `TK_HOST`: `clrBack` (`&hAARRGGBB`), `pDefaultFont`, `pUser`, and the callbacks `OnPaint` (the surface's own background), `OnSize`, `OnScale`, `OnClosed` (a popup closed, for any reason), `OnCloseRequest` (the close button; TRUE keeps the window open), `OnPreKey` (asked before the focused widget, which is how [tkKeys](tkKeys) attaches) and `OnDrop` (a drop no widget took).

## Widgets and coordinates

A widget is a `TK_WIDGET` with a `proc` (`tkWidgetProc`) and a `pData` pointer to your own state. Make one with `tkWidget_CreateChild( parent, id, proc, pData )`, or `tkWidget_Create( host, id, proc, pData )` for a child of the surface's root (`tkHost_Root`). Children are kept in z-order: the last made is on top (`tkWidget_BringToTop` moves one).

- `x`, `y` are relative to the parent, in **device pixels**; `cw`, `ch` are its size. Messages carry **widget-local** pixels, as Win32 client coordinates did. `tkWidget_AbsRect` gives window pixels.
- Multiply design values by the scale with `tkHost_Scale( h, v )`; `TKM_SCALECHANGED` tells every widget when the window moves to a monitor with another scale, and the host re-sizes the fonts it opened.
- Flags: `isFocusable` (a Tab stop), `bWantsText` (focus here starts text input and the IME, so `TKM_CHAR` arrives), `cursor` (`TK_CURSOR_*`), `bClipChildren`.
- `tkWidget_Enable` and `tkWidget_Show` take a whole subtree out of input, Tab order, hover, capture and focus at once.
- `tkWidget_Destroy` destroys the children first, kills the widget's timers and sends `TKM_DESTROY` last: free `pData` there.

## Messages

The proc gets `TK_MSG` messages shaped like the Win32 ones they replace. Return TRUE when handled.

| Message | Carries |
| --- | --- |
| `TKM_PAINT` | `pPaint`, a [tkPaint](tkPaint) context clipped to the widget, origin at its top-left |
| `TKM_SIZE` | sent by `tkWidget_SetPos` / `SetSize` when the size changes |
| `TKM_MOUSEMOVE`, `TKM_MOUSEENTER`, `TKM_MOUSELEAVE` | `x`, `y`; enter and leave need no tracking request |
| `TKM_LBUTTONDOWN` ... `TKM_MBUTTONUP` | `x`, `y`, `clicks` (2 = a double click on the same widget) |
| `TKM_MOUSEWHEEL` | `wheelX`, `wheelY` in notches, `mods`; **bubbles** to the parent if refused |
| `TKM_KEYDOWN`, `TKM_KEYUP` | `key` (an `SDL_Keycode`), `mods`, `scancode`, `bFlag` = repeat; key down **bubbles** if refused |
| `TKM_CHAR`, `TKM_IMECOMPOSE` | `text` (UTF-8); the composition's `nStart`, `nLen` |
| `TKM_SETFOCUS`, `TKM_KILLFOCUS` | `pOther`, the widget on the other side |
| `TKM_CAPTURECHANGED` | sent at once to the widget losing the capture |
| `TKM_ENABLE`, `TKM_SHOW` | `bFlag`, the new state |
| `TKM_TIMER` | `timerId` |
| `TKM_SCALECHANGED`, `TKM_THEMECHANGED`, `TKM_DESTROY` | `fOld`, `fNew` for the scale |
| `TKM_DROPFILES`, `TKM_DROPTEXT` | `text` (paths LF-separated, `nStart` = how many), `x`, `y`; **bubble** if refused |
| `TKM_CONTEXTMENU` | to a context-menu component: `pOther` = the widget it opens for, `x`, `y` = where, in window pixels; `bFlag` = from the keyboard |
| `TKM_ADORNLAYOUT` | to an adornment just before it paints: place yourself against your parent (the target) with `tkWidget_SetPos`; invalidations made while handling it are dropped, this frame already uses the new rect |

Rules a widget author relies on:

- **Focus is the widget's to take.** A click focuses nothing by itself: call `tkHost_SetFocus( w->pHost, w )` in `TKM_LBUTTONDOWN`. Tab and Shift+Tab walk the focusable widgets in tree order when no widget claims the key.
- **Capture** with `tkHost_SetCapture( w )` and `tkHost_ReleaseCapture( h )`: moves and the release keep coming to `w` while the mouse is outside it or the window. While a widget holds the capture it hears Esc first.
- **Timers** with `tkWidget_SetTimer( w, id, ms )`, delivered as `TKM_TIMER` on the UI thread. Ids below `TK_TIMER_APP` are reserved.
- **Context menus** with `tkWidget_SetContextMenu( w, hMenu )`: the right button's release over `w` or anything inside it, and the Menu key or Shift+F10 when the focus is there, go to `hMenu` as `TKM_CONTEXTMENU` instead of to the control. [tkContextMenu](tkContextMenu) is the component that answers it; it calls `tkWidget_ClearContextMenuRefs` as it goes.
- **Watching the mouse from outside** with `tkWidget_SetMouseMoveCallback( w, cb )`: `cb` (a `TK_MouseMoveSub`) is told of every move over `w`, and over anything inside it that has no watcher of its own, with `x, y` in pixels from `w`'s top-left, SDL's button mask and the modifier keys. It runs after the widget's own `TKM_MOUSEMOVE`, needs no subclassing, and works on any control; 0 clears it. The Form Designer's MouseMove event is built on it.
- **Adornments** with `tkWidget_SetAdorner( w, true )`: `w` becomes a decoration of its parent (an attached badge, a validation mark). It is painted right after the parent's own subtree, with the clip the *parent* was given, so it may overhang the parent and sits above it and its other children; before each paint it gets `TKM_ADORNLAYOUT` to place itself against the parent's current size. It is never hit-tested (a click on it reaches what is below), never in the Tab order, and gives up focus, capture and hot when it becomes one; otherwise it is an ordinary child, hidden, moved, rescaled, rethemed and destroyed with its parent. A sibling above the parent in z-order covers it as it covers the parent, and the parent's parent clips it. Code that walks a widget's children for layout skips `w->bAdorner` ones (tkScrollPanel's `AutoSizeContent` does). `tkWidget_IsAdorner( w )` reads the flag.
- **Theme.** On `TKM_THEMECHANGED`, re-read [tkTheme](tkTheme)'s `tkTheme_Get()` unless your widget's colours are pinned.
- **Notify like the controls do**: callbacks for user actions only; setters are silent.
- `tkWidget_SetTextKind( w, kind )` says which screen keyboard a text widget asks for: `TK_TEXT_DEFAULT` (SDL's own; every widget's default), `TK_TEXT_LINE`, `TK_TEXT_MULTILINE`, `TK_TEXT_DECIMAL`, `TK_TEXT_INTEGER` or `TK_TEXT_PASSWORD`. A focused widget's text input restarts with the new kind, and focus moving to a widget of another kind restarts it too -- on a phone 120 ms later, because Android loses a start that comes straight after a stop. `tkHost_TextKindOn( h )` is the kind the live text input was started with, -1 when none is on.
- `tkHost_SetTextInputArea` tells the IME where to put its candidate window; `tkHost_SetClipboardText`, `GetClipboardText` and `HasClipboardText` reach the clipboard.

## Fonts and icons

tkControls ships its own fonts, copied beside every program that imports tkHost, so a program looks the same on every OS:

| Constant | Font |
| --- | --- |
| `TK_FONT_UI`, `TK_FONT_UI_BOLD`, `TK_FONT_UI_ITALIC` | Inter, for text |
| `TK_FONT_MONO` | Cascadia Mono, for code |
| `TK_FONT_ICONS` | Fluent UI System Icons, for glyphs |

`tkHost_FontDir()` is the folder they are in (the program's own, ending in a separator), so `tkHost_FontDir() & TK_FONT_UI` is always a file that is there. `tkHost_OpenFont( h, path, pt )` opens a font in points at the surface's scale; the surface owns it, re-sizes it when the scale changes and closes it when the surface goes. `h->pDefaultFont` is the font every control falls back to.

`tkHost_FontSource( f, path, face )` says where a font `tkHost_OpenFontFace` opened came from (the name or path it was given, and the face); [tkPrint](tkPrint) re-opens recorded fonts at a page's size this way. Close a font you opened with `tkHost_OpenFontFace` through `tkHost_CloseFont`, which also forgets its source. `tkHost_FontBytes( path, pData, nBytes, bOwned )` gives a font's bytes by the same name or path: a registered resource's own (bOwned FALSE), or the file read whole (bOwned TRUE: `SDL_free` them). [tkPdf](tkPdf) embeds fonts this way.

### Fonts and images by name

A program can carry its fonts and images inside itself instead of beside it. Register each one's bytes under a name, and every font tkHost, [tkApp](tkApp) and [tkCodeEdit](tkCodeEdit) open, and every image [tkImage](tkImage), [tkPicture](tkPicture), [tkButton](tkButton) and `tkForm_SetIcon` load, takes that name where it takes a file path:

```freebasic
#embed InterRegular "fonts/Inter-Regular.ttf"

tkHost_AddFontData( "mem:Inter-Regular.ttf", @InterRegular(0), ubound( InterRegular ) + 1 )
dim as TK_HOST ptr h = tkHost_Create( "app", 400, 240, "mem:Inter-Regular.ttf" )
```

- The name must match exactly; nothing is derived from it. `mem:` plus the file name is the convention: with tkApp's `FontDir` set to `"mem:"`, its role fonts are found under their usual file names.
- The bytes stay the program's and must outlive every font opened from them. An [`#embed`](Category-Embed) array lives as long as the program.
- Registering a name again replaces it. `tkHost_HasFontData( name )` says whether a name is registered.
- `tkHost_AddResourceData( name, p, n )` is the same registry for any font or image; `tkHost_AddFontData` is its older name. `tkHost_AddResourceFile( name, path )` makes a name stand for a file instead, `tkHost_RemoveResource( name )` takes one back, `tkHost_HasResource( name )` says whether it stands for something there (bytes, or a file that exists) and `tkHost_ResourceFile( name )` is the file it stands for.
- The [Form Designer](Form-Designer)'s Resource Center names a project's resources `res:<name>`.
- `tkHost_LoadSurface( path )` loads an image as an `SDL_Surface` from a registered name or a file, through SDL_image; the caller destroys it. The image loads above go through it.
- `tkHost_OpenFontFace( path, pt, face )` opens face `face` of a font file or registered name, unscaled and owned by the caller. The other font opens go through it.

The `TK_ICON_*` constants are code points in `TK_FONT_ICONS` (`TK_ICON_SAVE`, `TK_ICON_FOLDER_OPEN`, `TK_ICON_SEARCH`, `TK_ICON_SETTINGS`, `TK_ICON_CLOSE` and more). Draw one with that font set: `p->PaintChar( wchr( TK_ICON_SAVE ), @rc, clr )`; controls with a glyph slot take the same string.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TK_FONT_UI = "Inter-Regular.ttf"
const TK_FONT_UI_BOLD = "Inter-Bold.ttf"
const TK_FONT_UI_ITALIC = "Inter-Italic.ttf"
const TK_FONT_MONO = "CascadiaMono-Regular.ttf"
const TK_FONT_ICONS = "FluentSystemIcons-Regular.ttf"
const TK_ICON_CHEVRON_DOWN = &hF2A3
const TK_ICON_CHEVRON_RIGHT = &hF2B0
const TK_ICON_MORE = &hE824 ' the horizontal ellipsis
const TK_ICON_CALENDAR = &hE24E
const TK_ICON_INFO = &hF4A3
const TK_ICON_WARNING = &hF869
const TK_ICON_ERROR = &hF3F1
const TK_ICON_QUESTION = &hF63D ' in a circle
const TK_ICON_CLOSE = &hF369
const TK_ICON_CHECKBOX = &hF291
const TK_ICON_CHECKBOX_CHECKED = &hF28D
const TK_ICON_CHECKMARK = &hF294
const TK_ICON_SAVE = &hF67F
const TK_ICON_REFRESH = &hF13D
const TK_ICON_SETTINGS = &hF6A9
const TK_ICON_FOLDER = &hF418
const TK_ICON_FOLDER_OPEN = &hF42E
const TK_ICON_OPEN = &hF582
const TK_ICON_DOCUMENT = &hF378
const TK_ICON_PAGE = &hE557 ' a document with lines
const TK_ICON_PLAY = &hF605
const TK_ICON_STOP = &hF72A
const TK_ICON_DELETE = &hF34C
const TK_ICON_STAR = &hF70F
const TK_ICON_LOCK = &hE78F
const TK_ICON_SEARCH = &hF68F
const TK_ICON_BUG = &hE206
const TK_ICON_CONSOLE = &hEE6F
const TK_ICON_WRENCH = &hEE86
const TK_ICON_WRAP = &hED69
const TK_ICON_HELP = &hF638 ' a bare question mark
const TK_ICON_ALIGN_LEFT = &hF79F
const TK_ICON_ALIGN_CENTER = &hF799
const TK_ICON_ALIGN_RIGHT = &hF7A1
const TK_ICON_BOLD = &hF7A4
const TK_ICON_LIKE = &hF81F

enum
    TKM_PAINT = 1
    TKM_SIZE
    TKM_MOUSEMOVE
    TKM_MOUSEENTER
    TKM_MOUSELEAVE
    TKM_LBUTTONDOWN          ' m->clicks = 2 for a double click (SDL's count)
    TKM_LBUTTONUP
    TKM_RBUTTONDOWN
    TKM_RBUTTONUP
    TKM_MBUTTONDOWN
    TKM_MBUTTONUP
    TKM_MOUSEWHEEL           ' m->wheelX / wheelY in notches; BUBBLES to the parent if refused
    TKM_CAPTURECHANGED
    TKM_SETFOCUS             ' m->pOther = the widget losing focus
    TKM_KILLFOCUS            ' m->pOther = the widget gaining it
    TKM_KEYDOWN              ' m->key (SDL_Keycode), m->mods, m->bFlag = repeat; BUBBLES if refused
    TKM_KEYUP
    TKM_CHAR                 ' m->text = UTF-8 text from SDL_EVENT_TEXT_INPUT
    TKM_IMECOMPOSE           ' m->text = the pre-edit string, m->nStart/nLen its cursor/selection
    TKM_ENABLE               ' m->bFlag = new state
    TKM_SHOW                 ' m->bFlag = new state
    TKM_TIMER                ' m->timerId
    TKM_SCALECHANGED         ' m->fOld / fNew
    TKM_THEMECHANGED
    TKM_DESTROY
    TKM_DROPFILES            ' files dropped from the OS: m->text = their paths, LF-separated (UTF-8),
    ' m->nStart = how many, m->x / y = the drop point; BUBBLES if refused
    TKM_DROPTEXT             ' text dropped from the OS: m->text, m->x / y; BUBBLES if refused
    TKM_CONTEXTMENU          ' to a CONTEXT-MENU COMPONENT (tkWidget_SetContextMenu): m->pOther = the widget
                             ' it opens for, m->x / y = where, in the surface's window pixels; m->bFlag =
                             ' from the keyboard (the Menu key, Shift+F10)
    TKM_ADORNLAYOUT          ' to an ADORNMENT just before it paints: place yourself against your parent
                             ' (the target) as it is now. Invalidations made while handling it are
                             ' dropped: this frame already paints the new rect.
end enum

enum
    TK_SURF_MAIN = 0
    TK_SURF_POPUP            ' menus, dropdowns: dismissed by Esc or a press elsewhere
    TK_SURF_TOOLTIP          ' never takes input, never dismissed by the router
    TK_SURF_DIALOG           ' modal, run by tkHost_RunModal
end enum

enum
    TK_CURSOR_ARROW = 0
    TK_CURSOR_IBEAM
    TK_CURSOR_HAND
    TK_CURSOR_SIZEWE
    TK_CURSOR_SIZENS
    TK_CURSOR_SIZEALL
    TK_CURSOR_WAIT
    TK_CURSOR_COUNT
end enum

enum
    TK_TIMER_CARET = 900
    TK_TIMER_AUTOREPEAT
    TK_TIMER_AUTOSCROLL
    TK_TIMER_MARQUEE
    TK_TIMER_HOVER
    TK_TIMER_TIPSHOW
    TK_TIMER_TIPPOP
    TK_TIMER_APP = 1000
end enum
```

### Types

```freebasic
type TK_MSG
    msg      as long
    x        as single          ' widget-local pixels (mouse messages)
    y        as single
    clicks   as long            ' button messages: 1, 2 for a double click
    wheelX   as single          ' TKM_MOUSEWHEEL, notches (fractional on precise devices)
    wheelY   as single
    key      as long            ' SDL_Keycode (TKM_KEYDOWN / KEYUP)
    mods     as long            ' SDL_Keymod
    timerId  as long            ' TKM_TIMER
    bFlag    as boolean         ' TKM_ENABLE / TKM_SHOW: the new state; TKM_KEYDOWN: repeat
    fOld     as single          ' TKM_SCALECHANGED
    fNew     as single
    text     as string          ' TKM_CHAR / TKM_IMECOMPOSE: UTF-8
    nStart   as long            ' TKM_IMECOMPOSE
    nLen     as long
    pOther   as TK_WIDGET ptr   ' TKM_SETFOCUS / KILLFOCUS: the other party
    pPaint   as TK_PAINT ptr    ' TKM_PAINT
    scancode as long            ' TKM_KEYDOWN / KEYUP: SDL_Scancode -- the physical key, for chords
end type

type TK_WIDGET_   ' per-instance state; reach it through the procedures

type TK_FONT
    f   as TTF_Font ptr
    pt  as single
end type

type TK_TIMER
    pW     as TK_WIDGET ptr
    id     as long
    sdlId  as SDL_TimerID
    gen    as long              ' bumped on kill, so a queued tick for a dead timer is dropped
    active as boolean
end type

type TK_HOST_   ' per-instance state; reach it through the procedures

type TK_HOST as TK_HOST_
type TK_WIDGET as TK_WIDGET_
type tkWidgetProc as function( byval w as TK_WIDGET ptr, byval m as TK_MSG ptr ) as boolean
type tkHostPaintSub as sub( byval h as TK_HOST ptr, byval p as TK_PAINT ptr )
type tkHostSub as sub( byval h as TK_HOST ptr )
type tkHostCloseFunc as function( byval h as TK_HOST ptr ) as boolean
type tkHostKeyFunc as function( byval h as TK_HOST ptr, byval m as TK_MSG ptr ) as boolean
type tkHostDropSub as sub( byval h as TK_HOST ptr, byval m as TK_MSG ptr )
type tkRendererGoneSub as sub( byval r as SDL_Renderer ptr )
type tkHotChangedSub as sub( byval h as TK_HOST ptr, byval w as TK_WIDGET ptr )
type tkEventHookFunc as function( byval e as SDL_Event ptr ) as boolean
type TK_MouseMoveSub as sub( byval w as TK_WIDGET ptr, byval x as long, byval y as long, byval buttons as long, byval mods as long )
```

### Procedures

```freebasic
function tkHost_FontDir() as ustring
sub tkHost_SetRendererGoneHook( byval f as tkRendererGoneSub )
sub tkHost_SetHotChangedHook( byval f as tkHotChangedSub )
sub tkHost_SetEventHook( byval f as tkEventHookFunc )
sub tkHost_AddEventHook( byval f as tkEventHookFunc )
sub tkHost_RemoveEventHook( byval f as tkEventHookFunc )
function tkHost_PressSerial() as ulong
function tkHost_Count() as long
function tkHost_Scale( byval h as TK_HOST ptr, byval v as long ) as long
sub tkHost_AddResourceData( byref name_ as string, byval pData as const any ptr, byval nBytes as integer )
sub tkHost_AddResourceFile( byref name_ as string, byref file as ustring )
sub tkHost_RemoveResource( byref name_ as string )
function tkHost_HasResource( byref name_ as string ) as boolean
function tkHost_ResourceFile( byref name_ as string ) as string
sub tkHost_AddFontData( byref name_ as string, byval pData as const any ptr, byval nBytes as integer )
function tkHost_HasFontData( byref name_ as string ) as boolean
function tkHost_LoadSurface( byref path as ustring ) as SDL_Surface ptr
function tkHost_OpenFontFace( byref path as string, byval pt as single, byval face as long ) as TTF_Font ptr
function tkHost_FontSource( byval f as TTF_Font ptr, byref path as string, byref face as long ) as boolean
sub tkHost_CloseFont( byval f as TTF_Font ptr )
function tkHost_FontBytes( byref path as string, byref pData as const any ptr, byref nBytes as integer, byref bOwned as boolean ) as boolean
function tkHost_OpenFont( byval h as TK_HOST ptr, byref path as ustring, byval pt as single ) as TTF_Font ptr
function tkHost_Create( byref title as ustring, byval w as long, byval hgt as long, byref defaultFont as ustring, byval forcedScale as single = 0 ) as TK_HOST ptr
function tkHost_CreatePopup( byval owner as TK_HOST ptr, byval x as long, byval y as long, byval w as long, byval hgt as long, byval kind as long = TK_SURF_POPUP, byval extraFlags as Uint64 = 0 ) as TK_HOST ptr
function tkHost_CreateDialog( byval owner as TK_HOST ptr, byref title as ustring, byval w as long, byval hgt as long, byval bBorderless as boolean = true ) as TK_HOST ptr
function tkHost_Root( byval h as TK_HOST ptr ) as TK_WIDGET ptr
sub tkHost_Show( byval h as TK_HOST ptr )
sub tkHost_PixelSize( byval h as TK_HOST ptr, byref w as long, byref hgt as long )
sub tkHost_Invalidate( byval h as TK_HOST ptr )
sub tkHost_PlacePopup( byval owner as TK_HOST ptr, byref rcAnchor as TKRECT, byval w as long, byval hgt as long, byval bSide as boolean, byref x as long, byref y as long )
function tkWidget_Send( byval w as TK_WIDGET ptr, byval m as TK_MSG ptr ) as boolean
sub tkWidget_AbsRect( byval w as TK_WIDGET ptr, byref rc as TKRECT )
function tkWidget_IsEnabled( byval w as TK_WIDGET ptr ) as boolean
function tkWidget_IsVisible( byval w as TK_WIDGET ptr ) as boolean
function tkWidget_CreateChild( byval parent as TK_WIDGET ptr, byval ctrlId as long, byval proc as tkWidgetProc, byval pData as any ptr ) as TK_WIDGET ptr
function tkWidget_Create( byval h as TK_HOST ptr, byval ctrlId as long, byval proc as tkWidgetProc, byval pData as any ptr ) as TK_WIDGET ptr
function tkWidget_Parent( byval w as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkWidget_BringToTop( byval w as TK_WIDGET ptr )
sub tkWidget_SetAdorner( byval w as TK_WIDGET ptr, byval bOn as boolean )
function tkWidget_IsAdorner( byval w as TK_WIDGET ptr ) as boolean
sub tkWidget_Invalidate( byval w as TK_WIDGET ptr )
sub tkWidget_SetPos( byval w as TK_WIDGET ptr, byval x as long, byval y as long, byval cw as long, byval ch as long )
sub tkWidget_SetSize( byval w as TK_WIDGET ptr, byval cw as long, byval ch as long )
function tkHost_GetCapture( byval h as TK_HOST ptr ) as TK_WIDGET ptr
sub tkHost_SetCapture( byval w as TK_WIDGET ptr )
sub tkHost_ReleaseCapture( byval h as TK_HOST ptr )
function tkHost_GetFocus( byval h as TK_HOST ptr ) as TK_WIDGET ptr
sub tkHost_SetFocus( byval h as TK_HOST ptr, byval w as TK_WIDGET ptr )
sub tkHost_SetTextInputArea( byval w as TK_WIDGET ptr, byref rc as TKRECT, byval cursorX as long )
function tkWidget_IsAncestorOf( byval w as TK_WIDGET ptr, byval p as TK_WIDGET ptr ) as boolean
sub tkWidget_Reparent( byval w as TK_WIDGET ptr, byval newParent as TK_WIDGET ptr )
sub tkWidget_Enable( byval w as TK_WIDGET ptr, byval bEnable as boolean )
sub tkWidget_Show( byval w as TK_WIDGET ptr, byval bShow as boolean )
sub tkWidget_SetContextMenu( byval w as TK_WIDGET ptr, byval hMenu as TK_WIDGET ptr )
function tkWidget_GetContextMenu( byval w as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkWidget_ClearContextMenuRefs( byval hMenu as TK_WIDGET ptr )
sub tkWidget_SetMouseMoveCallback( byval w as TK_WIDGET ptr, byval cb as TK_MouseMoveSub )
sub tkWidget_SetCursor( byval w as TK_WIDGET ptr, byval cursor as long )
sub tkWidget_KillTimer( byval w as TK_WIDGET ptr, byval id as long )
sub tkWidget_SetTimer( byval w as TK_WIDGET ptr, byval id as long, byval ms as long )
function tkWidget_HasTimer( byval w as TK_WIDGET ptr, byval id as long ) as boolean
sub tkWidget_Destroy( byval w as TK_WIDGET ptr )
sub tkHost_Close( byval h as TK_HOST ptr )
function tkHost_IsOpen( byval h as TK_HOST ptr ) as boolean
sub tkHost_Reap()
sub tkHost_Destroy( byval h as TK_HOST ptr )
sub tkHost_RenderTo( byval h as TK_HOST ptr, byval bPresent as boolean )
sub tkHost_Render( byval h as TK_HOST ptr )
function tkHost_HitTest( byval h as TK_HOST ptr, byval px as single, byval py as single ) as TK_WIDGET ptr
sub tkHost_BroadcastAll( byval msg as long, byval clrWindow as ulong = 0 )
function tkHost_CurrentCursor() as long
sub tkHost_FocusNext( byval h as TK_HOST ptr, byval bBack as boolean = false )
sub tkHost_WorkRect( byval h as TK_HOST ptr, byref rc as TKRECT )
sub tkHost_Dispatch( byval h as TK_HOST ptr, byval e as SDL_Event ptr )
sub tkHost_Pump( byval h as TK_HOST ptr )
sub tkHost_Run( byval h as TK_HOST ptr )
function tkHost_RunModal( byval dlg as TK_HOST ptr ) as long
sub tkHost_EndModal( byval dlg as TK_HOST ptr, byval result as long )
sub tkHost_SetDragRect( byval h as TK_HOST ptr, byref rc as TKRECT )
sub tkHost_SetClipboardText( byref s as ustring )
function tkHost_GetClipboardText() as ustring
function tkHost_HasClipboardText() as boolean
```

### See also

- [tkControls](Category-tkControls)
