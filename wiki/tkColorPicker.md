[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkColorPicker**

# tkColorPicker

Shows a modal colour picker popup and returns the colour and alpha the user chose.

tkColorPicker is a chromeless popup with three tabs: **Web** (the named web colours),
**System** (a table of system colour names) and **Custom** (a colour matrix with red, green, blue
and optional alpha fields). Below the tabs, an Initial and a Current preview and an OK button.
It blocks until the user answers: OK, Enter or a double-click on a colour accepts; Esc or a click
outside cancels.

For the common case, `tkColorPicker_DoModal` (centred) or `tkColorPicker_DoModalForRect`
(dropped under a rectangle, flipping above it when there is no room) does everything in one
call. It returns true with your two variables written, or false with neither touched. For more
control (hiding the alpha field, opening on a tab, live preview while the user drags), create
the picker yourself and call `tkColorPicker_RunModal`.

## Importing

```freebasic
#import "vendor/tkControls/tkColorPicker"

using tkColorPicker
using tkHost
```

The module imports `tkHost`, `tkTheme` and `tkVScrollBar` publicly.

## Example

The one-call form, dropped under the button that asked for it:

```freebasic
dim as TKRECT rcAnchor
tkWidget_AbsRect( hButton, rcAnchor )
if tkColorPicker_DoModalForRect( tkHost_Root( gHost ), rcAnchor, gColor, gAlpha ) then
    tkHost_Invalidate( gHost )            ' gColor and gAlpha hold the new choice
end if
```

The long form, with a live callback and no alpha field:

```freebasic
sub Pick_ColorChanged( byval hCtrl as TK_WIDGET ptr, byval clr as ulong, byval nAlpha as ubyte, byval nPhase as long )
    ' CLR_PHASE_BEGIN, then CLR_PHASE_MOVE while dragging, then CLR_PHASE_END
end sub

dim as TK_WIDGET ptr hPick = tkColorPicker_Create( tkHost_Root( gHost ) )
tkColorPicker_SetFont( hPick, gFont10 )
tkColorPicker_ShowAlpha( hPick, false )
tkColorPicker_SetColor( hPick, gColor, gAlpha )
tkColorPicker_SetTab( hPick, CLR_TAB_CUSTOM )
tkColorPicker_SetColorChangedCallback( hPick, @Pick_ColorChanged )
tkColorPicker_PositionCentered( hPick )
if tkColorPicker_RunModal( hPick ) then
    gColor = tkColorPicker_GetColor( hPick )
    gAlpha = tkColorPicker_GetAlpha( hPick )
end if
tkColorPicker_Destroy( hPick )
```

The handle stays valid after `RunModal`, so the getters answer after the run; call
`tkColorPicker_Destroy` when done. `DoModal` and `DoModalForRect` set no font, so they draw in the
host's default font.

## Concepts

### The handle and the popup

`tkColorPicker_Create( hParent [, id] )` returns a hidden, zero-size widget in the owner's
widget tree. That handle holds all the state: the value, the tab, the colours, the font, the
callbacks. `hParent` can be any widget of the owner window, typically `tkHost_Root` or the button
that opens the picker. Nothing is shown until `tkColorPicker_RunModal`, which creates a fresh popup
surface for that run and closes it when the user answers. The handle outlives the popup, so the
getters still answer after the run, and one handle can be run again. Free it with
`tkColorPicker_Destroy`, or let it go with its owner.

`tkColorPicker_IsOpen` says whether a run is in progress; `tkColorPicker_GetSurface` and
`tkColorPicker_GetContent` return the live popup surface and its content widget, or 0 between
runs.

### The value is a colour and a separate alpha

Colours are `ulong` in `&hAARRGGBB` form (`tkRGB`), and the picker always stores them opaque:
whatever alpha byte you pass in the colour is replaced by `&hFF`. The alpha the user picks travels
separately as a `ubyte`, so committing the Alpha field never disturbs the RGB. That is why
`DoModal` and `DoModalForRect` take two `byref` out-parameters, and why a cancel can leave both
untouched. A new picker starts on opaque black with alpha 255.

### Initial and Current

`tkColorPicker_SetColor` sets both the live value and the "Initial" baseline, unless you pass
`bKeepInitial = true`. The preview box is split across its middle: the top half shows Initial, the
bottom half Current, with the two labels above and below the box. **Clicking the Initial half
reverts** the live value to the baseline; clicking the Current half does nothing.

### Placement

Positions are pixels of the owner window, not screen pixels.
`tkColorPicker_PositionForRect` takes a rectangle from `tkWidget_AbsRect`, drops the popup under
it, and **flips it above** when it does not fit below and there is more room above. A popup
merely clamped upward would cover its own anchor. `tkColorPicker_PositionCentered( h, hRef )`
centres on the widget `hRef`, or on the whole owner window when `hRef` is 0. Both size the popup
to `GetIdealSize` and then clamp it onto the display's work area where the platform reports one;
on Wayland the compositor does the constraining. Neither shows anything.
`tkColorPicker_GetPosition` reports where the popup will open. `RunModal` on a picker that was
never placed centres it on the owner window.

### Geometry is derived, never set

Every rectangle is computed from the layout inputs; there are no rectangle setters. The layout is
lazy: setters mark it stale and the next paint, geometry query or hit test does one pass. Until a
run opens, the layout is computed against the ideal size, so `GetIdealSize`, the rectangle
getters, the hit tests and the probes all answer before the popup has ever been shown.

The popup is the tab strip, the body, and a bottom block of three columns:

```
[ "Initial" label      ]
[ preview, top half    ]   [ Red:   ][field]
[ preview, bottom half ]   [ Green: ][field]
[ "Current" label      ]   [ Blue:  ][field]          [   OK   ]
                           [ Alpha: ][field]
```

The block is as tall as its tallest column, and the preview column is taller than the fields.
So `tkColorPicker_ShowAlpha` adds or removes a whole field row but **does not change the popup's
size**: the row comes and goes inside space the preview already claimed. A hidden field takes no
row. The OK button sits against the right margin with its bottom on the last **visible** field
row, so hiding alpha moves it up.

The popup is as wide as the widest of the body, the bottom block and the tab strip.

### The matrix is a law, not a table

The Custom tab's grid is generated. Lightness runs down the rows as `1 - (row + 0.5) / rows`, hue
runs across the chromatic columns at full saturation, and the last column is a greyscale ramp.
`tkColorPicker_SetMatrixSize` therefore gives a finer or coarser sweep of the same colours, not a
cropped picture. It keeps at least two columns (the last is always the greys) and one row.
`tkColorPicker_MatrixColorAt` is public and pure, so you can generate the same colours yourself.

### Tabs

There are always three. **Web** (137 named colours) and **System** (30 named system colours) are
scrolling lists of rows, a framed swatch followed by the name, sharing one renderer and one hit
test; **Custom** is the matrix. A new picker opens on Custom. Each tab is as wide as its own
caption plus padding, laid left to right, so the strip's right-hand remainder is empty.

The body is a **fixed height across all three tabs**: the taller of the matrix and the visible
list rows. A body that resized as the user browsed would push an already-placed popup off the
display. On a list tab a strip on the right is reserved for the [tkVScrollBar](tkVScrollBar)
whether or not a thumb is needed; the scrollbar itself is shown only when the list overflows.

The System tab is a fixed table of the Windows default system colours, the same on every
platform. `tkColorPicker_SetSystemColor` replaces one entry, process-wide, for a host that wants
live or themed values there.

### Selection follows the value

There is one selection index, shared by whichever tab is showing, and it is re-derived from the
colour whenever the colour, the tab or the matrix size changes. A colour that is not on the
current tab selects nothing rather than snapping to a near match; when a list holds the same
colour twice, the first entry wins. A list scrolls only as far as needed to bring the selected row
into view. Switching tabs starts the list at the top and then scrolls the selection into view.

### Fields and focus

The entry fields are drawn and key-handled by the picker itself: one edit buffer, seeded from the
current value when a field is entered and parsed when it is left. When the popup opens it takes
the keyboard focus, and the caret goes into the Red field. Clicking a field moves the caret there
(committing the field it left); clicking anywhere else commits the field and leaves no field
holding the caret. The cursor is an I-beam over the fields.

## Behaviour and limits

- **There is no Cancel button.** Esc and a press anywhere outside the popup both cancel; the
  outside press is consumed and does not reach the window under it.
- **The application losing focus does not cancel** the picker.
- **The owner is not disabled** while the popup is up; a click on it is how the popup is
  cancelled. "Modal" means the call blocks, not that the rest of the application is inert. If
  the owner is asked to quit during a run, the run ends as a cancel.
- **Accepting commits a half-typed field; cancelling discards it.** A user who types `128` and
  presses OK gets 128. One who types `128` and presses Esc does not, and the typing is not
  carried into the next run.
- **The entry fields are deliberately minimal.** Digits (number row and keypad), Backspace,
  Delete, Left, Right, Home, End, Tab and Enter, and nothing else: no selection, no clipboard, no
  undo. The popup claims every other key while it is up, so nothing leaks to the window behind
  it.
- **There is no hex field.** `tkColorPicker_FormatHex` and `tkColorPicker_ParseHex` are public and
  pure if you want `#RRGGBB` for storage or display.
- **No eyedropper, no palette of your own colours, no typing a colour by name**, although Web and
  System are named lists you pick from.
- **Values clamp, they do not wrap.** A channel field takes at most three digits and is clamped to
  0..255 on commit. An empty field is discarded and the value left alone.
- **A double-click on a body cell accepts**, the mouse's equivalent of Enter. It adopts the cell
  under the pointer and then commits, so double-clicking a cell that is not the selected one
  answers with the one you hit. A double-click anywhere else (a tab, a field, the preview, OK)
  is an ordinary click there and cannot close the popup. On the matrix a rapid second click
  commits rather than starting a second drag.
- **A matrix drag clamps.** Dragging off the grid keeps adopting the nearest edge cell rather than
  stopping.
- **OK is a press-and-release gesture.** Pressing OK arms it; releasing over OK accepts, and
  sliding off before releasing cancels the press without closing the popup.
- **A disabled picker** ignores clicks, the wheel and the keyboard inside the popup, Esc
  included; its tab captions all draw in `TabForeColor`.

## API reference

### Running it

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_DoModal( hParent, byref clr, byref nAlpha ) as boolean` | Creates a picker on `hParent`'s window, starts it on `clr` / `nAlpha` (both also the Initial baseline), centres it on the widget `hParent`, blocks, destroys it. True on OK with both out-parameters written; false on a cancel with **neither** touched. Sets no font and no callbacks. |
| `tkColorPicker_DoModalForRect( hParent, byref rcAnchor, byref clr, byref nAlpha ) as boolean` | The same, dropped under `rcAnchor` (owner window pixels) and flipped above it when it will not fit below. |
| `tkColorPicker_Create( hParent, id = 0 ) as TK_WIDGET ptr` | Creates the hidden handle, without showing anything, so the setters can be reached first. 0 when `hParent` is 0. |
| `tkColorPicker_Destroy( hCtrl )` | Frees the handle and its state; closes the popup if a run is open. |
| `tkColorPicker_RunModal( hCtrl ) as boolean` | Opens the popup, focuses it, calls the open callback, and pumps the host until the user answers. True on OK. Does not destroy the handle. False at once if a run is already open on this handle. |
| `tkColorPicker_EndModal( hCtrl, bAccept )` | Ends the open run as if the user had answered: true accepts (committing a half-typed field first), false cancels. The first answer wins. |
| `tkColorPicker_IsOpen( hCtrl ) as boolean` | Whether a run is open. |
| `tkColorPicker_GetSurface( hCtrl ) as TK_HOST ptr` | The live popup surface, or 0 between runs. |
| `tkColorPicker_GetContent( hCtrl ) as TK_WIDGET ptr` | The popup's content widget, or 0 between runs. |
| `tkColorPicker_PositionForRect( hCtrl, byref rcAnchor )` | Places the popup under `rcAnchor` with the flip-above rule and clamps it to the work area. Does not show. |
| `tkColorPicker_PositionCentered( hCtrl, hRef = 0 )` | Centres the popup on `hRef`, or on the owner window when `hRef` is 0, and clamps it. Does not show. |
| `tkColorPicker_GetPosition( hCtrl, byref x, byref y )` | Where the popup will open, in owner window pixels. |

### Value

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_SetColor( hCtrl, clr, nAlpha = 255, bKeepInitial = false )` | Sets the live value. **Silent.** Also sets the Initial baseline unless `bKeepInitial` is true. |
| `tkColorPicker_GetColor( hCtrl ) as ulong` | The live colour, opaque. |
| `tkColorPicker_GetAlpha( hCtrl ) as ubyte` | The live alpha. |
| `tkColorPicker_SetInitial( hCtrl, clr, nAlpha = 255 )` | Sets the baseline shown as "Initial" without touching the live value. Silent. |
| `tkColorPicker_GetInitial( hCtrl ) as ulong` | The baseline colour. |
| `tkColorPicker_RevertToInitial( hCtrl )` | Sets the live value back to the baseline. An action, not a setter, so it **fires** the change callback with a single `CLR_PHASE_END`. |

### Tabs and fields

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_SetTab( hCtrl, nTab )` | Selects a tab. **Silent.** Ignores anything outside `CLR_TAB_WEB`..`CLR_TAB_CUSTOM`. Starts the list at the top and re-derives the selection. |
| `tkColorPicker_GetTab( hCtrl ) as long` | The current tab. |
| `tkColorPicker_ShowAlpha( hCtrl, bShow )` | Shows or hides the Alpha field row. **Shown by default.** Hiding it while the caret is in it commits that field first. Moves OK, but does not change the popup's size. |
| `tkColorPicker_IsAlphaShown( hCtrl ) as boolean` | Whether the Alpha row is shown. |
| `tkColorPicker_GetFocusField( hCtrl ) as long` | The field holding the caret (`CLR_FIELD_*`), or -1. |
| `tkColorPicker_GetEditText( hCtrl ) as ustring` | The in-progress text of that field. |
| `tkColorPicker_GetBodySel( hCtrl ) as long` | The selected body cell on the current tab, or -1. |
| `tkColorPicker_GetScrollTop( hCtrl ) as long` | The list's first visible row. |
| `tkColorPicker_TabName( idx ) as ustring` | The caption on tab `idx` (`"Web"`, `"System"`, `"Custom"`); `""` out of range. The strip measures this to size each tab. |

### Appearance

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_SetColors( hCtrl, pColors )` | Copies your `TKCOLORPICKER_COLORS` in and pins them. See *Colours*. |
| `tkColorPicker_GetColors( hCtrl, pColors )` | Copies the colours in force out. |
| `tkColorPicker_ThemeColors( t ) as TKCOLORPICKER_COLORS` | The theme mapping, as a value. |
| `tkColorPicker_ApplyTheme( hCtrl, t )` | Applies a theme to an unpinned picker. |
| `tkColorPicker_UnpinColors( hCtrl )` | Hands the colours back to the theme and applies it at once. |
| `tkColorPicker_SetFont( hCtrl, f )` | Sets the text font, a `TTF_Font ptr`. **You keep ownership.** Re-measures, because the tab strip is as wide as its captions. |
| `tkColorPicker_GetFont( hCtrl ) as TTF_Font ptr` | The font, or 0 if none was set; the host's default font is then used. |
| `tkColorPicker_ApplyFonts( hCtrl, fText, fGlyph )` | Sets `fText` as the font when it is not 0. There is no glyph font, so `fGlyph` is ignored. |
| `tkColorPicker_SetOKText( hCtrl, Text )` | The OK button's caption (default `"OK"`). |
| `tkColorPicker_SetPreviewText( hCtrl, TextInitial, TextCurrent )` | The two preview labels (default `"Initial"`, `"Current"`). |
| `tkColorPicker_SetFieldText( hCtrl, nField, Text )` | The label beside one field, in `CLR_FIELD_*` order. The defaults carry their colon (`"Red:"`, `"Green:"`, `"Blue:"`, `"Alpha:"`); nothing is appended, so omit it if you do not want one. |
| `tkColorPicker_GetFieldText( hCtrl, nField ) as ustring` | That label; `""` out of range. |
| `tkColorPicker_Refresh( hCtrl )` | Marks the layout stale and repaints. |

### State

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_SetEnabled( hCtrl, bEnabled )` | Enables or disables the picker. Disabling clears hover and ends a drag; while a run is open it goes through `tkWidget_Enable` on the popup's content, so the host enforces it. |
| `tkColorPicker_GetEnabled( hCtrl ) as boolean` | Whether the picker is enabled. |
| `tkColorPicker_GetFocused( hCtrl ) as boolean` | Whether the popup has the keyboard focus. |

### Geometry and layout

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_GetIdealSize( hCtrl, byref cx, byref cy )` | The size the popup wants. **Valid before the popup is ever shown**, which is what the placement routines rely on. Varies with the matrix and cell size and with the font; does **not** vary with `ShowAlpha`. |
| `tkColorPicker_GetMatrixSize( hCtrl, byref nCols, byref nRows )` | The Custom grid's dimensions (16 x 14 by default). |
| `tkColorPicker_SetMatrixSize( hCtrl, nCols, nRows )` | Sets them, at least 2 x 1. Silent; re-derives the selection and re-measures, so the ideal size changes. |
| `tkColorPicker_GetCellSize( hCtrl, byref cx, byref cy )` | One matrix cell, in pixels. |
| `tkColorPicker_SetCellSize( hCtrl, cx, cy )` | Sets it, at least 1 x 1. Silent, and re-measures. Pixels at the current scale. |
| `tkColorPicker_GetPartRect( hCtrl, nPart, byref rc ) as boolean` | A `CLR_PART_*` rectangle. False means the part is legitimately empty: `CLR_PART_MATRIX` off Custom, `CLR_PART_SWATCHES` on Custom, `CLR_PART_ALPHA` with alpha hidden. |
| `tkColorPicker_GetFieldRect( hCtrl, nField, byref rc ) as boolean` | One field's box. False when the field is not shown. |
| `tkColorPicker_GetTabRect( hCtrl, idx, byref rc ) as boolean` | One tab cell. |

### Hit tests

All take popup client coordinates, the same coordinates the rectangle getters return.

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_HitTestTab( hCtrl, x, y ) as long` | Tab index, or -1. |
| `tkColorPicker_HitTestField( hCtrl, x, y ) as long` | `CLR_FIELD_*`, or -1. Only shown fields are reachable. |
| `tkColorPicker_HitTestBody( hCtrl, x, y ) as long` | The body cell index, or -1. On Custom that is `row * cols + col`; on a list tab it is the entry index, and a partial row past the bottom of the list is **not** hit-testable. |

### Colour tables

The two fixed lists, exposed so you can offer the same colours elsewhere. An out-of-range index
gives 0 or `""` rather than failing.

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_WebColorCount() as long` | How many named web colours there are (137). |
| `tkColorPicker_WebColorAt( idx ) as ulong` | One of them, opaque. |
| `tkColorPicker_WebColorName( idx ) as ustring` | Its name. |
| `tkColorPicker_SystemColorCount() as long` | How many system colours there are (30). |
| `tkColorPicker_SystemColorAt( idx ) as ulong` | One of them, opaque, from the fixed table or a `SetSystemColor` override. |
| `tkColorPicker_SystemColorName( idx ) as ustring` | Its name. |
| `tkColorPicker_SetSystemColor( idx, clr )` | Replaces one System entry for every picker in the process. Out of range is ignored. |

### Pure helpers

No picker needed; safe to call before anything is created.

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_HSLtoRGB( h, s, lum ) as ulong` | HSL (each 0..1) to an opaque colour. Every axis **clamps** out-of-range input rather than wrapping, so a hue of 1.4 does not become 0.4. |
| `tkColorPicker_MatrixColorAt( nCol, nRow, nCols, nRows ) as ulong` | The colour the matrix law puts at that cell. Indices clamp. |
| `tkColorPicker_MatrixIndexOf( clr, nCols, nRows ) as long` | The cell index (`row * cols + col`) holding `clr`, or -1. |
| `tkColorPicker_CellFromPoint( rc, nCellW, nCellH, nCols, nRows, x, y, byref nCol, byref nRow ) as boolean` | Point to grid cell. False, with both set to -1, when the point is outside the grid. |
| `tkColorPicker_FormatHex( clr ) as ustring` | `#RRGGBB`, upper case. |
| `tkColorPicker_ParseHex( wszText, byref clr ) as boolean` | Reads `#RRGGBB` with or without the `#`, either case. False, leaving `clr` alone, on empty, short, long or non-hex input. |
| `tkColorPicker_ContrastColor( clr ) as ulong` | Black or white, whichever is legible on `clr`. |
| `tkColorPicker_FieldAccepts( nField, ch, nPos ) as boolean` | Whether a field would take that character. Digits only; `nPos` never affects the answer. An out-of-range field accepts nothing. |
| `tkColorPicker_FieldMaxLen( nField ) as long` | How long a field may get: three digits. |
| `tkColorPicker_PtIn( rc, x, y ) as boolean` | Half-open containment: left and top inclusive, right and bottom exclusive, matching the grid arithmetic. |

### Callback registration and painting

Passing 0 to any setter removes that callback.

| Function | Behaviour |
| --- | --- |
| `tkColorPicker_SetColorChangedCallback( hCtrl, usersub )` | See *Callbacks*. |
| `tkColorPicker_SetTabChangedCallback( hCtrl, usersub )` | See *Callbacks*. |
| `tkColorPicker_SetMessageCallback( hCtrl, userfunc )` | See *Callbacks*. |
| `tkColorPicker_SetOpenCallback( hCtrl, usersub )` | See *Callbacks*. |
| `tkColorPicker_SetPaintCallback( hCtrl, usersub )` | Replaces the built-in painter wholesale; 0 restores it. |
| `tkColorPicker_RenderInfo( p )` | Runs the **built-in** painter into the buffer your paint callback was handed. Pass it the same pointer. This is what lets you decorate rather than replace. |
| `tkColorPicker_CountRenderedTones( hCtrl, nPart ) as long` | Renders the picker through the real paint path (into the popup's back buffer while a run is open, otherwise into the owner's at its top-left, with focus and the caret forced on) and counts the distinct colours in one part, capped at 64. 0 when the part is empty. Lets you assert a paint callback has not flooded the picker: a flooded part is one tone. |
| `tkColorPicker_HashRenderedPart( hCtrl, nPart ) as ulong` | The same render, hashed, so you can assert a state change actually reached the pixels. |

## Colours

Fill a `TKCOLORPICKER_COLORS` and hand it to `tkColorPicker_SetColors`. These paint the popup's
own chrome; the colours it is *editing* are content and are never themed.

| Field | Paints | When | Theme role |
| --- | --- | --- | --- |
| `BackColor` | The popup's background, and a list row's background. | Always; a list row when neither selected nor hovered. | `Popup` |
| `ForeColor` | Field labels, the two preview labels, and list row names. | Always; a list name when neither selected nor hovered. | `Text` |
| `BorderColor` | The popup's frame, the frame around the preview box, and each list swatch's frame. | Always. | `Border` |
| `TabBackColor` | A tab cell's background. | An unselected, unhovered tab. | `Popup` |
| `TabBackColorSel` | A tab cell's background, and a list row's background. | The selected tab and the hovered one; the hovered list row. | `SurfaceHot` |
| `TabForeColor` | A tab caption. | An unselected tab, and every tab while the picker is disabled. | `TextDim` |
| `TabForeColorSel` | A tab caption, and a list row's name. | The selected tab; the hovered list row. | `TextHot` |
| `FieldBackColor` | An entry field's box. | Always. | `Window` |
| `FieldForeColor` | The text and caret in an entry field. | Always. | `Text` |
| `FieldBorderColor` | An entry field's frame. | A field without the caret. | `Border` |
| `FieldBorderColorSel` | An entry field's frame. | The field holding the caret. | `FocusRing` |
| `HotRingColor` | The ring around a matrix cell. | The cell under the pointer. | `TextStrong` |
| `SelRingColor` | The ring around a matrix cell, the selected list row's background, and the rule under the selected tab. | The selected cell or row. | `FocusRing` |
| `FocusRingColor` | A ring around the whole content area. | The popup has focus and **no** field holds the caret. | `FocusRing` |
| `OKBackColor` | The OK button's fill. | Idle. | `Surface` |
| `OKBackColorHot` | The OK button's fill. | Pointer over it. | `SurfaceHot` |
| `OKBackColorPressed` | The OK button's fill. | Held down with the pointer still on it. | `Selected` |
| `OKForeColor` | The OK button's caption. | Always. | `Text` |
| `OKBorderColor` | The OK button's frame. | Always. | `Border` |

The selected list row's name is drawn in black or white, whichever `tkColorPicker_ContrastColor`
picks for `SelRingColor`. On the matrix the selected ring wins over the hover ring. The OK
button's fill resolves **pressed > hot > idle**; there is no disabled pair, because OK is never
disabled.

The picker takes its colours from the current theme when it is created (including any theme
recipe for `"ColorPicker"`) and follows every theme change. `tkColorPicker_SetColors` pins the
colours, so a theme change leaves this picker alone; `tkColorPicker_UnpinColors` hands it back to
the theme and applies the theme at once. `tkColorPicker_GetColors` reads the colours in force,
`tkColorPicker_ThemeColors` gives the theme mapping as a value, and `tkColorPicker_ApplyTheme`
applies a given theme to an unpinned picker. The `TKCOLORPICKER_COLORS` field defaults are a dark
scheme, used only when you fill the type yourself.

## Callbacks

All are optional and are reachable only through `Create` + `RunModal`; `DoModal` has nowhere to
take one. Every callback receives the handle, not the popup.

### Value changed

```freebasic
type CLR_ColorChangedCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval clr as ulong, byval nAlpha as ubyte, byval nPhase as long )
```

Fires for **user action only**, plus `tkColorPicker_RevertToInitial`. Every programmatic setter is
silent, which is what lets you call `tkColorPicker_SetColor` from inside this callback without
re-entering.

`nPhase` makes live preview possible. Dragging across the matrix emits one `CLR_PHASE_BEGIN`
(on the press), a `CLR_PHASE_MOVE` for every pointer move (which can repeat the previous colour)
and one `CLR_PHASE_END` on the release. A click on a list row, a committed field that changed the
value, an arrow key in the body, a click on the Initial half that changes the value, and a
double-click on a cell each emit a single `CLR_PHASE_END`. Coalesce the moves; commit on the end.

**If a drag is abandoned because the pointer capture is taken away, no `END` is sent.** Abandoned
is not finished, and an invented `END` would report a colour the user was merely passing over.
Treat a missing `END` as a cancel.

You do not need this callback if you only want the final answer; `RunModal` and `DoModal` report
that themselves.

### Tab changed

```freebasic
type CLR_TabChangedCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval nTab as long )
```

Fires when the **user** clicks a different tab. `tkColorPicker_SetTab` is silent.

### Open

```freebasic
type CLR_OpenCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval pSurface as TK_HOST ptr )
```

Fires once per run, after the popup is on screen and focused and before it reads its first event.
`pSurface` is the live popup surface: the place to reach it, or to queue events at it from a
test.

### Message observer

```freebasic
type CLR_MessageCallbackFunc as function( byval m as TKCOLORPICKER_MESSAGEINFO ptr ) as boolean
```

Sees the popup's input. For `TKM_LBUTTONDOWN`, `TKM_KEYDOWN` and `TKM_MOUSEWHEEL` the callback
runs before the picker acts, and returning true suppresses the picker's own handling (so it can,
for instance, swallow Esc). `TKM_MOUSEMOVE`, `TKM_MOUSELEAVE`, `TKM_RBUTTONDOWN` and
`TKM_RBUTTONUP` are reported after the picker has handled them, and the result does not matter.

