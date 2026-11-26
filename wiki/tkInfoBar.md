[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkInfoBar**

# tkInfoBar

Draws an info bar: a message strip in the form's layout, with a severity, a title, a message,
action buttons and a close button.

`tkInfoBar` is the [tkControls](Category-tkControls) inline message bar, in the manner of WinUI's
InfoBar or KDE's KMessageWidget. It takes space in the layout: docked at the top of a form, it pushes
the content down while it is open and gives the strip back when it closes. It has **no timer**. It
stays until the user closes it or the program does. For a message that comes and goes by itself, use
[tkToast](tkToast).

Every setter is silent. The close button, Esc and the action buttons notify; `tkInfoBar_SetOpen( h, false )`
fires no Closing or Closed. The Form Designer's **InfoBar** binds its message: a record field with
text opens the bar, an empty one closes it.

## Importing

```freebasic
#import "vendor/tkControls/tkInfoBar"
#import "vendor/tkControls/tkLayout"      ' to dock it

using tkInfoBar
using tkNotify
using tkLayout
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme), and **tkNotify**: the part it shares with [tkToast](tkToast), which
holds the severities, the colour struct and the painter. Add `using tkNotify` for its constants
(`TKN_WARNING`, …) and `using tkPaint` for `TKRECT`. It uses [tkLayout](tkLayout) inside but does not
re-export it: import tkLayout yourself to dock the bar.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Update_Action( byval hBar as TK_WIDGET ptr, byval id as long )
    if id = 1 then print "install now" else tkInfoBar_SetOpen( hBar, false )   ' an action does not close the bar
end sub

sub Update_Closed( byval hBar as TK_WIDGET ptr, byval reason as long )
    print "closed by the user, reason " & reason       ' TKN_CLOSE_BUTTON or TKN_CLOSE_KEY
end sub

dim as TK_LAYOUT ptr l = tkLayout_Create( )
tkLayout_AddContainer( l, tkHost_Root( host ), 640, 480 )

dim as TK_WIDGET ptr bar = tkInfoBar_Create( tkHost_Root( host ), 100 )     ' starts closed
tkInfoBar_SetSeverity( bar, TKN_WARNING )
tkInfoBar_SetTitle( bar, "Update available" )
tkInfoBar_SetMessage( bar, "Version 0.1.7 is ready to install." )
tkInfoBar_AddAction( bar, "Install" )                ' id 1
tkInfoBar_AddAction( bar, "Later" )                  ' id 2
tkInfoBar_SetActionCallback( bar, @Update_Action )
tkInfoBar_SetClosedCallback( bar, @Update_Closed )

tkLayout_Add( l, bar, 0, 0, 640, 44, TK_ANCHOR_NONE, TK_DOCK_TOP )
tkInfoBar_AttachLayout( bar, l )                     ' docked at its own height; re-laid out when it changes
' ... the rest of the form, docked or anchored below it ...
tkLayout_Apply( l )

tkInfoBar_SetOpen( bar, true )                       ' slides open; the content below follows it
```

## Opening and closing

- A bar **starts closed**, and closed means hidden (`tkWidget_Show`). `tkInfoBar_Create( parent, id, true )`
  starts it open, as a designed form's bar does.
- `SetOpen( true )` / `SetOpen( false )` open and close it, **silently**: no Closing, no Closed.
  `IsOpen` answers the logical state at once.
- `SetText( s )` sets the message and opens the bar when `s` has text, closes it when `s` is empty.
  It is the setter a designed form's binding uses.
- **Motion.** Opening and closing animate the height over `TKINFOBAR_ANIM_MS` (150 ms, eased out).
  The content is anchored to the bar's bottom, so it slides in from the edge above. A closing bar
  stays on screen until its height reaches 0. A move can be reversed half way, and it continues
  from where it got to. The bar takes no mouse input while it moves.
  `SetAnimate( false )` lands every open and close at once. `IsAnimating` answers whether it is
  moving.
- **The user closes it** with the close button or Esc. The Closing callback can refuse; Closed
  follows with the reason. A bar that had keyboard focus hands it to the next tab stop before it
  hides.

## In a layout

A docked bar needs its layout to follow its height, which changes on open and close, while it
moves, and when its message wraps to more lines at a narrower width.

- **With tkLayout:** call `tkInfoBar_AttachLayout( bar, l )` after `tkLayout_Add`. It registers
  `tkInfoBar_GetPreferredHeight` as the dock's height function (`tkLayout_SetHeightFunc`), and the bar
  re-runs `tkLayout_Apply( l )` whenever its height changes. Pass `0` to detach. The layout must
  outlive the bar, or be detached first. tkLayout gives a hidden docked control no slice, so a closed
  bar leaves no gap.
- **Without tkLayout:** set `SetHeightChangedCallback`. It receives the bar's new height in design
  units (0 when closed) and places the bar and the content itself.
- `GetPreferredHeight( h, cx )` answers the pixels the bar wants at width `cx`: 0 closed, its full
  height open, and the height it has reached while it moves.

## Layout of the bar

- **LINE**: glyph, title, message (cut with an ellipsis), the actions, then the close button, on one
  row.
- **STACKED**: glyph, title and close on the first row; the message word-wrapped below, at most
  `SetMaxLines` lines (default 3, the rest clipped); the actions on a last row at the text column.
- `SetLayoutMode( TKN_LAYOUT_AUTO )` (default) picks LINE while the title and the message fit
  without cutting, else STACKED. `TKN_LAYOUT_LINE` and `TKN_LAYOUT_STACKED` force one.
  `GetCurrentLayout` answers the one in force.
- `GetPartRect( h, part, rc )` answers a part's rect in bar pixels: `TKN_PART_BODY`,
  `TKN_PART_CLOSE`, `TKN_PART_ACTION1 + id - 1`, `TKN_PART_PROGRESS`.

## Content

- `SetSeverity`: `TKN_INFO` (default), `TKN_SUCCESS`, `TKN_WARNING`, `TKN_ERROR`. It sets the fill,
  the border and the glyph's colour, and the glyph itself: info, a checkmark in a circle, warning,
  error. Any other value is refused.
- `SetTitle`, `SetMessage`, `SetGlyph` ("" returns to the severity's glyph), `SetIconVisible`.
- **Actions.** `AddAction( caption )` returns the action's id (1, 2, …).
  - **Changing them:** `SetActionText`, `SetActionEnabled` (a disabled action does nothing and is
    skipped by Tab), `ClearActions`.
  - **As one text:** `SetActionList( "Retry|Details" )` replaces them all at once (a designed form's
    **Actions** property), and `GetActionList` reads them back.
- `SetClosable( false )` removes the close button, and Esc no longer closes.
- **Progress** — `SetProgress( n )`:
  - 0..100 (clamped) draws a strip in the bar's bottom padding, filled in the severity's colour;
  - `TKN_PROGRESS_INDETERMINATE` moves a segment across it, one pass every 1.5 s;
  - `TKN_PROGRESS_NONE` (default) hides it.

  The strip never changes the bar's height.

## Mouse and keyboard

- A click on an action calls the Action callback with its id. The bar stays open. A press released
  off the button does nothing. A click never takes the focus.
- **Tab stop.** The bar is a tab stop while it is open and has something to press: an enabled
  action, or the close button. `SetTabStop( false )` takes it out of the Tab order.
- **Keys:**
  - **Tab / Shift+Tab** move between its parts; past the last, focus moves on.
  - **Left / Up** and **Right / Down** move between parts inside the bar.
  - **Enter / Space** press the part.
  - **Esc** closes it, if it is closable.

  `GetFocusPart` answers the part a keyboard user is on.
- **The clock** is one widget timer: 15 ms while the bar moves, 30 ms while an open bar shows an
  indeterminate strip, none otherwise. `TickForTest( h, ms )` pins it, for self-tests.

## Notifications

| Callback | When |
| --- | --- |
| `SetActionCallback` | an action is clicked or keyed: `( hBar, id )` |
| `SetClosingCallback` | before a **user** close: `( hBar, reason ) as boolean` — FALSE keeps it open |
| `SetClosedCallback` | after a user close: `( hBar, reason )`, `TKN_CLOSE_BUTTON` or `TKN_CLOSE_KEY` |
| `SetHeightChangedCallback` | the height the bar wants changed: `( hBar, cyDesign )` — a layout signal, so a setter fires it too |

## Colours and theme

`TKNOTIFY_COLORS` (from tkNotify, shared with [tkToast](tkToast)) holds:

- **per severity**, a fill, a border and a glyph colour: `InfoBack`, `InfoBorder`, `InfoGlyph`,
  `SuccessBack` … `ErrorGlyph`;
- **text:** `TitleColor` and `TextColor`;
- **the buttons:** `ButtonBack` (with `Hot` and `Pressed`), `ButtonBorder`, `ButtonText` and
  `ButtonTextDisabled`;
- **the close button:** `CloseBackHot` and `CloseGlyph`;
- **the rest:** `FocusRing`, `ProgressTrack` and `Shadow` (used by toasts).

`tkNotify_ThemeColors( t )` maps them from the theme's roles: info reads `Accent`; the fills are the
surface tinted toward `Success`, `Warning`, `Error` or `Accent`. `SetColors` pins the struct (a
theme change leaves it) until `UnpinColors`. The title is drawn in Inter Bold, and the glyph in the
bundled icon font, each opened on the surface when the host gives none. `ApplyFonts( h, text, title, glyph )`
hands over a form's fonts.

## In the Form Designer

The toolbox's **InfoBar** (Common) has:

- **IsOpen** — on by default. It is a creation choice: a designed bar starts open on the canvas and
  when the form runs. A bar made in code starts closed.
- **Properties:** Severity, Title, Message, Actions (`Retry|Details`), Closable, IconVisible, Glyph,
  LayoutMode, MaxLines, Progress, Animate, TabStop, Font and TitleFont.
- **Events:** Action, Closing (the handler sets `Allow = false` to refuse), Closed and
  HeightChanged.

Dock it at the top. The generated form calls `tkInfoBar_AttachLayout` for you, so the form follows
the bar's height.

**Bind** moves the record field into the message, in only: a field with text opens the bar and an
empty one closes it; SaveTo leaves the field alone. See [Form Designer](Form-Designer), Data
binding.

## Public declarations

### Constants

`TKINFOBAR_ANIM_MS` (150), `TKINFOBAR_MARQUEE_MS` (1500), `TKINFOBAR_TIMER` (the bar's timer id).

From tkNotify:

- **Severities:** `TKN_INFO`, `TKN_SUCCESS`, `TKN_WARNING`, `TKN_ERROR`.
- **Close reasons:** `TKN_CLOSE_BUTTON`, `TKN_CLOSE_ACTION`, `TKN_CLOSE_KEY`, `TKN_CLOSE_SWIPE`,
  `TKN_CLOSE_TIMEOUT`, `TKN_CLOSE_REPLACED` (declared; never reported), `TKN_CLOSE_PROGRAMMATIC`.
- **Layout modes:** `TKN_LAYOUT_AUTO`, `TKN_LAYOUT_LINE`, `TKN_LAYOUT_STACKED`.
- **Progress:** `TKN_PROGRESS_NONE`, `TKN_PROGRESS_INDETERMINATE`.
- **Parts:** `TKN_PART_PROGRESS`, `TKN_PART_NONE`, `TKN_PART_BODY`, `TKN_PART_CLOSE`,
  `TKN_PART_ACTION1`.
- **Glyph:** `TKNOTIFY_GLYPH_SUCCESS` (&hF298, the success glyph).
- **Sizes:** `TKNOTIFY_PADX`, `_PADY`, `_GLYPHCELL`, `_CLOSECELL`, `_MAXLINES` and the others, in
  design units.

### Types

`TKNOTIFY_COLORS` (from tkNotify), and the callback types `IB_ActionCallbackSub`,
`IB_ClosingCallbackFunc`, `IB_ClosedCallbackSub`, `IB_HeightChangedCallbackSub`.

### Procedures

```freebasic
function tkInfoBar_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long, byval bOpen as boolean = false ) as TK_WIDGET ptr
function tkInfoBar_IsOpen( byval hBar as TK_WIDGET ptr ) as boolean
sub tkInfoBar_SetOpen( byval hBar as TK_WIDGET ptr, byval bOpen as boolean )
sub tkInfoBar_SetText( byval hBar as TK_WIDGET ptr, byref s as const ustring )
function tkInfoBar_GetSeverity( byval hBar as TK_WIDGET ptr ) as long
sub tkInfoBar_SetSeverity( byval hBar as TK_WIDGET ptr, byval nSeverity as long )
function tkInfoBar_GetTitle( byval hBar as TK_WIDGET ptr ) as ustring
sub tkInfoBar_SetTitle( byval hBar as TK_WIDGET ptr, byref s as const ustring )
function tkInfoBar_GetMessage( byval hBar as TK_WIDGET ptr ) as ustring
sub tkInfoBar_SetMessage( byval hBar as TK_WIDGET ptr, byref s as const ustring )
function tkInfoBar_GetGlyph( byval hBar as TK_WIDGET ptr ) as ustring
sub tkInfoBar_SetGlyph( byval hBar as TK_WIDGET ptr, byref g as const ustring )
function tkInfoBar_GetIconVisible( byval hBar as TK_WIDGET ptr ) as boolean
sub tkInfoBar_SetIconVisible( byval hBar as TK_WIDGET ptr, byval bVisible as boolean )
function tkInfoBar_GetClosable( byval hBar as TK_WIDGET ptr ) as boolean
sub tkInfoBar_SetClosable( byval hBar as TK_WIDGET ptr, byval bClosable as boolean )
function tkInfoBar_AddAction( byval hBar as TK_WIDGET ptr, byref caption as const ustring ) as long
function tkInfoBar_GetActionCount( byval hBar as TK_WIDGET ptr ) as long
function tkInfoBar_GetActionText( byval hBar as TK_WIDGET ptr, byval id as long ) as ustring
sub tkInfoBar_SetActionText( byval hBar as TK_WIDGET ptr, byval id as long, byref caption as const ustring )
function tkInfoBar_GetActionEnabled( byval hBar as TK_WIDGET ptr, byval id as long ) as boolean
sub tkInfoBar_SetActionEnabled( byval hBar as TK_WIDGET ptr, byval id as long, byval bEnabled as boolean )
sub tkInfoBar_ClearActions( byval hBar as TK_WIDGET ptr )
sub tkInfoBar_SetActionList( byval hBar as TK_WIDGET ptr, byref list_ as const ustring )
function tkInfoBar_GetActionList( byval hBar as TK_WIDGET ptr ) as ustring
function tkInfoBar_GetProgress( byval hBar as TK_WIDGET ptr ) as long
sub tkInfoBar_SetProgress( byval hBar as TK_WIDGET ptr, byval n as long )
function tkInfoBar_GetLayoutMode( byval hBar as TK_WIDGET ptr ) as long
sub tkInfoBar_SetLayoutMode( byval hBar as TK_WIDGET ptr, byval nMode as long )
function tkInfoBar_GetCurrentLayout( byval hBar as TK_WIDGET ptr ) as long
function tkInfoBar_GetMaxLines( byval hBar as TK_WIDGET ptr ) as long
sub tkInfoBar_SetMaxLines( byval hBar as TK_WIDGET ptr, byval n as long )
function tkInfoBar_GetPreferredHeight( byval hBar as TK_WIDGET ptr, byval cx as long ) as long
function tkInfoBar_GetPartRect( byval hBar as TK_WIDGET ptr, byval part as long, byref rc as TKRECT ) as boolean
sub tkInfoBar_AttachLayout( byval hBar as TK_WIDGET ptr, byval l as TK_LAYOUT ptr )
function tkInfoBar_GetAnimate( byval hBar as TK_WIDGET ptr ) as boolean
sub tkInfoBar_SetAnimate( byval hBar as TK_WIDGET ptr, byval bAnimate as boolean )
function tkInfoBar_IsAnimating( byval hBar as TK_WIDGET ptr ) as boolean
function tkInfoBar_GetTabStop( byval hBar as TK_WIDGET ptr ) as boolean
sub tkInfoBar_SetTabStop( byval hBar as TK_WIDGET ptr, byval bTabStop as boolean )
function tkInfoBar_GetFocusPart( byval hBar as TK_WIDGET ptr ) as long
sub tkInfoBar_SetFont( byval hBar as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkInfoBar_GetFont( byval hBar as TK_WIDGET ptr ) as TTF_Font ptr
sub tkInfoBar_SetTitleFont( byval hBar as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkInfoBar_GetTitleFont( byval hBar as TK_WIDGET ptr ) as TTF_Font ptr
sub tkInfoBar_SetGlyphFont( byval hBar as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkInfoBar_ApplyFonts( byval hBar as TK_WIDGET ptr, byval fText as TTF_Font ptr, _
                          byval fTitle as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkInfoBar_SetActionCallback( byval hBar as TK_WIDGET ptr, byval usersub as IB_ActionCallbackSub )
sub tkInfoBar_SetClosingCallback( byval hBar as TK_WIDGET ptr, byval userfunc as IB_ClosingCallbackFunc )
sub tkInfoBar_SetClosedCallback( byval hBar as TK_WIDGET ptr, byval usersub as IB_ClosedCallbackSub )
sub tkInfoBar_SetHeightChangedCallback( byval hBar as TK_WIDGET ptr, byval usersub as IB_HeightChangedCallbackSub )
sub tkInfoBar_ApplyTheme( byval hBar as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkInfoBar_GetColors( byval hBar as TK_WIDGET ptr, byval pColors as TKNOTIFY_COLORS ptr )
sub tkInfoBar_SetColors( byval hBar as TK_WIDGET ptr, byval pColors as TKNOTIFY_COLORS ptr )
sub tkInfoBar_UnpinColors( byval hBar as TK_WIDGET ptr )
sub tkInfoBar_TickForTest( byval hBar as TK_WIDGET ptr, byval nowMs as longint )
function tkInfoBar_GetClockMs( byval hBar as TK_WIDGET ptr ) as long
function tkNotify_ThemeColors( byref t as TKTHEME_COLORS ) as TKNOTIFY_COLORS
```

### See also

- [tkControls](Category-tkControls)
- [tkToast](tkToast), the same severities and look as transient cards
- [tkLayout](tkLayout), docking; [tkHost](tkHost), [tkTheme](tkTheme)
- [Form Designer](Form-Designer), data binding
