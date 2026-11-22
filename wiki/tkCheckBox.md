[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkCheckBox**

# tkCheckBox

Draws a two-state checkbox with an optional caption on either side of the box.

`tkCheckBox` is the [tkControls](Category-tkControls) checkbox: a box, an optional single-line
caption and a focus ring around the pair. It has two states, checked and unchecked; there is no
indeterminate state. A click anywhere on the control, Space or Enter toggles it, and the
check-changed callback reports the new state after it has been applied. You can override the
colours and the fonts; the control owns the geometry and the state.

By default the box is drawn as vectors (`CHK_BOXSTYLE_VECTOR`): a rounded square when unchecked,
the square filled with a knocked-out tick when checked. It needs no font, so it looks the same on
Windows, Linux and macOS. `CHK_BOXSTYLE_GLYPH` draws one font glyph per state instead.

## Importing

```freebasic
#import "vendor/tkControls/tkCheckBox"

using tkCheckBox
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` for a paint
callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Dark_Changed( byval hCheckBox as TK_WIDGET ptr, byval isChecked as boolean )
    print tkCheckBox_GetText( hCheckBox ) & ": " & isChecked
end sub

dim as TK_WIDGET ptr chk = tkCheckBox_Create( tkHost_Root( host ), 1001 )
tkCheckBox_SetText( chk, "Enable dark mode" )
tkCheckBox_SetChecked( chk, true )                 ' silent: no callback
tkCheckBox_SetCheckChangedCallback( chk, @Dark_Changed )

dim as long w, h
tkCheckBox_GetIdealSize( chk, w, h )
tkWidget_SetPos( chk, tkHost_Scale( host, 20 ), tkHost_Scale( host, 60 ), w, h )
```

That callback fires for a completed click, for Space or Enter, and for `tkCheckBox_Toggle`. It
does **not** fire for `tkCheckBox_SetChecked`.

## Concepts

### The handle is a widget

`tkCheckBox_Create( hParent, ctrlId )` returns a `TK_WIDGET ptr`, a child of `hParent`; for a
top-level checkbox pass `tkHost_Root( host )`. You place and size it like any other widget, with
`tkWidget_SetPos`, and show, hide and enable it through the `tkWidget_*` calls. `ctrlId` becomes
the widget's id and the initial `tkCheckBox_SetID` value. The control is created zero-sized: size
it with `tkCheckBox_GetIdealSize`, or turn on `tkCheckBox_SetAutoSize`.

The control frees its state when its widget is destroyed, and destroys its tooltip with it. The
two fonts you hand it are borrowed: they stay yours to close.

### Geometry is derived, never set

You never assign a rectangle. You set inputs — padding, box size, gap, focus ring — and the
control derives four rectangles from them, lazily: a setter marks the layout stale, and the next
paint or rect query does a single measuring pass. A burst of setters costs one measurement, not
one each.

```
ringPad    = nFocusGap + nFocusThick          reserved ALWAYS, focused or not
textW      = measured caption width           0 when there is no caption
textH      = the caption font's height        one height for the control
textBlock  = hasText ? nBoxGap + textW : 0
contentH   = max( hasText ? textH : 0 , nBoxHeight )

nIdealW    = 2*ringPad + nPadLeft + nBoxWidth + textBlock + nPadRight
nIdealH    = 2*ringPad + nPadTop  + contentH + nPadBottom

rcContent  = rcClient deflated by ringPad on all four sides
rcVisual   = rcContent inflated by ringPad    ( = rcClient when sized ideally )

BOXALIGN_LEFT    rcBox  at rcContent.left + nPadLeft,  nBoxWidth x nBoxHeight, v-centred
                 rcText = ( rcBox.right + nBoxGap , rcContent.right - nPadRight )
BOXALIGN_RIGHT   rcBox  at rcContent.right - nPadRight - nBoxWidth, same, v-centred
                 rcText = ( rcContent.left + nPadLeft , rcBox.left - nBoxGap )
```

With no caption font set, the host's default font measures and paints the caption.

`tkCheckBox_GetIdealSize` is valid **before** the control has ever been sized — the measuring
pass runs ahead of the check for a client area, precisely so you can call it to decide how big to
make the control in the first place. It is also unaffected by starving the control's client area,
so a host that always sizes with it can never see an ellipsis.

### The box is pinned; the caption gets the leftover

The box cell is pinned to the padding on whichever side you put it, and the caption takes the
whole span left over. One model, two looks, decided entirely by the width you give the control:

```
sized to GetIdealSize     [x] Enable dark mode              packed
sized to a row width      Enable dark mode            [x]   settings row
```

So a column of `CHK_BOXALIGN_RIGHT` checkboxes all given the same width will line their boxes up
for free. Flipping the side does **not** change the ideal size — the box cell, the gap and both
paddings are all still charged, they have only swapped ends.

`tkCheckBox_SetTextAlign` places the caption inside that **span**, not inside the control. With
the box on the left and `CHK_TEXTALIGN_RIGHT`, the caption goes to the right-hand end of the
span, not to the right-hand edge of the control. Sized to its ideal width the span *is* the
caption, so all three alignments render identically — alignment only becomes visible once the
control has slack.

### The box cell is declared, not measured

`tkCheckBox_SetBoxSize` states how much room the box gets. The control never measures the box —
neither the vector box nor a glyph — so a glyph too large for its cell clips rather than resizing
the control. This is why `tkCheckBox_SetGlyphFont`, `SetGlyphUnchecked`, `SetGlyphChecked` and
`SetBoxStyle` repaint but never re-lay-out, and can never change the ideal width.

### Setters are silent; user interaction notifies

`tkCheckBox_SetChecked` changes the state and fires nothing. That is what makes it safe to call
from inside your own change handler without recursing.

The one deliberate exception is `tkCheckBox_Toggle`, which flips the state **and** fires the
callback. It is an action, not a setter — and the door your keyboard shortcut uses, since this
control parses no mnemonics.

### Focus and keyboard

The control is focusable, so Tab reaches it, and it paints a focus ring while it has focus. A
click focuses it. Space, Enter **and** keypad Enter all toggle it while it is focused; every other
key, Tab included, goes on to the host.

If Enter should reach something else instead — a default button, say — set a message callback
that returns TRUE for `TKM_KEYDOWN` with `key = SDLK_RETURN`. The same veto works for Space.

The focus ring's band is reserved whether or not the control has focus, so nothing moves when
focus arrives — which also means the ring settings contribute to the ideal size.

### Mouse capture and the cancelled gesture

The control takes mouse capture on a press, because press → slide off → release must **not**
toggle. Only a matched press and release with the cursor still inside counts as a click. While
the press is live the hover state keeps tracking, so sliding off visibly un-flashes the control
before the release decides that nothing happened. Losing capture mid-press cancels the press.

`tkCheckBox_GetPressed` reports the gesture itself, inside or slid off; the painter's "pressed"
— `isPressed` in the paint info — is the gesture **and** the cursor still inside.

### Scaling

Every setter takes **raw pixels**; you do the scaling, with `tkHost_Scale`. Only the
creation-time defaults are scaled for you, and the focus ring's thickness is never scaled at all
— a hairline should stay a hairline.

When the host's scale changes, the control receives `TKM_SCALECHANGED` and rescales every metric
it holds — padding, box gap, box size, focus gap and focus curvature — by the ratio of the new
scale to the old, then re-lays-out and re-applies auto-size. The ring thickness is left alone.
There is nothing to call.

## The box styles

- `CHK_BOXSTYLE_VECTOR` (default) paints the box in the mood's box colour. The square is the
  largest one centred in the box cell; its corner curvature is a quarter of its side and its pen
  is `max( 1, (side + 8) \ 16 )`, both derived from the (already scaled) box size. Unchecked is
  the rounded outline in the box colour; checked is the square filled with the box colour and a
  six-point tick knocked out of it in the mood's back colour, so the box is still one colour. A
  paint callback can draw the same box with `tkCheckBox_DrawVectorBox`;
  `tkCheckBox_VectorSquare` and `tkCheckBox_VectorPen` give its square and pen width.
  `tkCheckBox_PaintDefault( p )` draws the whole check box as it would have been drawn, for a
  callback that only adds to it.
- `CHK_BOXSTYLE_GLYPH` draws `TKCHECKBOX_GLYPH_UNCHECKED` / `TKCHECKBOX_GLYPH_CHECKED` from the
  glyph font, centred in the box cell in the box colour. Set that font with
  `tkCheckBox_SetGlyphFont` (the bundled `TK_FONT_ICONS`), and change the glyphs with
  `tkCheckBox_SetGlyphUnchecked` / `SetGlyphChecked`. Unset, the glyph font falls back to the
  caption font, which will usually draw the icon codepoints as missing-glyph boxes — so set it.

Switch with `tkCheckBox_SetBoxStyle`; both styles live in the same declared cell, so the switch
repaints only.

## Behaviour and limits

- **Two states only.** `isChecked` is a `boolean` everywhere, including in the change callback.
  There is no indeterminate / tri-state.
- **One colour per box.** The vector box's tick is knocked out in the background colour, and a
  glyph is a single piece of ink, so the box never has a second colour of its own. A two-colour
  box needs a paint callback.
- **No mnemonics.** `"&Enable"` draws a literal ampersand: `PaintText` does no prefix processing.
  Wire a keyboard shortcut to `tkCheckBox_Toggle` instead.
- **No multiline.** One line, ellipsized into the caption span. Wrapping would make the ideal
  height depend on the assigned width, which would cost `GetIdealSize` its "valid before sizing"
  guarantee.
- **No notification to the parent.** State changes reach you through the callback only.
- **No hit test.** The whole client is the hit area — clicking the caption toggles — so a hit test
  could only ever be "inside the client".
- **The right button is reported, never acted on.** A context menu is your business, through the
  message callback.
- **Overflow is honest, not squeezed.** Too narrow, and the box keeps its declared size and its
  padding while the caption span collapses to zero width and the caption ellipsizes. Too short,
  and the content clips rather than deforming.
- **Removing the caption drops the content height to the box alone.** A caption-less checkbox is
  therefore never taller than a captioned one, and is shorter whenever the box is smaller than a
  line of text — which it is at the defaults. If you are laying out a column of mixed rows, take
  the max of the ideal heights yourself.

## API reference

### Creation

| Function | Behaviour |
|---|---|
| `tkCheckBox_Create( hParent, ctrlId ) as TK_WIDGET ptr` | Creates the control as a child of `hParent`, zero-sized. Returns 0 if `hParent` is 0. `ctrlId` becomes the widget's id and the initial `SetID` value. Colours start from the current theme. Size it with `GetIdealSize` and place it with `tkWidget_SetPos`, or turn on `SetAutoSize`. |

### Content

All silent — they change what is drawn, never what was clicked.

| Function | Behaviour |
|---|---|
| `tkCheckBox_GetText( hCheckBox ) as ustring` | The caption. |
| `tkCheckBox_SetText( hCheckBox, Text )` | Sets the caption and re-measures. `""` removes it, which also gives back the box gap and drops the content height to the box alone. |
| `tkCheckBox_GetGlyphUnchecked( hCheckBox ) as ustring` | The codepoint(s) drawn when unchecked (glyph style). |
| `tkCheckBox_SetGlyphUnchecked( hCheckBox, Glyph )` | Replaces it. Repaints only — the cell is declared, so this can never change the ideal size. `""` draws nothing while still charging the cell and the gap. |
| `tkCheckBox_GetGlyphChecked( hCheckBox ) as ustring` | The codepoint(s) drawn when checked (glyph style). |
| `tkCheckBox_SetGlyphChecked( hCheckBox, Glyph )` | As above, for the checked state. |
| `tkCheckBox_GetBoxStyle( hCheckBox ) as long` | `CHK_BOXSTYLE_VECTOR` or `CHK_BOXSTYLE_GLYPH`. |
| `tkCheckBox_SetBoxStyle( hCheckBox, nBoxStyle )` | Vector box or glyph box. Values outside the enum are **ignored**. Repaints only. |
| `tkCheckBox_GetID( hCheckBox ) as long` | The stored host id. |
| `tkCheckBox_SetID( hCheckBox, id )` | A host payload only. |
| `tkCheckBox_GetItemData( hCheckBox ) as integer` | Free-form host payload. |
| `tkCheckBox_SetItemData( hCheckBox, itemData )` | Stores it. The control never reads it. |

### State

| Function | Behaviour |
|---|---|
| `tkCheckBox_GetChecked( hCheckBox ) as boolean` | The current state. |
| `tkCheckBox_SetChecked( hCheckBox, isChecked )` | **Silent** — fires no callback. Repaints only; never re-measures. Does nothing if the state already matches. |
| `tkCheckBox_GetEnabled( hCheckBox ) as boolean` | |
| `tkCheckBox_SetEnabled( hCheckBox, isEnabled )` | Goes through `tkWidget_Enable`, so the disable is enforced by the host: the control gets no input, Tab skips it, and it gives up capture and focus. Clears hover and any live press at once, and hides a showing tooltip. Does **not** change the checked state. |
| `tkCheckBox_GetFocused( hCheckBox ) as boolean` | Whether the control has keyboard focus. |
| `tkCheckBox_GetHot( hCheckBox ) as boolean` | Whether the cursor is over the control. |
| `tkCheckBox_GetPressed( hCheckBox ) as boolean` | Whether a left press is live — the gesture, inside or slid off. |
| `tkCheckBox_Refresh( hCheckBox )` | Marks the layout stale and repaints. |

Calling `tkWidget_Enable` yourself instead of `SetEnabled` also works: the control handles
`TKM_ENABLE` and syncs its own flag, so it still renders greyed rather than looking live while
eating input.

### Action

| Function | Behaviour |
|---|---|
| `tkCheckBox_Toggle( hCheckBox )` | Flips the state **and fires** `CheckChangedCallback` — an action, not a setter. Refused outright on a disabled control. Does not paint a press flash. |

### Geometry and layout

Every setter takes raw pixels — see *Scaling*.

| Function | Behaviour |
|---|---|
| `tkCheckBox_GetBoxAlign( hCheckBox ) as long` | `CHK_BOXALIGN_LEFT` or `CHK_BOXALIGN_RIGHT`. |
| `tkCheckBox_SetBoxAlign( hCheckBox, nBoxAlign )` | Puts the box on that side, pinned to that side's padding. Values outside the enum are **ignored**. Does not change the ideal size, so it never triggers auto-size. |
| `tkCheckBox_GetTextAlign( hCheckBox ) as long` | `CHK_TEXTALIGN_*`. |
| `tkCheckBox_SetTextAlign( hCheckBox, nTextAlign )` | Places the caption within its **span**, not within the control. Values outside the enum are **ignored**. Repaints only — the span does not move, just the ink inside it. |
| `tkCheckBox_GetPadding( hCheckBox, nLeft, nTop, nRight, nBottom )` | All four, by reference. |
| `tkCheckBox_SetPadding( hCheckBox, nLeft, nTop, nRight, nBottom )` | Negative values are **clamped to 0**. Changes the ideal size. |
| `tkCheckBox_GetBoxGap( hCheckBox ) as long` | |
| `tkCheckBox_SetBoxGap( hCheckBox, nBoxGap )` | Space between the box cell and the caption. Charged **only when there is a caption**. Negative clamps to 0. |
| `tkCheckBox_GetBoxSize( hCheckBox, nBoxWidth, nBoxHeight )` | |
| `tkCheckBox_SetBoxSize( hCheckBox, nBoxWidth, nBoxHeight )` | The declared box cell. Nothing is measured, so this is the only thing deciding how much room the box gets. Negative clamps to 0. |
| `tkCheckBox_GetFocusRing( hCheckBox, nGap, nThickness )` | |
| `tkCheckBox_SetFocusRing( hCheckBox, nGap, nThickness )` | Gap from the content to the ring, and the ring's own thickness. Both are reserved unconditionally, so **changing either changes the ideal size**. Negative clamps to 0; thickness 0 disables the ring. |
| `tkCheckBox_GetFocusCurvature( hCheckBox ) as long` | |
| `tkCheckBox_SetFocusCurvature( hCheckBox, nCurvature )` | An ellipse **diameter**, not a radius: 8 draws a 4px radius. 0 gives square corners. Repaints only — the band's width is the gap plus the thickness, not the curvature. Negative clamps to 0. Setting it pins the curvature against the theme's corner radius. |
| `tkCheckBox_GetAutoSize( hCheckBox ) as boolean` | |
| `tkCheckBox_SetAutoSize( hCheckBox, bAutoSize )` | When true the control sizes **itself** to its ideal size, keeping its top-left, and applies it immediately. Default false. |
| `tkCheckBox_GetIdealSize( hCheckBox, nWidth, nHeight )` | Forces any pending layout and returns the measured size. **Valid before the control has ever been sized**, and unaffected by starving the control's client area. |
| `tkCheckBox_GetTextSize( hCheckBox, tw, nTextH )` | The measured caption width and the one text height, after any pending layout. |
| `tkCheckBox_GetContentRect( hCheckBox, rc ) as boolean` | The client deflated by the focus-ring band. Returns FALSE if the control has no geometry yet. |
| `tkCheckBox_GetBoxRect( hCheckBox, rc ) as boolean` | The box cell. |
| `tkCheckBox_GetTextRect( hCheckBox, rc ) as boolean` | The caption **span**. Empty when there is no caption; degenerate (left = right) when the client is too narrow. Returns TRUE either way — empty is the honest answer. |
| `tkCheckBox_GetVisualRect( hCheckBox, rc ) as boolean` | The content inflated by the ring band; equals the client when the control is sized ideally. |

All four rect queries force a pending layout first, so results are always current.

With auto-size on, the setters that re-apply it are exactly the ones that can move the ideal size:
`SetText`, `SetFont` (and `ApplyFonts` with a text font), `SetPadding`, `SetBoxGap`, `SetBoxSize`,
`SetFocusRing`, and `SetAutoSize` itself — plus a scale change.

### Appearance

| Function | Behaviour |
|---|---|
| `tkCheckBox_GetColors( hCheckBox, pColors )` | Fills your struct. The read-modify-write idiom is Get, assign one field, Set. Does nothing if `pColors` is null. |
| `tkCheckBox_SetColors( hCheckBox, pColors )` | Copies the whole struct, **pins** it, and repaints: a theme change leaves this control's colours alone until `UnpinColors`. Does nothing if `pColors` is null. |
| `tkCheckBox_ThemeColors( t ) as TKCHECKBOX_COLORS` | The colour struct a theme palette maps to — see *Colors*. |
| `tkCheckBox_ApplyTheme( hCheckBox, t )` | Re-applies the theme's corner shape (unless `SetFocusCurvature` pinned it) and, unless the colours are pinned, its colours; repaints. |
| `tkCheckBox_UnpinColors( hCheckBox )` | Hands the colours back to the theme, which is applied at once. |
| `tkCheckBox_GetFont( hCheckBox ) as TTF_Font ptr` | The caption font you set, or 0. |
| `tkCheckBox_SetFont( hCheckBox, f )` | The caption font, and the **measuring** font. Changing it re-measures and can change the ideal size. Borrowed, never owned. Unset, the control measures and paints with the host's default font. |
| `tkCheckBox_GetGlyphFont( hCheckBox ) as TTF_Font ptr` | The glyph font you set, or 0. |
| `tkCheckBox_SetGlyphFont( hCheckBox, f )` | The box font for `CHK_BOXSTYLE_GLYPH`. A paint-time input only: repaints, never re-lays-out, never resizes. Unset, it falls back to the caption font. Borrowed, never owned. |
| `tkCheckBox_ApplyFonts( hCheckBox, fText, fGlyph )` | Sets both fonts at once, as [tkApp](tkApp) does for a form; either may be 0 to keep the current one. |

### Colour resolution

Both are pure functions — no control handle, no globals — so you can call them from your own
paint callback to get exactly the colours the built-in painter would have used.

| Function | Behaviour |
|---|---|
| `tkCheckBox_ResolveMood( isEnabled, isPressed, isHot ) as long` | Returns a `CHK_MOOD_*` value. Precedence is `disabled > pressed > hot > idle`. |
| `tkCheckBox_ResolveColors( pColors, nMood, isChecked, clrBack, clrFore, clrBox )` | Fills the three output colours by reference. `isChecked` selects between the two box colour sets **within** the mood and affects nothing else. Does nothing if `pColors` is null. |

### The vector box

Public so a paint callback can draw the built-in box.

| Function | Behaviour |
|---|---|
| `tkCheckBox_VectorSquare( rcCell, rcSq )` | The square the vector box occupies: the largest square in `rcCell`, centred in it. Empty when the cell is. |
| `tkCheckBox_VectorPen( side ) as long` | The outline's pen width for a square of that side: `(side + 8) \ 16`, at least 1. |
| `tkCheckBox_DrawVectorBox( b, rcCell, isChecked, clrBox, clrBack )` | Draws the vector box into `rcCell`: the rounded outline in `clrBox` when unchecked; when checked, the square filled with `clrBox` and the tick knocked out in `clrBack`. Does nothing if `b` is null or the square is empty. |

### Tooltips

| Function | Behaviour |
|---|---|
| `tkCheckBox_GetTooltipText( hCheckBox ) as ustring` | |
| `tkCheckBox_SetTooltipText( hCheckBox, Text )` | The control's own tip text. When non-empty it wins over the callback. Stores only — the tip is pulled on demand, so there is nothing to repaint. |
| `tkCheckBox_GetTooltipHandle( hCheckBox ) as TK_TIP ptr` | The control's [tkTooltip](tkTooltip), for any `tkTooltip_*` call — `tkTooltip_SetColors`, `SetFonts`, `SetStyle`, `SetMaxWidth` and the rest, none of which is mirrored here. The control owns it and destroys it. |
| `tkCheckBox_SetHoverTime( hCheckBox, ms )` | Initial delay — how long the cursor must rest before the tip shows. |
| `tkCheckBox_SetAutoPopTime( hCheckBox, ms )` | How long the tip stays up. |
| `tkCheckBox_SetReshowTime( hCheckBox, ms )` | The shorter delay after a tip was recently dismissed. |

Resolution order: the control's own text, then `TooltipCallback`, then nothing. **There is no
caption fallback** — a checkbox whose caption is already on screen would otherwise pop a tip that
just repeats it. A press, the cursor leaving, or disabling the control hides a showing tip.

### Callback registration

| Function | Behaviour |
|---|---|
| `tkCheckBox_SetPaintCallback( hCheckBox, usersub )` | Replaces the built-in painter wholesale, and repaints. |
| `tkCheckBox_SetMessageCallback( hCheckBox, userfunc )` | Observe mouse, focus and key messages. |
| `tkCheckBox_SetTooltipCallback( hCheckBox, userfunc )` | Supply tip text on demand. |
| `tkCheckBox_SetCheckChangedCallback( hCheckBox, usersub )` | User-driven state changes. |
| `tkCheckBox_PaintDefault( p )` | Draws the box, caption and focus ring exactly as the built-in painter would, from a paint callback's `p`. Does nothing if `p` is null. |

Pass `0` to any of the `Set*Callback` calls to remove the callback.

### Render probes

Neither is called by the control. They exist so a host writing its own paint callback can
**assert** two specific defects rather than eyeball them. Both render the control into the
window's back buffer with its current painter and with focus forced on — so the focus-ring step is
actually exercised — read one part's pixels back, and mark the window for a fresh repaint.

| Function | Behaviour |
|---|---|
| `tkCheckBox_CountRenderedTones( hCheckBox, nPart ) as long` | How many distinct colours land inside one `CHK_PART_*` rect, capped at 64. Returns 0 if the control has no geometry or the part rect is empty. A part wiped by an unintended fill is literally **one** tone, so the useful assertion is `> 1`. |
| `tkCheckBox_HashRenderedPart( hCheckBox, nPart ) as ulong` | An FNV-1a hash of the pixels in one `CHK_PART_*` rect. Compare two states to prove a change actually reached the surface. Returns 0 on failure. |

`HashRenderedPart` can only ever prove **difference**, never correctness — and only for what you
isolate. Comparing checked against unchecked proves "the state reached the pixels", but not that
the *glyph* did, because the box colour changes too. To isolate one variable, flatten the other
first: set all eight box colours to the same value and the only thing left that can move a pixel
is the glyph or the vector shape.

## Colors

`TKCHECKBOX_COLORS` is a flat struct of 32-bit ARGB `ulong` fields, all with defaults. Copy
semantics: `Set` takes a copy, `Get` fills one out.

| Field | Paints | When |
|---|---|---|
| `BackColor` | The whole client | Idle |
| `BackColorHot` | The whole client | Cursor over the control |
| `BackColorPressed` | The whole client | Live left press, cursor still inside |
| `BackColorDisabled` | The whole client | Disabled |
| `ForeColor` | The caption | Idle |
| `ForeColorHot` | The caption | Hot |
| `ForeColorPressed` | The caption | Pressed |
| `ForeColorDisabled` | The caption | Disabled |
| `BoxColor` | The box | Unchecked, idle |
| `BoxColorHot` | The box | Unchecked, hot |
| `BoxColorPressed` | The box | Unchecked, pressed |
| `BoxColorDisabled` | The box | Unchecked, disabled |
| `BoxColorChecked` | The box | Checked, idle |
| `BoxColorCheckedHot` | The box | Checked, hot |
| `BoxColorCheckedPressed` | The box | Checked, pressed |
| `BoxColorCheckedDisabled` | The box | Checked, disabled |
| `FocusRingColor` | The focus ring | Whenever the control has focus |

**Precedence:** `disabled > pressed > hot > idle`. The checked flag is not a mood — it selects
between the two box colour sets *inside* whichever mood resolved, and touches nothing else. That
is also why a disabled ticked box still reads as ticked: it has its own colour.

**The control reads completely flat out of the box.** `BackColorHot`, `BackColorPressed` and
`BackColorDisabled` all default **equal to** `BackColor`, so hovering changes only the box and the
caption. That is usually what you want in a settings pane. To get a highlight across the whole
row, set one field:

```freebasic
dim as TKCHECKBOX_COLORS c
tkCheckBox_GetColors( chk, @c )
c.BackColorHot = tkRGB( 44, 49, 58 )
tkCheckBox_SetColors( chk, @c )                    ' pins: theme changes now leave it alone
```

### Theme colours

The control's colours start from the current [tkTheme](tkTheme) palette, and follow it: a theme
change (`TKM_THEMECHANGED`) re-applies it unless `SetColors` has pinned the colours.
`tkCheckBox_ThemeColors` maps the palette's roles like this:

| Fields | Theme role |
|---|---|
| `BackColor`, `BackColorHot`, `BackColorPressed`, `BackColorDisabled` | `Window` |
| `ForeColor` / `ForeColorHot` / `ForeColorPressed` / `ForeColorDisabled` | `Text` / `TextHot` / `TextStrong` / `TextDisabled` |
| `BoxColor` / `BoxColorHot` / `BoxColorPressed` / `BoxColorDisabled` | `TextDim` / `Text` / `TextHot` / `TextDisabled` |
| `BoxColorChecked` / `BoxColorCheckedHot` / `BoxColorCheckedPressed` | `Accent` / `AccentHot` / `AccentHot` |
| `BoxColorCheckedDisabled` | `Border` |
| `FocusRingColor` | `FocusRing` |

The focus ring's curvature follows the theme's corner radius too, until
`tkCheckBox_SetFocusCurvature` sets the control's own.

## Callbacks

### CHK_CheckChangedCallbackSub

```freebasic
type CHK_CheckChangedCallbackSub as sub( byval hCheckBox as TK_WIDGET ptr, byval isChecked as boolean )
```

The state changed through **user interaction** — a completed click, Space, or Enter — or through
`tkCheckBox_Toggle`. Fired after the state is updated, so `tkCheckBox_GetChecked()` already
agrees with the `isChecked` you are handed.

`tkCheckBox_SetChecked` does **not** fire it, which is what makes it safe to call `SetChecked`
from inside this handler.

Nothing fires for a cancelled gesture: press the control, slide off it, release, and the state
does not change.

### CHK_PaintCallbackSub

```freebasic
type CHK_PaintCallbackSub as sub( byval p as TKCHECKBOX_PAINTINFO ptr )
```

Draws the whole control **instead of** the built-in painter. Paint through `p->b` — the control's
`TK_PAINT` for this repaint.

The control has already filled the client with the resolved mood's `BackColor` before calling
you, so a callback that only adds a foreground does not have to repaint the background. The box
and the focus ring are the built-in painter's job too, so a callback that wants them must draw
them — `tkCheckBox_DrawVectorBox` draws the box, and `tkCheckBox_PaintDefault( p )` draws
everything the built-in painter would, for a callback that only adds to it.

Two rules worth honouring:

- Draw the caption with the **same font** you handed to `tkCheckBox_SetFont`. The ideal width
  was measured with it; a wider font here makes that measurement a lie and the caption clips.
- **Do not use `PaintBorderRect` to draw a frame or a ring.** It fills before it strokes, so used
  as an outline it erases everything beneath it and the control renders as one solid block. Use
  `PaintRoundOutline`, which strokes without filling, or `PaintRectFactory` when you do want the
  fill. `tkCheckBox_CountRenderedTones` exists so you can assert you have not made this mistake.

More generally: a callback that fills a rectangle covering the whole control erases everything
already drawn. Draw your additions, not a background.

### CHK_MessageCallbackFunc

```freebasic
type CHK_MessageCallbackFunc as function( byval m as TKCHECKBOX_MESSAGEINFO ptr ) as boolean
```

Observe messages. Return TRUE to suppress the control's default handling, FALSE to let it
proceed.

You see the mouse messages (`TKM_MOUSEMOVE`, `TKM_MOUSELEAVE`, `TKM_LBUTTONDOWN`,
`TKM_LBUTTONUP`, `TKM_RBUTTONDOWN`, `TKM_RBUTTONUP`), both focus messages, and `TKM_KEYDOWN`.
While the control is disabled, `TKM_MOUSEMOVE`, `TKM_LBUTTONDOWN` and `TKM_KEYDOWN` are not
reported. The right-button messages are reported and never acted on — a context menu is your
business — and because no capture is taken for the right button, an up can arrive without a down.

Suppressing `TKM_LBUTTONDOWN` suppresses the press itself, which is the supported way to veto a
click; suppressing `TKM_KEYDOWN` vetoes the key, Space and Enter included.

**The result is ignored for three messages:**

| Message | Why |
|---|---|
| `TKM_LBUTTONUP` | The control holds mouse capture across a press and this message releases it. A callback that suppressed it would strand the capture and route every later click to this control. The capture is already released by the time you are called; the toggle, if the click counts, fires after you return. |
| `TKM_SETFOCUS` | Focus is a fact the host reports, not an action to veto. The state is already updated by the time you are called. |
| `TKM_KILLFOCUS` | As above. |

The result is also moot for `TKM_MOUSEMOVE`, `TKM_MOUSELEAVE` and the right-button messages:
the control has already handled them when you are called.

### CHK_TooltipCallbackFunc

```freebasic
type CHK_TooltipCallbackFunc as function( byval hCheckBox as TK_WIDGET ptr ) as ustring
```

Called only when a tip is about to show, and only when the control has no tooltip text of its
own. Return `""` for no tooltip.

### TKCHECKBOX_PAINTINFO

| Field | Meaning |
|---|---|
| `hCheckBox` | The control, so the callback can query it |
| `b` | The control's `TK_PAINT` for this repaint — paint through this |
| `rcClient` | The whole client area |
| `rcContent` | `rcClient` deflated by the focus-ring band |
| `rcBox` | The box cell. Never empty once sized |
| `rcText` | The caption **span**, not the ink. Empty when there is no caption; degenerate when the client is too narrow |
| `rcVisual` | `rcContent` inflated by the ring band — where the focus ring goes |
| `isChecked` | |
| `isHot` | The mouse is over the control |
| `isPressed` | A live left press **and** the cursor is still inside. Slide off and this goes false without ending the gesture |
| `isEnabled` | |
| `isFocused` | Draw a focus ring when true |
| `wszText` | The caption |
| `wszGlyph` | The glyph **already resolved** for `isChecked`, so you do not repeat the choice and cannot disagree with the control about which glyph belongs to which state |
| `nBoxAlign` | `CHK_BOXALIGN_*` |
| `nTextAlign` | `CHK_TEXTALIGN_*` — map to `TK_DT_LEFT` / `TK_DT_CENTER` / `TK_DT_RIGHT` |
| `nBoxStyle` | `CHK_BOXSTYLE_*` |

`rcText` is the span, not a tight box around the glyphs. That is what `TK_DT_ELLIPSIS` needs;
handed a tight box the ellipsis would have nowhere to happen. It also means filling `rcText` fills
the whole span, not just behind the words.

Test presence on the **rects**, not on the strings: an absent caption leaves `rcText` empty, so
`tkRect_IsEmpty` is the single source of truth — and a degenerate span on a too-narrow control
drops out of the same test.

### TKCHECKBOX_MESSAGEINFO

| Field | Meaning |
|---|---|
| `hCheckBox` | The control |
| `msg` | The `TKM_*` message |
| `x`, `y` | The cursor position in the control's client coordinates, for the mouse messages |
| `key` | The key, for `TKM_KEYDOWN` (an `SDLK_*` value) |

## Constants

### Box side

| Value | Meaning |
|---|---|
| `CHK_BOXALIGN_LEFT` | Box pinned to the left padding, caption takes the span to its right (default) |
| `CHK_BOXALIGN_RIGHT` | Box pinned to the right padding, caption takes the span to its left |

### Caption alignment within the span

| Value | Meaning |
|---|---|
| `CHK_TEXTALIGN_LEFT` | Default |
| `CHK_TEXTALIGN_CENTER` | |
| `CHK_TEXTALIGN_RIGHT` | |

### Box style

| Value | Meaning |
|---|---|
| `CHK_BOXSTYLE_VECTOR` | Rounded square and polygon tick, no font needed (default) |
| `CHK_BOXSTYLE_GLYPH` | One font glyph per state, from the glyph font |

### Moods

| Value | Meaning |
|---|---|
| `CHK_MOOD_IDLE` | Nothing is happening |
| `CHK_MOOD_HOT` | The cursor is over the control |
| `CHK_MOOD_PRESSED` | A live left press, cursor still inside |
| `CHK_MOOD_DISABLED` | Beats all three |

### Probe parts

| Value | Rect measured |
|---|---|
| `CHK_PART_CONTROL` | `rcContent` |
| `CHK_PART_BOX` | `rcBox` |
| `CHK_PART_TEXT` | `rcText` |

### Default glyphs

| Constant | Codepoint | Glyph of `TK_FONT_ICONS` |
|---|---|---|
| `TKCHECKBOX_GLYPH_UNCHECKED` | `U+F291` | `TK_ICON_CHECKBOX` — an empty outlined square |
| `TKCHECKBOX_GLYPH_CHECKED` | `U+F28D` | `TK_ICON_CHECKBOX_CHECKED` — the square with a tick |

Both are written in the source as `\u` escapes rather than as literal characters. Do the same if
you replace them from source.

### Default geometry

All are scaled once at `Create` except `TKCHECKBOX_DEFAULT_FOCUSTHICK`, which is never scaled.

| Constant | Value | |
|---|---|---|
| `TKCHECKBOX_DEFAULT_PADLEFT` | 4 | |
| `TKCHECKBOX_DEFAULT_PADTOP` | 2 | |
| `TKCHECKBOX_DEFAULT_PADRIGHT` | 4 | |
| `TKCHECKBOX_DEFAULT_PADBOTTOM` | 2 | |
| `TKCHECKBOX_DEFAULT_BOXGAP` | 8 | Charged only when there is a caption |
| `TKCHECKBOX_DEFAULT_BOXWIDTH` | 16 | Declared, never measured |
| `TKCHECKBOX_DEFAULT_BOXHEIGHT` | 16 | |
| `TKCHECKBOX_DEFAULT_FOCUSGAP` | 2 | |
| `TKCHECKBOX_DEFAULT_FOCUSCURV` | 4 | Ellipse diameter |
| `TKCHECKBOX_DEFAULT_FOCUSTHICK` | 1 | Not scaled |

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const TKCHECKBOX_GLYPH_UNCHECKED = !"\uF291"
const TKCHECKBOX_GLYPH_CHECKED = !"\uF28D"
const as long TKCHECKBOX_DEFAULT_PADLEFT = 4
const as long TKCHECKBOX_DEFAULT_PADTOP = 2
const as long TKCHECKBOX_DEFAULT_PADRIGHT = 4
const as long TKCHECKBOX_DEFAULT_PADBOTTOM = 2
const as long TKCHECKBOX_DEFAULT_BOXGAP = 8
const as long TKCHECKBOX_DEFAULT_BOXWIDTH = 16
const as long TKCHECKBOX_DEFAULT_BOXHEIGHT = 16
const as long TKCHECKBOX_DEFAULT_FOCUSGAP = 2
const as long TKCHECKBOX_DEFAULT_FOCUSCURV = 4 ' ellipse DIAMETER
const as long TKCHECKBOX_DEFAULT_FOCUSTHICK = 1 ' never scaled

enum
    CHK_BOXALIGN_LEFT = 0
    CHK_BOXALIGN_RIGHT
end enum

enum
    CHK_TEXTALIGN_LEFT = 0
    CHK_TEXTALIGN_CENTER
    CHK_TEXTALIGN_RIGHT
end enum

enum
    CHK_MOOD_IDLE = 0
    CHK_MOOD_HOT
    CHK_MOOD_PRESSED
    CHK_MOOD_DISABLED
end enum

enum
    CHK_PART_CONTROL = 0
    CHK_PART_BOX
    CHK_PART_TEXT
end enum

enum
    CHK_BOXSTYLE_VECTOR = 0      ' rounded square + polygon tick, no font needed (default)
    CHK_BOXSTYLE_GLYPH
end enum
```

### Types

```freebasic
type TKCHECKBOX_COLORS
    BackColor               as ulong = &hFF21252Bul    ' ( 33, 37, 43)
    BackColorHot            as ulong = &hFF21252Bul    ' = BackColor: flat out of the box
    BackColorPressed        as ulong = &hFF21252Bul
    BackColorDisabled       as ulong = &hFF21252Bul
    ForeColor               as ulong = &hFFC8CDD6ul    ' (200,205,214)
    ForeColorHot            as ulong = &hFFE2E6EEul    ' (226,230,238)
    ForeColorPressed        as ulong = &hFFFFFFFFul
    ForeColorDisabled       as ulong = &hFF606670ul    ' ( 96,102,112)
    BoxColor                as ulong = &hFF8A9099ul    ' (138,144,153)
    BoxColorHot             as ulong = &hFFB0B6BFul    ' (176,182,191)
    BoxColorPressed         as ulong = &hFFC8CDD6ul    ' (200,205,214)
    BoxColorDisabled        as ulong = &hFF545961ul    ' ( 84, 89, 97)
    BoxColorChecked         as ulong = &hFF569CD6ul    ' ( 86,156,214)
    BoxColorCheckedHot      as ulong = &hFF7AB4E6ul    ' (122,180,230)
    BoxColorCheckedPressed  as ulong = &hFF96C8F0ul    ' (150,200,240)
    BoxColorCheckedDisabled as ulong = &hFF384654ul    ' ( 56, 70, 84)
    FocusRingColor          as ulong = &hFF569CD6ul    ' ( 86,156,214)
end type

type TKCHECKBOX_PAINTINFO
    hCheckBox   as TK_WIDGET ptr
    b           as TK_PAINT ptr
    rcClient    as TKRECT
    rcContent   as TKRECT          ' rcClient deflated by the focus-ring band
    rcBox       as TKRECT          ' the box cell; never empty once sized
    rcText      as TKRECT          ' the caption SPAN, not the ink; empty with no caption
    rcVisual    as TKRECT          ' rcContent inflated by the band: where the ring goes
    isChecked   as boolean
    isHot       as boolean
    isPressed   as boolean         ' a live press AND the cursor still inside
    isEnabled   as boolean
    isFocused   as boolean
    wszText     as ustring
    wszGlyph    as ustring         ' already resolved for isChecked
    nBoxAlign   as long
    nTextAlign  as long
    nBoxStyle   as long            ' CHK_BOXSTYLE_* (added)
end type

type TKCHECKBOX_MESSAGEINFO
    hCheckBox as TK_WIDGET ptr
    msg       as long              ' TKM_*
    x         as single
    y         as single
    key       as long
end type

type TKCHECKBOX_STATE   ' per-instance state; reach it through the procedures

type CHK_PaintCallbackSub as sub( byval p as TKCHECKBOX_PAINTINFO ptr )
type CHK_MessageCallbackFunc as function( byval m as TKCHECKBOX_MESSAGEINFO ptr ) as boolean
type CHK_TooltipCallbackFunc as function( byval hCheckBox as TK_WIDGET ptr ) as ustring
type CHK_CheckChangedCallbackSub as sub( byval hCheckBox as TK_WIDGET ptr, byval isChecked as boolean )
```

### Procedures

```freebasic
function tkCheckBox_ResolveMood( byval isEnabled as boolean, byval isPressed as boolean, byval isHot as boolean ) as long
sub tkCheckBox_ResolveColors( byval pColors as TKCHECKBOX_COLORS ptr, byval nMood as long, byval isChecked as boolean, byref clrBack as ulong, byref clrFore as ulong, byref clrBox as ulong )
sub tkCheckBox_VectorSquare( byref rcCell as TKRECT, byref rcSq as TKRECT )
function tkCheckBox_VectorPen( byval side as long ) as long
sub tkCheckBox_DrawVectorBox( byval b as TK_PAINT ptr, byref rcCell as TKRECT, byval isChecked as boolean, byval clrBox as ulong, byval clrBack as ulong )
function tkCheckBox_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkCheckBox_GetText( byval hCheckBox as TK_WIDGET ptr ) as ustring
sub tkCheckBox_SetText( byval hCheckBox as TK_WIDGET ptr, byval Text as ustring )
function tkCheckBox_GetGlyphUnchecked( byval hCheckBox as TK_WIDGET ptr ) as ustring
sub tkCheckBox_SetGlyphUnchecked( byval hCheckBox as TK_WIDGET ptr, byval Glyph as ustring )
function tkCheckBox_GetGlyphChecked( byval hCheckBox as TK_WIDGET ptr ) as ustring
sub tkCheckBox_SetGlyphChecked( byval hCheckBox as TK_WIDGET ptr, byval Glyph as ustring )
function tkCheckBox_GetBoxStyle( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetBoxStyle( byval hCheckBox as TK_WIDGET ptr, byval nBoxStyle as long )
function tkCheckBox_GetID( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetID( byval hCheckBox as TK_WIDGET ptr, byval id as long )
function tkCheckBox_GetItemData( byval hCheckBox as TK_WIDGET ptr ) as integer
sub tkCheckBox_SetItemData( byval hCheckBox as TK_WIDGET ptr, byval itemData as integer )
function tkCheckBox_GetChecked( byval hCheckBox as TK_WIDGET ptr ) as boolean
sub tkCheckBox_SetChecked( byval hCheckBox as TK_WIDGET ptr, byval isChecked as boolean )
function tkCheckBox_GetEnabled( byval hCheckBox as TK_WIDGET ptr ) as boolean
sub tkCheckBox_SetEnabled( byval hCheckBox as TK_WIDGET ptr, byval isEnabled as boolean )
function tkCheckBox_GetFocused( byval hCheckBox as TK_WIDGET ptr ) as boolean
function tkCheckBox_GetHot( byval hCheckBox as TK_WIDGET ptr ) as boolean
function tkCheckBox_GetPressed( byval hCheckBox as TK_WIDGET ptr ) as boolean
sub tkCheckBox_Refresh( byval hCheckBox as TK_WIDGET ptr )
sub tkCheckBox_Toggle( byval hCheckBox as TK_WIDGET ptr )
function tkCheckBox_GetBoxAlign( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetBoxAlign( byval hCheckBox as TK_WIDGET ptr, byval nBoxAlign as long )
function tkCheckBox_GetTextAlign( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetTextAlign( byval hCheckBox as TK_WIDGET ptr, byval nTextAlign as long )
sub tkCheckBox_GetPadding( byval hCheckBox as TK_WIDGET ptr, byref nLeft as long, byref nTop as long, byref nRight as long, byref nBottom as long )
sub tkCheckBox_SetPadding( byval hCheckBox as TK_WIDGET ptr, byval nLeft as long, byval nTop as long, byval nRight as long, byval nBottom as long )
function tkCheckBox_GetBoxGap( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetBoxGap( byval hCheckBox as TK_WIDGET ptr, byval nBoxGap as long )
sub tkCheckBox_GetBoxSize( byval hCheckBox as TK_WIDGET ptr, byref nBoxWidth as long, byref nBoxHeight as long )
sub tkCheckBox_SetBoxSize( byval hCheckBox as TK_WIDGET ptr, byval nBoxWidth as long, byval nBoxHeight as long )
sub tkCheckBox_GetFocusRing( byval hCheckBox as TK_WIDGET ptr, byref nGap as long, byref nThickness as long )
sub tkCheckBox_SetFocusRing( byval hCheckBox as TK_WIDGET ptr, byval nGap as long, byval nThickness as long )
function tkCheckBox_GetFocusCurvature( byval hCheckBox as TK_WIDGET ptr ) as long
sub tkCheckBox_SetFocusCurvature( byval hCheckBox as TK_WIDGET ptr, byval nCurvature as long )
function tkCheckBox_GetAutoSize( byval hCheckBox as TK_WIDGET ptr ) as boolean
sub tkCheckBox_SetAutoSize( byval hCheckBox as TK_WIDGET ptr, byval bAutoSize as boolean )
sub tkCheckBox_GetIdealSize( byval hCheckBox as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
sub tkCheckBox_GetTextSize( byval hCheckBox as TK_WIDGET ptr, byref tw as long, byref nTextH as long )
function tkCheckBox_GetContentRect( byval hCheckBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCheckBox_GetBoxRect( byval hCheckBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCheckBox_GetTextRect( byval hCheckBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkCheckBox_GetVisualRect( byval hCheckBox as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkCheckBox_GetColors( byval hCheckBox as TK_WIDGET ptr, byval pColors as TKCHECKBOX_COLORS ptr )
sub tkCheckBox_SetColors( byval hCheckBox as TK_WIDGET ptr, byval pColors as TKCHECKBOX_COLORS ptr )
function tkCheckBox_ThemeColors( byref t as TKTHEME_COLORS ) as TKCHECKBOX_COLORS
sub tkCheckBox_ApplyTheme( byval hCheckBox as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkCheckBox_UnpinColors( byval hCheckBox as TK_WIDGET ptr )
function tkCheckBox_GetFont( byval hCheckBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCheckBox_SetFont( byval hCheckBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkCheckBox_GetGlyphFont( byval hCheckBox as TK_WIDGET ptr ) as TTF_Font ptr
sub tkCheckBox_SetGlyphFont( byval hCheckBox as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkCheckBox_ApplyFonts( byval hCheckBox as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkCheckBox_SetTooltipText( byval hCheckBox as TK_WIDGET ptr, byval Text as ustring )
function tkCheckBox_GetTooltipText( byval hCheckBox as TK_WIDGET ptr ) as ustring
function tkCheckBox_GetTooltipHandle( byval hCheckBox as TK_WIDGET ptr ) as TK_TIP ptr
sub tkCheckBox_SetHoverTime( byval hCheckBox as TK_WIDGET ptr, byval ms as long )
sub tkCheckBox_SetAutoPopTime( byval hCheckBox as TK_WIDGET ptr, byval ms as long )
sub tkCheckBox_SetReshowTime( byval hCheckBox as TK_WIDGET ptr, byval ms as long )
sub tkCheckBox_PaintDefault( byval p as TKCHECKBOX_PAINTINFO ptr )
sub tkCheckBox_SetPaintCallback( byval hCheckBox as TK_WIDGET ptr, byval usersub as CHK_PaintCallbackSub )
sub tkCheckBox_SetMessageCallback( byval hCheckBox as TK_WIDGET ptr, byval userfunc as CHK_MessageCallbackFunc )
sub tkCheckBox_SetTooltipCallback( byval hCheckBox as TK_WIDGET ptr, byval userfunc as CHK_TooltipCallbackFunc )
sub tkCheckBox_SetCheckChangedCallback( byval hCheckBox as TK_WIDGET ptr, byval usersub as CHK_CheckChangedCallbackSub )
function tkCheckBox_CountRenderedTones( byval hCheckBox as TK_WIDGET ptr, byval nPart as long ) as long
function tkCheckBox_HashRenderedPart( byval hCheckBox as TK_WIDGET ptr, byval nPart as long ) as ulong
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