**The result is ignored for three messages**, and the reasons are worth knowing:

- `TKM_LBUTTONUP` ends the matrix drag and the OK press and releases the pointer capture they
  hold. Suppressing it would strand the capture.
- `TKM_SETFOCUS` and `TKM_KILLFOCUS` report focus; they are facts, not actions to veto.
  `TKM_KILLFOCUS` is also what commits a half-typed field.

| `TKCOLORPICKER_MESSAGEINFO` field | Meaning |
| --- | --- |
| `hColorPicker` | The handle. |
| `msg` | The message, a `TKM_*`. |
| `x`, `y` | The pointer position, in popup client coordinates. |
| `key` | The key, for a key message. |
| `mods` | The modifier keys. |
| `clicks` | The click count; 2 or more is a double-click. |

### Painting

```freebasic
type CLR_PaintCallbackSub as sub( byval p as any ptr )
```

Cast `p` to a `TKCOLORPICKER_PAINTINFO ptr`. The picker has already filled the client with
`BackColor` before calling you.

**Do not use `PaintBorderRect` to draw an outline.** It fills before it strokes, so used as a
frame it erases everything beneath it. `PaintRoundOutline` strokes without filling. More
generally: draw your additions, not a background. `tkColorPicker_CountRenderedTones` exists so you
can assert you have not flooded the picker.

To decorate rather than replace, call `tkColorPicker_RenderInfo( p )` first and then add your own
drawing on top:

```freebasic
sub MyPickerPaint( byval p as any ptr )
    dim as TKCOLORPICKER_PAINTINFO ptr pinf = cast( TKCOLORPICKER_PAINTINFO ptr, p )
    if pinf->b = 0 then exit sub

    tkColorPicker_RenderInfo( p )

    dim as TKRECT rc = pinf->rcBody
    tkRect_Inflate( rc, 2, 2 )
    pinf->b->SetPenColor( tkRGB( 86, 156, 214 ) )
    pinf->b->PaintRoundOutline( @rc, 6, 1 )
end sub
```

Every rectangle below is precomputed; never re-derive one from another.

| `TKCOLORPICKER_PAINTINFO` field | Meaning |
| --- | --- |
| `hColorPicker` | The handle, so you can query it. |
| `b` | The `TK_PAINT` for this repaint. Draw into it. |
| `rcClient` | The whole popup client area. |
| `rcContent` | `rcClient` less the padding. |
| `rcTabs` | The whole tab strip. The tabs themselves do not fill it. |
| `rcBody` | The tab's content area. Fixed height across all tabs. |
| `rcMatrix` | The grid, or **empty** when not on Custom. |
| `rcSwatches` | The list area, scrollbar strip excluded, or **empty** on Custom. |
| `rcOK` | The OK button. |
| `rcPreview` | The whole split preview box. |
| `rcInitial` | Its top half, the baseline. |
| `rcCurrent` | Its bottom half, the live value. |
| `rcInitialLabel` | The "Initial" label, **above** the box. |
| `rcCurrentLabel` | The "Current" label, **below** the box. |
| `rcFields` | The entry block: from the field labels to the right edge of the field boxes. |
| `rcAlpha` | The Alpha field's box, or **empty** when alpha is hidden. |
| `clrCurrent` | The live colour. |
| `nAlphaCurrent` | The live alpha. |
| `clrInitial` | The baseline colour. |
| `nAlphaInitial` | The baseline alpha. |
| `nTab` | `CLR_TAB_*`. |
| `isEnabled` | Whether the picker is enabled. |
| `isFocused` | Whether the popup has focus. |
| `isDragging` | A matrix drag is in progress. |
| `isOKHot` | The pointer is over OK. |
| `isOKPressed` | OK is held down. |
| `nFocusField` | `CLR_FIELD_*`, or -1 when no field holds the caret. |

`rcMatrix` and `rcSwatches` are **mutually exclusive**, so you can branch on `tkRect_IsEmpty`
instead of re-implementing the tab-to-body mapping.

## Keyboard and mouse

| Input | Effect |
| --- | --- |
| `Esc` | Cancels, from anywhere. `DoModal` returns false and your variables are untouched. Does **not** commit a half-typed field. |
| `Enter` (or keypad Enter) | With the caret in a field: commits it, clamps it, re-seeds it so the user sees what `999` became, and stays there. Otherwise: accepts, exactly as OK does. The popup opens with the caret in Red, so a bare Enter right after opening commits that field rather than accepting. |
| `Tab` / `Shift+Tab` | In a field: walks the shown fields, **wrapping** at both ends; a hidden Alpha field is skipped. Outside a field: puts the caret in the first field. |
| `Left` / `Right` | In a field: moves the caret. Otherwise: moves the body selection by one cell and adopts that colour. |
| `Up` / `Down` | Outside a field: moves the body selection by one row, one list row or one whole row of matrix cells. Body moves clamp at the ends, and start at the first cell when nothing is selected. |
| `Home` / `End` | Moves the caret within a field. |
| `Backspace` / `Delete` | Edits the field. |
| Digits | Typed into the field holding the caret, from the number row or the keypad. The first digit after entering a field replaces the seeded value; any editing key (arrows, Home, End, Backspace, Delete) switches to amending it. |
| Click | On a tab: switches to it. On a field: puts the caret there. On a list row: adopts that colour. On the matrix: adopts the cell and starts a drag. On the Initial half: reverts. On OK: arms the press. |
| Double-click | On a body cell: adopts it and accepts. Anywhere else: an ordinary click. |
| Mouse wheel | Scrolls the list on the Web and System tabs. |
| Click outside | Cancels; the press is consumed. |

## Constants

### Tabs

| Constant | Value |
| --- | --- |
| `CLR_TAB_WEB` | 0 |
| `CLR_TAB_SYSTEM` | 1 |
| `CLR_TAB_CUSTOM` | 2 |
| `CLR_TAB_COUNT` | 3 |

### Change phases

| Constant | Meaning |
| --- | --- |
| `CLR_PHASE_BEGIN` | A drag started. |
| `CLR_PHASE_MOVE` | One step of a drag. |
| `CLR_PHASE_END` | A settled value. |

### Parts

`CLR_PART_TABS`, `CLR_PART_MATRIX`, `CLR_PART_SWATCHES`, `CLR_PART_INITIAL`, `CLR_PART_CURRENT`,
`CLR_PART_FIELDS`, `CLR_PART_ALPHA`, `CLR_PART_OK`.

### Fields

`CLR_FIELD_R` (0), `CLR_FIELD_G`, `CLR_FIELD_B`, `CLR_FIELD_A`, `CLR_FIELD_COUNT` (4). The enum
order is the visual order, top to bottom, and the Tab order. `CLR_FIELD_A` keeps its id whether or
not the row is shown.

### Defaults, in unscaled pixels

The picker scales these by the host's scale factor when it is created, and rescales every size in
proportion when a `TKM_SCALECHANGED` arrives, including sizes you set. `SetCellSize` takes pixels
at the current scale.

| Constant | Default | Meaning |
| --- | --- | --- |
| `TKCOLORPICKER_DEFAULT_PAD` | 8 | Padding around the content. |
| `TKCOLORPICKER_DEFAULT_GAP` | 6 | Gap between blocks and between field rows. |
| `TKCOLORPICKER_DEFAULT_TABHEIGHT` | 24 | Tab strip height. |
| `TKCOLORPICKER_DEFAULT_TABPAD` | 14 | Padding either side of a tab's caption. |
| `TKCOLORPICKER_DEFAULT_MATRIXCOLS` | 16 | Matrix columns. |
| `TKCOLORPICKER_DEFAULT_MATRIXROWS` | 14 | Matrix rows. |
| `TKCOLORPICKER_DEFAULT_CELLW` | 18 | Matrix cell width. |
| `TKCOLORPICKER_DEFAULT_CELLH` | 22 | Matrix cell height. |
| `TKCOLORPICKER_DEFAULT_SWATCHW` | 34 | Swatch width in a list row. |
| `TKCOLORPICKER_DEFAULT_LISTROWS` | 14 | Visible list rows. |
| `TKCOLORPICKER_DEFAULT_SCROLLW` | 14 | Scrollbar strip width. |
| `TKCOLORPICKER_DEFAULT_PREVIEWW` | 92 | Preview box width. |
| `TKCOLORPICKER_DEFAULT_PREVIEWH` | 46 | Height of **one half** of the preview box. |
| `TKCOLORPICKER_DEFAULT_FIELDW` | 58 | Entry field width. |
| `TKCOLORPICKER_DEFAULT_FIELDH` | 24 | Entry field height. |
| `TKCOLORPICKER_DEFAULT_OKW` | 92 | OK button width. |
| `TKCOLORPICKER_DEFAULT_OKH` | 30 | OK button height. |
| `TKCOLORPICKER_DEFAULT_LABELW` | 52 | Field label gutter. |
| `TKCOLORPICKER_DEFAULT_ROWH` | 22 | List row height, and each preview label row. |
| `TKCOLORPICKER_DEFAULT_CURVATURE` | 4 | Corner rounding of the fields, OK and the focus ring, as an ellipse diameter. |
| `TKCOLORPICKER_DEFAULT_BORDERTHICK` | 1 | Border pen width. Never scaled. |
| `TKCOLORPICKER_DEFAULT_FOCUSTHICK` | 1 | Focus ring pen width. Never scaled. |
| `TKCOLORPICKER_RINGINSET` | 1 | How far a matrix cell's hot or selected ring is inset into the cell. |
| `TKCOLORPICKER_CARET_MS` | 530 | The field caret's blink interval, in milliseconds. |

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKCOLORPICKER_DEFAULT_PAD = 8
const TKCOLORPICKER_DEFAULT_GAP = 6
const TKCOLORPICKER_DEFAULT_TABHEIGHT = 24
const TKCOLORPICKER_DEFAULT_MATRIXCOLS = 16
const TKCOLORPICKER_DEFAULT_MATRIXROWS = 14
const TKCOLORPICKER_DEFAULT_CELLW = 18
const TKCOLORPICKER_DEFAULT_CELLH = 22
const TKCOLORPICKER_DEFAULT_SWATCHW = 34
const TKCOLORPICKER_DEFAULT_LISTROWS = 14
const TKCOLORPICKER_DEFAULT_SCROLLW = 14
const TKCOLORPICKER_DEFAULT_PREVIEWW = 92
const TKCOLORPICKER_DEFAULT_PREVIEWH = 46
const TKCOLORPICKER_DEFAULT_FIELDW = 58
const TKCOLORPICKER_DEFAULT_FIELDH = 24
const TKCOLORPICKER_DEFAULT_OKW = 92
const TKCOLORPICKER_DEFAULT_OKH = 30
const TKCOLORPICKER_DEFAULT_LABELW = 52
const TKCOLORPICKER_DEFAULT_ROWH = 22
const TKCOLORPICKER_DEFAULT_TABPAD = 14
const TKCOLORPICKER_DEFAULT_CURVATURE = 4
const TKCOLORPICKER_DEFAULT_BORDERTHICK = 1 ' never scaled
const TKCOLORPICKER_DEFAULT_FOCUSTHICK = 1 ' never scaled
const TKCOLORPICKER_RINGINSET = 1
const TKCOLORPICKER_CARET_MS = 530

enum
    CLR_TAB_WEB = 0
    CLR_TAB_SYSTEM
    CLR_TAB_CUSTOM
    CLR_TAB_COUNT
end enum

enum
    CLR_PHASE_BEGIN = 0
    CLR_PHASE_MOVE
    CLR_PHASE_END
end enum

enum
    CLR_PART_TABS = 0
    CLR_PART_MATRIX
    CLR_PART_SWATCHES
    CLR_PART_INITIAL
    CLR_PART_CURRENT
    CLR_PART_FIELDS
    CLR_PART_ALPHA
    CLR_PART_OK
end enum

enum
    CLR_FIELD_R = 0
    CLR_FIELD_G
    CLR_FIELD_B
    CLR_FIELD_A
    CLR_FIELD_COUNT
end enum
```

### Types

```freebasic
type TKCOLORPICKER_COLORS
    BackColor           as ulong = &hFF2C313Aul
    ForeColor           as ulong = &hFFC8CDD6ul
    BorderColor         as ulong = &hFF444A56ul
    TabBackColor        as ulong = &hFF2C313Aul
    TabBackColorSel     as ulong = &hFF373D48ul
    TabForeColor        as ulong = &hFF969CA7ul
    TabForeColorSel     as ulong = &hFFE2E6EEul
    FieldBackColor      as ulong = &hFF21252Bul
    FieldForeColor      as ulong = &hFFC8CDD6ul
    FieldBorderColor    as ulong = &hFF444A56ul
    FieldBorderColorSel as ulong = &hFF61AFEFul
    HotRingColor        as ulong = &hFFFFFFFFul
    SelRingColor        as ulong = &hFF61AFEFul
    FocusRingColor      as ulong = &hFF61AFEFul
    OKBackColor         as ulong = &hFF373D48ul
    OKBackColorHot      as ulong = &hFF444A56ul
    OKBackColorPressed  as ulong = &hFF282D35ul
    OKForeColor         as ulong = &hFFE2E6EEul
    OKBorderColor       as ulong = &hFF444A56ul
end type

type TKCOLORPICKER_PAINTINFO
    hColorPicker   as TK_WIDGET ptr      ' the handle, so the callback can query it
    b              as TK_PAINT ptr
    rcClient       as TKRECT
    rcContent      as TKRECT
    rcTabs         as TKRECT
    rcBody         as TKRECT
    rcMatrix       as TKRECT             ' EMPTY off Custom
    rcSwatches     as TKRECT             ' EMPTY on Custom
    rcOK           as TKRECT
    rcPreview      as TKRECT
    rcInitial      as TKRECT
    rcCurrent      as TKRECT
    rcInitialLabel as TKRECT
    rcCurrentLabel as TKRECT
    rcFields       as TKRECT
    rcAlpha        as TKRECT
    clrCurrent     as ulong
    nAlphaCurrent  as ubyte
    clrInitial     as ulong
    nAlphaInitial  as ubyte
    nTab           as long
    isEnabled      as boolean
    isFocused      as boolean
    isDragging     as boolean
    isOKHot        as boolean
    isOKPressed    as boolean
    nFocusField    as long
end type

type TKCOLORPICKER_MESSAGEINFO
    hColorPicker  as TK_WIDGET ptr
    msg           as long               ' TKM_*
    x             as single
    y             as single
    key           as long
    mods          as long
    clicks        as long
end type

type TKCOLORPICKER_STATE   ' per-instance state; reach it through the procedures

type CLR_ColorChangedCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval clr as ulong, byval nAlpha as ubyte, byval nPhase as long )
type CLR_TabChangedCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval nTab as long )
type CLR_MessageCallbackFunc as function( byval m as TKCOLORPICKER_MESSAGEINFO ptr ) as boolean
type CLR_PaintCallbackSub as sub( byval p as any ptr )
type CLR_OpenCallbackSub as sub( byval hCtrl as TK_WIDGET ptr, byval pSurface as TK_HOST ptr )
```

### Procedures

```freebasic
function tkColorPicker_HSLtoRGB( byval h as double, byval s as double, byval lum as double ) as ulong
function tkColorPicker_MatrixColorAt( byval nCol as long, byval nRow as long, byval nCols as long, byval nRows as long ) as ulong
function tkColorPicker_MatrixIndexOf( byval clr as ulong, byval nCols as long, byval nRows as long ) as long
function tkColorPicker_PtIn( byref rc as TKRECT, byval x as long, byval y as long ) as boolean
function tkColorPicker_CellFromPoint( byref rc as TKRECT, byval nCellW as long, byval nCellH as long, byval nCols as long, byval nRows as long, byval x as long, byval y as long, byref nCol as long, byref nRow as long ) as boolean
function tkColorPicker_FormatHex( byval clr as ulong ) as ustring
function tkColorPicker_ParseHex( byval wszText as ustring, byref clr as ulong ) as boolean
function tkColorPicker_ContrastColor( byval clr as ulong ) as ulong
function tkColorPicker_FieldAccepts( byval nField as long, byval ch as long, byval nPos as long ) as boolean
function tkColorPicker_FieldMaxLen( byval nField as long ) as long
function tkColorPicker_TabName( byval idx as long ) as ustring
function tkColorPicker_WebColorCount() as long
function tkColorPicker_WebColorAt( byval idx as long ) as ulong
function tkColorPicker_WebColorName( byval idx as long ) as ustring
function tkColorPicker_SystemColorCount() as long
function tkColorPicker_SystemColorAt( byval idx as long ) as ulong
function tkColorPicker_SystemColorName( byval idx as long ) as ustring
sub tkColorPicker_SetSystemColor( byval idx as long, byval clr as ulong )
function tkColorPicker_Create( byval hParent as TK_WIDGET ptr, byval id as long = 0 ) as TK_WIDGET ptr
sub tkColorPicker_Destroy( byval hCtrl as TK_WIDGET ptr )
sub tkColorPicker_PositionForRect( byval hCtrl as TK_WIDGET ptr, byref rcAnchor as TKRECT )
sub tkColorPicker_PositionCentered( byval hCtrl as TK_WIDGET ptr, byval hRef as TK_WIDGET ptr = 0 )
sub tkColorPicker_GetPosition( byval hCtrl as TK_WIDGET ptr, byref x as long, byref y as long )
function tkColorPicker_RunModal( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkColorPicker_DoModal( byval hParent as TK_WIDGET ptr, byref clr as ulong, byref nAlpha as ubyte ) as boolean
function tkColorPicker_DoModalForRect( byval hParent as TK_WIDGET ptr, byref rcAnchor as TKRECT, byref clr as ulong, byref nAlpha as ubyte ) as boolean
sub tkColorPicker_EndModal( byval hCtrl as TK_WIDGET ptr, byval bAccept as boolean )
function tkColorPicker_IsOpen( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkColorPicker_GetSurface( byval hCtrl as TK_WIDGET ptr ) as TK_HOST ptr
function tkColorPicker_GetContent( byval hCtrl as TK_WIDGET ptr ) as TK_WIDGET ptr
sub tkColorPicker_SetColor( byval hCtrl as TK_WIDGET ptr, byval clr as ulong, byval nAlpha as ubyte = 255, byval bKeepInitial as boolean = false )
function tkColorPicker_GetColor( byval hCtrl as TK_WIDGET ptr ) as ulong
function tkColorPicker_GetAlpha( byval hCtrl as TK_WIDGET ptr ) as ubyte
sub tkColorPicker_SetInitial( byval hCtrl as TK_WIDGET ptr, byval clr as ulong, byval nAlpha as ubyte = 255 )
function tkColorPicker_GetInitial( byval hCtrl as TK_WIDGET ptr ) as ulong
sub tkColorPicker_RevertToInitial( byval hCtrl as TK_WIDGET ptr )
sub tkColorPicker_ShowAlpha( byval hCtrl as TK_WIDGET ptr, byval bShow as boolean )
function tkColorPicker_IsAlphaShown( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkColorPicker_SetTab( byval hCtrl as TK_WIDGET ptr, byval nTab as long )
function tkColorPicker_GetTab( byval hCtrl as TK_WIDGET ptr ) as long
sub tkColorPicker_SetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKCOLORPICKER_COLORS ptr )
sub tkColorPicker_GetColors( byval hCtrl as TK_WIDGET ptr, byval pColors as TKCOLORPICKER_COLORS ptr )
function tkColorPicker_ThemeColors( byref t as TKTHEME_COLORS ) as TKCOLORPICKER_COLORS
sub tkColorPicker_ApplyTheme( byval hCtrl as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkColorPicker_UnpinColors( byval hCtrl as TK_WIDGET ptr )
sub tkColorPicker_SetFont( byval hCtrl as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkColorPicker_GetFont( byval hCtrl as TK_WIDGET ptr ) as TTF_Font ptr
sub tkColorPicker_ApplyFonts( byval hCtrl as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkColorPicker_SetOKText( byval hCtrl as TK_WIDGET ptr, byval Text as ustring )
sub tkColorPicker_SetPreviewText( byval hCtrl as TK_WIDGET ptr, byval TextInitial as ustring, byval TextCurrent as ustring )
sub tkColorPicker_SetFieldText( byval hCtrl as TK_WIDGET ptr, byval nField as long, byval Text as ustring )
function tkColorPicker_GetFieldText( byval hCtrl as TK_WIDGET ptr, byval nField as long ) as ustring
sub tkColorPicker_Refresh( byval hCtrl as TK_WIDGET ptr )
function tkColorPicker_GetEnabled( byval hCtrl as TK_WIDGET ptr ) as boolean
sub tkColorPicker_SetEnabled( byval hCtrl as TK_WIDGET ptr, byval bEnabled as boolean )
function tkColorPicker_GetFocused( byval hCtrl as TK_WIDGET ptr ) as boolean
function tkColorPicker_GetFocusField( byval hCtrl as TK_WIDGET ptr ) as long
function tkColorPicker_GetEditText( byval hCtrl as TK_WIDGET ptr ) as ustring
function tkColorPicker_GetBodySel( byval hCtrl as TK_WIDGET ptr ) as long
function tkColorPicker_GetScrollTop( byval hCtrl as TK_WIDGET ptr ) as long
sub tkColorPicker_GetIdealSize( byval hCtrl as TK_WIDGET ptr, byref cx as long, byref cy as long )
sub tkColorPicker_GetMatrixSize( byval hCtrl as TK_WIDGET ptr, byref nCols as long, byref nRows as long )
sub tkColorPicker_SetMatrixSize( byval hCtrl as TK_WIDGET ptr, byval nCols as long, byval nRows as long )
sub tkColorPicker_GetCellSize( byval hCtrl as TK_WIDGET ptr, byref cx as long, byref cy as long )
sub tkColorPicker_SetCellSize( byval hCtrl as TK_WIDGET ptr, byval cx as long, byval cy as long )
function tkColorPicker_GetPartRect( byval hCtrl as TK_WIDGET ptr, byval nPart as long, byref rc as TKRECT ) as boolean
function tkColorPicker_GetFieldRect( byval hCtrl as TK_WIDGET ptr, byval nField as long, byref rc as TKRECT ) as boolean
function tkColorPicker_GetTabRect( byval hCtrl as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkColorPicker_HitTestTab( byval hCtrl as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkColorPicker_HitTestField( byval hCtrl as TK_WIDGET ptr, byval x as long, byval y as long ) as long
function tkColorPicker_HitTestBody( byval hCtrl as TK_WIDGET ptr, byval x as long, byval y as long ) as long
sub tkColorPicker_SetColorChangedCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CLR_ColorChangedCallbackSub )
sub tkColorPicker_SetTabChangedCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CLR_TabChangedCallbackSub )
sub tkColorPicker_SetMessageCallback( byval hCtrl as TK_WIDGET ptr, byval userfunc as CLR_MessageCallbackFunc )
sub tkColorPicker_SetPaintCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CLR_PaintCallbackSub )
sub tkColorPicker_SetOpenCallback( byval hCtrl as TK_WIDGET ptr, byval usersub as CLR_OpenCallbackSub )
sub tkColorPicker_RenderInfo( byval p as any ptr )
function tkColorPicker_CountRenderedTones( byval hCtrl as TK_WIDGET ptr, byval nPart as long ) as long
function tkColorPicker_HashRenderedPart( byval hCtrl as TK_WIDGET ptr, byval nPart as long ) as ulong
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme), [tkPaint](tkPaint), [tkVScrollBar](tkVScrollBar)
