[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkButton**

# tkButton

Draws a momentary command button with an optional glyph or image on either side.

`tkButton` is the [tkControls](Category-tkControls) command button: a rounded rectangle with an
optional left icon, an optional caption and an optional right icon. It fires on release and never
latches, so its only states are transient (hot, pressed, focused) or yours (enabled, default). It
takes focus, so Tab reaches it and Space or Enter operates it.

Either icon slot holds a glyph from a font (the bundled icon font's `TK_ICON_*` codepoints, or any
font's) or an image file loaded through SDL_image. Setters are silent; the click callback runs
only for a real click or for `tkButton_Click`.

The shape setters take pixels: `tkButton_SetIconGap`, `tkButton_SetIconSize`, `tkButton_SetFocusRing`
(gap and thickness; 0 thickness hides it) and `tkButton_SetBorderWidth`. The border follows the
theme's `BorderWidth` until you set it, as the corner curvature follows its `CornerRadius`. A paint
callback replaces the drawing; call `tkButton_PaintDefault( p )` in it to draw the stock button
first and add to it.

## Importing

```freebasic
#import "vendor/tkControls/tkButton"

using tkButton
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip). Add `using tkPaint` for a paint
callback and `using tkTooltip` to configure the shared tooltip.

## Example

A complete program: one window, one button with a glyph, a click callback.

```freebasic
#import "vendor/tkControls/tkButton"
using tkButton
using tkHost

sub Save_Click( byval hButton as TK_WIDGET ptr, byval id as long )
    print "clicked " & tkButton_GetText( hButton ) & " (id " & id & ")"
end sub

SDL_Init( SDL_INIT_VIDEO )
TTF_Init()
dim as TK_HOST ptr host = tkHost_Create( "tkButton", 400, 200, tkHost_FontDir() & TK_FONT_UI )
dim as TTF_Font ptr fGlyph = tkHost_OpenFont( host, tkHost_FontDir() & TK_FONT_ICONS, 10 )

dim as TK_WIDGET ptr btn = tkButton_Create( tkHost_Root( host ), 1000 )
tkButton_SetGlyphFont( btn, fGlyph )
tkButton_SetText( btn, "Save" )
tkButton_SetGlyphLeft( btn, wchr( TK_ICON_SAVE ) )
tkButton_SetDefault( btn, true )
tkButton_SetClickCallback( btn, @Save_Click )

dim as long w, h
tkButton_GetIdealSize( btn, w, h )
tkWidget_SetPos( btn, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), w, h )
tkHost_Show( host )
tkHost_Run( host )
tkHost_Destroy( host )
TTF_Quit()
SDL_Quit()
```

With no font set, the caption uses the host's default font. Fonts opened with `tkHost_OpenFont`
belong to the host and are rescaled with it; the button only borrows them.

## Concepts

### The handle is a widget

`tkButton_Create( hParent, ctrlId )` makes the button a child of `hParent` (another widget, or
`tkHost_Root( host )` for a top-level control) and returns its `TK_WIDGET ptr`; every
`tkButton_*` procedure takes it. The button is created with no size: measure it with
`tkButton_GetIdealSize` and place it with `tkWidget_SetPos`. `ctrlId` is the widget's id and the
initial value handed to the click callback (`tkButton_SetID` changes the latter).

The button is focusable, so it joins the host's Tab order. Tab and Shift+Tab are the host's: the
button never claims them.

### The layout model

**The two icon cells are pinned to the padding.** The left cell sits at
`rcButton.left + padLeft`, the right cell at `rcButton.right - padRight - iconWidth`, and
neither ever moves. `BTN_ALIGN_LEFT` / `BTN_ALIGN_CENTER` / `BTN_ALIGN_RIGHT` then place the
caption **in the span left over between them**, not in the button.

So a button with a left glyph and `BTN_ALIGN_CENTER` centres its caption on the *leftover*
space, which sits visibly right of the button's own centre. The icons frame the caption; they do
not travel with it.

The geometry, if you need to predict it:

```
  ringPad     = focusGap + focusThickness          reserved ALWAYS, focused or not
  textW       = the measured caption width, 0 when there is no caption
  textH       = the caption font's line height     ONE height for the control

  leftBlock   = hasLeft  ? iconWidth + (hasText ? iconGap : 0) : 0
  rightBlock  = hasRight ? iconWidth + (hasText ? iconGap : 0) : 0
  contentH    = max( hasText ? textH : 0 , (hasLeft or hasRight) ? iconHeight : 0 )

  idealW      = 2*ringPad + padLeft + leftBlock + textW + rightBlock + padRight
  idealH      = 2*ringPad + padTop  + contentH + padBottom

  rcButton    = rcClient deflated by ringPad on all four sides
  rcIconLeft  = pinned at rcButton.left + padLeft,  iconWidth x iconHeight, v-centred
  rcIconRight = pinned at rcButton.right - padRight - iconWidth, same, v-centred
  rcText      = ( rcButton.left  + padLeft  + leftBlock ,
                  rcButton.right - padRight - rightBlock ), v-centred on textH
  rcVisual    = rcButton inflated by ringPad
```

Three consequences follow:

**`rcText` is the caption span, not the caption ink.** It is the whole box between the two icon
blocks, which is what the ellipsis needs: handed a tight box around the glyphs, there would be
nowhere for it to happen. A paint callback that fills `rcText` fills the entire span.

**The icon gap is charged only when there is a caption to separate from.** An icon-only button
costs `padLeft + icon + padRight` and nothing else, so the glyph sits centred in its own padding.

**Content height ignores the font when there is no caption.** An icon-only button in a row of
captioned ones therefore has a *shorter* ideal height. A host laying out a row of buttons takes
the maximum itself.

An absent part gets an **empty** rect, not a zero-width one tucked against an edge, so a paint
callback can test `tkRect_IsEmpty` instead of re-deriving presence from the strings and images it
was handed. A cell counts as present when its side carries either a glyph or a successfully
loaded image.

Layout is lazy. A setter marks the layout stale and invalidates the widget; the next paint, or
any rect, size or tone query, recomputes it. Setting six properties in a row costs one measuring
pass, not six.

### When the button is smaller than ideal

Rects are computed honestly rather than squeezed. The icons keep their declared size and stay
pinned to their padding, and `rcText` is what collapses, clamped to degenerate (`left = right`)
rather than going negative. So a too-narrow button loses its caption to the ellipsis and keeps
its icons. Vertically, a client shorter than the content clips top and bottom.

### The focus-ring band is always reserved

The ring is drawn inside a band of `focusGap + focusThickness` pixels around the button chrome,
and that band is reserved whether or not the control currently has focus. This is why the button
does not jump when you Tab onto it, and why changing either focus-ring value changes the ideal
size. `rcButton` is the client rect deflated by that band; `rcVisual` is `rcButton` inflated by
it again, which is the full client area.

### The icon cell is declared, never measured

`tkButton_SetIconSize` decides how much room a glyph gets, and the control never measures the
glyph font. A glyph too large for the cell **clips**; it does not resize the button. That is why
`tkButton_SetGlyphFont` is a paint-time input only: changing it repaints but never re-lays-out.
With no glyph font set, glyphs are drawn with the caption font.

The caption font is the opposite: it is the *measuring* font, and changing it re-measures. With
no caption font set, the control measures and paints with the host's default font.

### An icon slot holds a glyph or an image, never both

`tkButton_SetImageLeft` and `tkButton_SetImageRight` take a path, load it through SDL_image
(`.png`, `.bmp`, `.jpg`, `.gif`, `.ico` and more) and draw that image in the icon cell
**instead of** a glyph. The setters keep the invariant themselves: a successful load clears that
side's glyph string, and setting a non-empty glyph frees that side's image.

The image is drawn into the **same declared cell** a glyph would have used, aspect ratio
preserved, so switching a side from a glyph to an image changes no geometry at all.

The control **owns** the images it loads. They are freed when the button is destroyed, when you
pass `""`, when the load fails, and when you set a glyph on that side.

```freebasic
if tkButton_SetImageLeft( btn, "save.png" ) = 0 then
    tkButton_SetGlyphLeft( btn, wchr( TK_ICON_SAVE ) )    ' fall back to the glyph
end if
```

### Sizes and scale

The creation-time defaults are scaled to the host with `tkHost_Scale`; the two thicknesses are
not, so a hairline stays a hairline:

| Setting | Default | Scaled at create? |
|---|---:|---|
| Padding left / right | 12 | Yes |
| Padding top / bottom | 6 | Yes |
| Icon gap | 8 | Yes |
| Icon width / height | 16 | Yes |
| Corner curvature | 12 | Yes (or from the theme, see below) |
| Border thickness | 1 | No (or from the theme) |
| Focus-ring gap | 2 | Yes |
| Focus-ring thickness | 1 | No |

Every setter takes pixels at the current scale. When the scale changes the button receives
`TKM_SCALECHANGED` and multiplies the padding, icon gap, icon size, curvature and focus-ring gap
by the ratio of new to old scale (values you set included), then re-applies auto-size. The border
and ring thicknesses are left alone.

### Corner curvature and border follow the theme

`tkButton_SetCornerCurvature` takes an ellipse **diameter**, not a radius: `12` draws a 6-pixel
radius, `0` gives square corners. Until you call it, the curvature follows the
[tkTheme](tkTheme) shape: twice the theme's `CornerRadius`, scaled, or the default when the theme
gives none. The border thickness likewise follows the theme's `BorderWidth` until you call
`tkButton_SetBorderWidth`. Either setter pins that button's shape, so later theme changes leave
it alone.

The whole client takes the mood colour first, as PsButton's did, so a rounded button on a parent
of another colour shows **square corners**. `tkButton_SetTransparentCorners( h, TRUE )` leaves the
client outside the rounded body unpainted: the corners show what the parent painted under the
button (a card, a tinted strip). A paint callback then draws on the parent's colours too.

### Who sizes the control

By default, nobody but you: measure with `tkButton_GetIdealSize` and call `tkWidget_SetPos`.
Turn on `tkButton_SetAutoSize( btn, true )` and the button resizes **itself** with
`tkWidget_SetSize`, keeping its position, whenever something that changes the ideal size changes:
caption, glyphs, images, caption font, padding, icon gap, icon size, focus ring, scale. Turning it
on applies immediately.

### Programmatic setters are silent, with one deliberate exception

No setter fires the click callback. `tkButton_SetText`, `tkButton_SetEnabled`,
`tkButton_SetDefault` and the rest change what is drawn, never what was clicked.

**`tkButton_Click` is the exception, and it fires the click callback on purpose.** It is an
*action*, not a state setter, and it is the door your accelerator uses, since the button parses
no mnemonics.

### How a click is decided

Pressing the left button focuses the control (even if your message callback goes on to suppress
the press), hides any tooltip, then takes mouse capture. The click fires on **release**, and only
if the press started on the control and the cursor is over it at release. So the standard escape
gesture works: press, slide off, release, and nothing happens. Sliding back on before releasing
re-arms it. If capture is taken away mid-press (`TKM_CAPTURECHANGED`), the press is cancelled.

Space, Enter and keypad Enter take the same path to the click callback, so the keyboard and the
mouse cannot drift apart: both are user action, both notify.

### The keyboard

While focused and enabled, the button claims Space, Enter and keypad Enter on key-down and fires
the click. Every other key is left unclaimed and bubbles to the parent widgets; an unclaimed Tab
moves focus. A held key auto-repeats, and every repeat is a click. A message callback sees
`TKM_KEYDOWN` first and can claim the key by returning TRUE.

### The default button is appearance only

`tkButton_SetDefault` draws `DefaultBorderColor` over whichever mood's border would have been
used, and does nothing else. It does **not** claim Enter from elsewhere in the form: the button
claims Enter only while it is itself focused. Routing a form's default key stays your job.
Nothing stops you marking two buttons default.

### Enabling and disabling is real

`tkButton_SetEnabled` calls `tkWidget_Enable`. A disabled widget gets no input and is skipped by
Tab. Whichever route disables the widget, the button hears it as `TKM_ENABLE`: it greys itself,
drops any hover and live press, and hides its tooltip, so the routes cannot disagree.

### Hover

The host guarantees `TKM_MOUSELEAVE`, so the button never stays painted hot after the cursor has
gone. While a press is live the leave does not clear the press: during capture the cursor may
wander off and come back.

### Lifetime

The button frees itself when its widget is destroyed, together with its tooltip and any images it
loaded. The fonts you pass in stay yours (fonts from `tkHost_OpenFont` belong to the host).

## Behaviour and limits

- **It never latches.** There is no selected or checked state. A latching toolbar button and an
  on/off switch are different controls ([tkToggle](tkToggle) is the switch).
- **`isDefault` is appearance only.** One border colour, applied last and with no mood test.
- **No mnemonics.** `"&Save"` draws a literal ampersand; the text painter does no prefix
  processing. Wire your own accelerator and call `tkButton_Click`.
- **Notification is the click callback and nothing else.**
- **A cell is a glyph or an image, never both.** The setters enforce it in both directions, and
  an image takes exactly the same declared cell a glyph would.
- **Single line only.** The caption is one line, vertically centred, cut with an ellipsis when it
  does not fit.
- **No mouse auto-repeat.** Holding the mouse button fires nothing; the click happens on release.
- **Double-clicks are not special.** The button ignores the click count, so a rapid second click
  is an ordinary second click.
- **Mouse capture is taken** for the press/cancel gesture. It is released on the button-up before
  any callback runs. A message callback cannot suppress the button-up.
- **No hit-test procedure.** The whole widget is the hit area.
- **Arrow keys are not handled.** Only Space, Enter and keypad Enter activate the control.
- **The right mouse button is reported, never acted on.** A context menu is your business.
- **No caption fallback for the tooltip.** With neither tooltip text nor a tooltip callback
  answer, nothing shows.
- **Invalid alignment values are ignored**, leaving the current setting in place.
- **Both fonts are borrowed.** The button creates neither and closes neither.
- **Negative layout values clamp to 0.** Padding, icon gap, icon size, curvature, border width
  and both focus-ring values are floored at zero. A border or ring thickness of 0 means "do not
  draw it at all".
- **An icon-only button is shorter than a captioned one.** By design; take the maximum yourself
  when laying out a row.

## Procedures in brief

### Caption, glyphs and tooltip

All of these are silent: they change what is drawn, never what was clicked.

| Procedure | Description |
|---|---|
| `tkButton_GetText` / `tkButton_SetText` | The caption. `""` removes it, which also stops the icon gap being charged. Re-measures and re-applies auto-size. |
| `tkButton_SetGlyphLeft` / `tkButton_SetGlyphRight` | A glyph string for that cell, usually one codepoint such as `wchr( TK_ICON_SAVE )`. `""` removes it, giving back both the cell **and** its gap. A non-empty glyph frees that side's image. |
| `tkButton_SetImageLeft` / `tkButton_SetImageRight` | Loads an image file into that cell **instead of** a glyph. Returns 1 on a successful load (which clears that side's glyph), 0 otherwise. `""` removes the image and returns 0, so 0 means "no image on this side", not necessarily an error. The button owns the image. |
| `tkButton_GetID` / `tkButton_SetID` | The value handed to the click callback; defaults to `ctrlId`. A host payload: the button never acts on it. |
| `tkButton_GetTooltipText` / `tkButton_SetTooltipText` | The button's own tooltip text. It always wins; the tooltip callback is consulted only when this is empty. Does not repaint. |
| `tkButton_GetTooltipHandle` | The button's [tkTooltip](tkTooltip) as a `TK_TIP ptr`, for any `tkTooltip_*` call (title, glyph, style, colours). The button owns it. |
| `tkButton_SetHoverTime` / `SetAutoPopTime` / `SetReshowTime` | The tooltip's initial delay, how long it stays up, and the shorter delay after a tip was recently dismissed, in milliseconds. |

### State

| Procedure | Description |
|---|---|
| `tkButton_GetEnabled` / `tkButton_SetEnabled` | The enabled state, through `tkWidget_Enable`, so input really stops and Tab skips it. |
| `tkButton_GetFocused` | TRUE while the button has focus and is painting its focus ring. |
| `tkButton_GetHot` | TRUE while the cursor is over the button. |
| `tkButton_GetPressed` | TRUE while a left press that started on the button is live. |
| `tkButton_GetDefault` / `tkButton_SetDefault` | The default-button border. **Appearance only**; repaints, never re-measures. No-op when the state already matches. |
| `tkButton_Click` | **Fires the click callback**, exactly as a real click would. Refused on a disabled button; does nothing without a click callback; paints no press flash. |

### Geometry and layout

Every setter takes pixels. Unless noted, each marks the layout stale, invalidates the widget and
re-applies auto-size.

| Procedure | Description |
|---|---|
| `tkButton_SetTextAlign` | `BTN_ALIGN_LEFT`, `BTN_ALIGN_CENTER` (the default) or `BTN_ALIGN_RIGHT`, within the span between the icon cells. Other values are ignored. Repaints without re-measuring. |
| `tkButton_GetPadding` / `tkButton_SetPadding` | The four padding values inside the chrome, each clamped to 0. |
| `tkButton_GetIconGap` / `tkButton_SetIconGap` | The space between an icon cell and the caption, clamped to 0. Charged only on a side with an icon, and only when there is a caption. |
| `tkButton_GetIconSize` / `tkButton_SetIconSize` | The declared icon cell both icons share, each clamped to 0. |
| `tkButton_GetFocusRing` / `tkButton_SetFocusRing` | The gap from the chrome to the ring, and the ring's thickness (0 hides it), each clamped to 0. Both change the ideal size. |
| `tkButton_GetBorderWidth` / `tkButton_SetBorderWidth` | The border thickness, clamped to 0, where 0 means no border. Repaints only. Setting it stops the theme's `BorderWidth` applying to this button. |
| `tkButton_SetCornerCurvature` | The corner ellipse **diameter**, clamped to 0 (square corners). Repaints only. Setting it stops the theme's `CornerRadius` applying to this button. |
| `tkButton_GetTransparentCorners` / `tkButton_SetTransparentCorners` | TRUE: the client outside the rounded body is not filled, so the corners show the parent. Default FALSE (the whole client in the mood colour). Repaints only. |
| `tkButton_SetAutoSize` | When TRUE the button sizes itself to its ideal size whenever something size-affecting changes. Default FALSE. Turning it on applies immediately. |
| `tkButton_GetIdealSize` | Forces any pending layout and returns the ideal size. **Valid before the button has been sized**: the measuring pass runs before the zero-size bail. |
| `tkButton_GetTextWidth` | The measured caption width and the caption font's line height. |
| `tkButton_GetButtonRect` | The chrome: the widget's rect deflated by the focus-ring band. |
| `tkButton_GetTextRect` | The caption **span** between the icon cells. Empty with no caption; degenerate when too narrow. |
| `tkButton_GetIconLeftRect` / `tkButton_GetIconRightRect` | That icon cell; **empty** (and still TRUE) when the side has neither a glyph nor an image. |
| `tkButton_GetVisualRect` | The chrome inflated by the focus-ring band: the whole widget. |

The five rect queries force any pending layout first. Each returns FALSE, leaving `rc` empty,
while the button has no size yet. Rects are in the button's own coordinates.

### Appearance

| Procedure | Description |
|---|---|
| `tkButton_GetColors` / `tkButton_SetColors` | Reads or replaces the whole `TKBUTTON_COLORS` struct. Setting repaints and **pins** the colours, so theme changes leave this button alone. |
| `tkButton_UnpinColors` | Hands the colours back to the theme and applies it at once. |
| `tkButton_ThemeColors` | The `TKBUTTON_COLORS` a theme's roles produce (see *Colors*). |
| `tkButton_ApplyTheme` | Applies a theme's shape, and its colours unless pinned. The button does this itself on `TKM_THEMECHANGED`. |
| `tkButton_SetFont` | The **caption font, and therefore the measuring font**: changing it re-measures. Borrowed. Unset, the host's default font. |
| `tkButton_SetGlyphFont` | The **icon font**, normally `tkHost_OpenFont( host, tkHost_FontDir() & TK_FONT_ICONS, size )`. Paint-time only: repaints, never re-lays-out. Borrowed. Unset, the caption font. |
| `tkButton_ApplyFonts` | Sets both at once; a 0 keeps that font. Re-measures. |

To change one colour, read-modify-write:

```freebasic
dim as TKBUTTON_COLORS clrs
tkButton_GetColors( btn, @clrs )
clrs.BorderColor    = tkRGB( 80, 86, 98 )
clrs.BorderColorHot = tkRGB( 97, 175, 239 )
tkButton_SetColors( btn, @clrs )
```

### Diagnostics

| Procedure | Description |
|---|---|
| `tkButton_ResolveMood( isEnabled, isPressed, isHot )` | The `BTN_MOOD_*` this state calls for: `disabled > pressed > hot > idle`. A **pure function**, so a custom painter gets exactly what the built-in painter would use. |
| `tkButton_ResolveColors( pColors, nMood, isDefault, ... )` | Turns a mood plus the default flag into the four colours the painter uses. Also pure. The default border is applied **last and unconditionally**. Does nothing if `pColors` is null. |
| `tkButton_CountRenderedTones( btn, nPart )` | Renders the button with its current painter, `isFocused` forced TRUE, and counts the distinct colours inside one of its rects (`BTN_PART_*`), capped at 64. Returns 0 while the button has no size or the part's rect is empty. |

`tkButton_CountRenderedTones` exists to check that **a custom paint callback is not flooding the
button**. `PaintBorderRect` fills before it strokes, so a callback that reaches for it to draw a
frame or a focus ring floods everything beneath, and the button renders as one solid block of a
plausible colour. A wiped part is literally one tone, so `count > 1` is an unambiguous check. The
probe draws into the host's back buffer and marks the host for a repaint.

```freebasic
if tkButton_CountRenderedTones( btn, BTN_PART_BUTTON ) <= 1 then
    print "paint callback is flooding the button"
end if
```

### Callback registration

`tkButton_SetPaintCallback`, `tkButton_SetMessageCallback`, `tkButton_SetTooltipCallback` and
`tkButton_SetClickCallback` install the four callbacks below. All are optional and independent;
setting the paint callback repaints.

## Colors

`TKBUTTON_COLORS` is one flat struct of eighteen `ulong` ARGB fields: four drawn things (fill,
caption, border, icon) × four moods (idle, hot, pressed, disabled), plus the focus ring and the
default-button border. A new button takes its colours from the current theme.

| Field | Paints | Theme role |
|---|---|---|
| `BackColor` | Button fill, idle | `Surface` |
| `ForeColor` | Caption, idle | `Text` |
| `BorderColor` | Button border, idle | `Surface` |
| `IconColor` | Both glyphs, idle | `Text` |
| `BackColorHot` | Button fill, cursor over the button | `SurfaceHot` |
| `ForeColorHot` | Caption, hot | `TextHot` |
| `BorderColorHot` | Button border, hot | `SurfaceHot` |
| `IconColorHot` | Both glyphs, hot | `TextHot` |
| `BackColorPressed` | Button fill, live left press | `Selected` |
| `ForeColorPressed` | Caption, pressed | `SelectedText` |
| `BorderColorPressed` | Button border, pressed | `Selected` |
| `IconColorPressed` | Both glyphs, pressed | `SelectedText` |
| `BackColorDisabled` | Button fill, disabled | `SurfaceDisabled` |
| `ForeColorDisabled` | Caption, disabled | `TextDisabled` |
| `BorderColorDisabled` | Button border, disabled | `SurfaceDisabled` |
| `IconColorDisabled` | Both glyphs, disabled | `TextDisabled` |
| `FocusRingColor` | The focus ring, drawn only while focused | `FocusRing` |
| `DefaultBorderColor` | Replaces the resolved mood's border when `isDefault` is set | `FocusRing` |

The roles are read after the button's theme style, if any, has remapped them, and any recipes the
theme defines for `Button` are applied on top. The struct's own initialisers are the dark preset's
values, so a `TKBUTTON_COLORS` you declare yourself starts out matching the dark theme.

### Which colour wins

The painter picks one fill, one caption, one border and one icon colour per repaint, in this
precedence:

```
disabled   >   pressed   >   hot   >   idle
```

That is `tkButton_ResolveMood` in full. There is a real pressed set: the held-down state is the
feedback that tells the user the click registered.

`DefaultBorderColor` is the only field outside the moods. `tkButton_ResolveColors` applies it
**last and with no mood test**, replacing whatever border the mood chose, so the accent outline
survives all four moods.

### Why the button reads borderless by default

Each mood's border role is the same as its fill, so the button reads as a solid shape with no
outline until you want one; set the four `BorderColor*` fields to get a visible frame. The icons
follow the caption the same way. Set the `IconColor*` fields to break that coupling.

### What the painter draws

| Part | Shape |
|---|---|
| Background | The whole widget, in the resolved mood's fill, before anything else (and before a paint callback). |
| Chrome | A rounded rectangle over `rcButton`, curvature as an ellipse diameter, with a border when the border thickness is above 0, filled without one at 0. |
| Left / right icon | The image, aspect preserved, or the glyph centred in its cell with the glyph font. Skipped when the cell is empty. |
| Caption | Drawn in `rcText` with the caption font, aligned per `BTN_ALIGN_*`, single line, ellipsized. Skipped when `rcText` is empty. |
| Focus ring | A rounded **outline** over `rcVisual`, only while focused and the ring thickness is above 0. Never a fill. Its curvature is the button's plus the band on both sides, so the two curves stay concentric. |

## Callbacks

### Click

```freebasic
type BTN_ClickCallbackSub as sub( byval hButton as TK_WIDGET ptr, byval id as long )
```

The button was clicked: a matched press and release with the cursor inside, or Space / Enter /
keypad Enter while focused, or `tkButton_Click`. Nothing fires for a cancelled gesture. `id` is
whatever `tkButton_SetID` set, defaulting to `ctrlId`.

The button re-reads its own enabled state immediately before calling you, so a message callback
that disabled it mid-gesture is honoured. On a mouse release the order is: capture released, the
message callback told of `TKM_LBUTTONUP`, then the click.

### Paint

```freebasic
type BTN_PaintCallbackSub as sub( byval p as TKBUTTON_PAINTINFO ptr )
```

Draws the whole control **instead of** the built-in painter. Paint through `p->b`, the
[tkPaint](tkPaint) surface for this repaint. Call `tkButton_PaintDefault( p )` first to draw the
stock button and add to it.

The widget has already been filled with the **resolved mood's** background before you are called,
so a callback that only adds something on top does not repaint the background.

| Field | Meaning |
|---|---|
| `hButton` | The control, so the callback can query it |
| `b` | The `TK_PAINT` surface for this repaint (borrowed) |
| `rcClient` | The whole widget, in its own coordinates |
| `rcButton` | The chrome: `rcClient` deflated by the focus-ring band |
| `rcIconLeft` | The left icon cell; **empty** when the side carries neither a glyph nor an image |
| `rcText` | The caption **span** between the icon blocks, not the ink; empty with no caption, degenerate when too narrow |
| `rcIconRight` | The right icon cell, same rule |
| `rcVisual` | `rcButton` inflated by the focus-ring band |
| `isHot` | The cursor is over the control |
| `isPressed` | A left press that started on the control is live |
| `isEnabled` | The enabled state |
| `isFocused` | Draw a focus ring when TRUE |
| `isDefault` | The default-button flag (appearance only) |
| `wszText` | The caption |
| `wszGlyphLeft` / `wszGlyphRight` | The glyph strings |
| `pImageLeft` / `pImageRight` | That cell's image as an `SDL_Texture ptr`, or 0. When set, draw it with `p->b->PaintImage` **instead of** the glyph. Borrowed: the button owns it |
| `nTextAlign` | `BTN_ALIGN_*` |

All five rects are precomputed. Use them as given: do not re-derive `rcText` from the padding,
because the icon cells and the gap can change underneath you. Test presence with
`tkRect_IsEmpty`.

Two contracts worth honouring:

- **Draw the caption with the font you gave `tkButton_SetFont`.** The button's width was measured
  with it.
- **Do not use `PaintBorderRect` to draw a frame.** It fills first, so used as an outline it erases
  everything beneath it. `PaintRoundOutline` strokes without filling.

### Message

```freebasic
type BTN_MessageCallbackFunc as function( byval m as TKBUTTON_MESSAGEINFO ptr ) as boolean
```

Observes messages as they arrive. `TKBUTTON_MESSAGEINFO` carries `hButton`, `msg` (a `TKM_*`
code), `x` and `y` (the cursor in the button's coordinates, for mouse messages) and `key` (the
SDL keycode, for `TKM_KEYDOWN`).

| Message | Return TRUE to |
|---|---|
| `TKM_LBUTTONDOWN` | Suppress the press (no capture, no pressed state). Focus has already moved to the button. |
| `TKM_KEYDOWN` | Claim the key before the button acts on it. |
| `TKM_MOUSEMOVE`, `TKM_MOUSELEAVE` | Ignored: reported after the hover state is updated. |
| `TKM_LBUTTONUP` | Ignored: capture is already released, and the click still follows. |
| `TKM_RBUTTONDOWN`, `TKM_RBUTTONUP` | Ignored: reported only. |
| `TKM_SETFOCUS`, `TKM_KILLFOCUS` | Ignored: focus is a fact, and the state is already updated. |

A disabled button reports no mouse moves, presses or keys.

### Tooltip

```freebasic
type BTN_TooltipCallbackFunc as function( byval hButton as TK_WIDGET ptr ) as ustring
```

Supplies the tooltip text on demand, when a tip is about to show, and **only when the button has
no tooltip text of its own**. Return `""` for no tooltip. There is no caption fallback: a tip
repeating a caption already on screen is noise. A press, a leave or disabling the button hides
the tip.

## Constants

| Constant | Value | Meaning |
|---|---:|---|
| `TKBUTTON_DEFAULT_PADLEFT` / `PADRIGHT` | 12 | Default left / right padding, scaled at create |
| `TKBUTTON_DEFAULT_PADTOP` / `PADBOTTOM` | 6 | Default top / bottom padding, scaled at create |
| `TKBUTTON_DEFAULT_ICONGAP` | 8 | Default icon-to-caption gap, scaled at create |
| `TKBUTTON_DEFAULT_ICONWIDTH` / `ICONHEIGHT` | 16 | Default icon cell, scaled at create |
| `TKBUTTON_DEFAULT_CURVATURE` | 12 | Default corner ellipse **diameter**, scaled at create, used when the theme gives no corner radius |
| `TKBUTTON_DEFAULT_BORDERTHICK` | 1 | Default border thickness, never scaled, used when the theme gives no border width |
| `TKBUTTON_DEFAULT_FOCUSGAP` | 2 | Default focus-ring gap, scaled at create |
| `TKBUTTON_DEFAULT_FOCUSTHICK` | 1 | Default focus-ring thickness, never scaled |

`BTN_ALIGN_*` places the caption in the span between the icon cells (`BTN_ALIGN_CENTER` is the
default). `BTN_MOOD_*` names the colour set `tkButton_ResolveMood` returns. `BTN_PART_*` names the
rect `tkButton_CountRenderedTones` looks at: the chrome, the caption span, or an icon cell.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TKBUTTON_DEFAULT_PADLEFT = 12
const as long TKBUTTON_DEFAULT_PADRIGHT = 12
const as long TKBUTTON_DEFAULT_PADTOP = 6
const as long TKBUTTON_DEFAULT_PADBOTTOM = 6
const as long TKBUTTON_DEFAULT_ICONGAP = 8
const as long TKBUTTON_DEFAULT_ICONWIDTH = 16
const as long TKBUTTON_DEFAULT_ICONHEIGHT = 16
const as long TKBUTTON_DEFAULT_CURVATURE = 12
const as long TKBUTTON_DEFAULT_BORDERTHICK = 1
const as long TKBUTTON_DEFAULT_FOCUSGAP = 2
const as long TKBUTTON_DEFAULT_FOCUSTHICK = 1

enum
    BTN_ALIGN_LEFT = 0
    BTN_ALIGN_CENTER
    BTN_ALIGN_RIGHT
end enum

enum
    BTN_MOOD_IDLE = 0
    BTN_MOOD_HOT
    BTN_MOOD_PRESSED
    BTN_MOOD_DISABLED
end enum

enum
    BTN_PART_BUTTON = 0
    BTN_PART_TEXT
    BTN_PART_ICONLEFT
    BTN_PART_ICONRIGHT
end enum
```

### Types

```freebasic
type TKBUTTON_COLORS
    BackColor           as ulong = &hFF2C313Aul    ' ( 44, 49, 58)
    ForeColor           as ulong = &hFFC8CDD6ul    ' (200,205,214)
    BorderColor         as ulong = &hFF2C313Aul
    IconColor           as ulong = &hFFC8CDD6ul
    BackColorHot        as ulong = &hFF373D48ul    ' ( 55, 61, 72)
    ForeColorHot        as ulong = &hFFE2E6EEul    ' (226,230,238)
    BorderColorHot      as ulong = &hFF373D48ul
    IconColorHot        as ulong = &hFFE2E6EEul
    BackColorPressed    as ulong = &hFF264F78ul    ' ( 38, 79,120)
    ForeColorPressed    as ulong = &hFFFFFFFFul
    BorderColorPressed  as ulong = &hFF264F78ul
    IconColorPressed    as ulong = &hFFFFFFFFul
    BackColorDisabled   as ulong = &hFF282C33ul    ' ( 40, 44, 51)
    ForeColorDisabled   as ulong = &hFF606670ul    ' ( 96,102,112)
    BorderColorDisabled as ulong = &hFF282C33ul
    IconColorDisabled   as ulong = &hFF606670ul
    FocusRingColor      as ulong = &hFF61AFEFul    ' ( 97,175,239)
    DefaultBorderColor  as ulong = &hFF61AFEFul
end type

type TKBUTTON_PAINTINFO
    hButton       as TK_WIDGET ptr
    b             as TK_PAINT ptr
    rcClient      as TKRECT
    rcButton      as TKRECT
    rcIconLeft    as TKRECT
    rcText        as TKRECT            ' the caption SPAN between the icon blocks, not the ink
    rcIconRight   as TKRECT
    rcVisual      as TKRECT
    isHot         as boolean
    isPressed     as boolean
    isEnabled     as boolean
    isFocused     as boolean
    isDefault     as boolean
    wszText       as ustring
    wszGlyphLeft  as ustring
    wszGlyphRight as ustring
    pImageLeft    as SDL_Texture ptr
    pImageRight   as SDL_Texture ptr
    nTextAlign    as long
end type

type TKBUTTON_MESSAGEINFO
    hButton as TK_WIDGET ptr
    msg     as long                    ' TKM_*
    x       as single
    y       as single
    key     as long
end type

type TKBUTTON_STATE   ' per-instance state; reach it through the procedures

type BTN_PaintCallbackSub as sub( byval p as TKBUTTON_PAINTINFO ptr )
type BTN_MessageCallbackFunc as function( byval m as TKBUTTON_MESSAGEINFO ptr ) as boolean
type BTN_TooltipCallbackFunc as function( byval hButton as TK_WIDGET ptr ) as ustring
type BTN_ClickCallbackSub as sub( byval hButton as TK_WIDGET ptr, byval id as long )
```

### Procedures

```freebasic
function tkButton_ResolveMood( byval isEnabled as boolean, byval isPressed as boolean, byval isHot as boolean ) as long
sub tkButton_ResolveColors( byval pColors as TKBUTTON_COLORS ptr, byval nMood as long, byval isDefault as boolean, byref clrBack as ulong, byref clrFore as ulong, byref clrBorder as ulong, byref clrIcon as ulong )
function tkButton_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkButton_GetText( byval hButton as TK_WIDGET ptr ) as ustring
sub tkButton_SetText( byval hButton as TK_WIDGET ptr, byval Text as ustring )
sub tkButton_SetGlyphLeft( byval hButton as TK_WIDGET ptr, byval Glyph as ustring )
sub tkButton_SetGlyphRight( byval hButton as TK_WIDGET ptr, byval Glyph as ustring )
function tkButton_SetImageLeft( byval hButton as TK_WIDGET ptr, byval Path as ustring ) as long
function tkButton_SetImageRight( byval hButton as TK_WIDGET ptr, byval Path as ustring ) as long
function tkButton_GetID( byval hButton as TK_WIDGET ptr ) as long
sub tkButton_SetID( byval hButton as TK_WIDGET ptr, byval id as long )
function tkButton_GetEnabled( byval hButton as TK_WIDGET ptr ) as boolean
sub tkButton_SetEnabled( byval hButton as TK_WIDGET ptr, byval isEnabled as boolean )
function tkButton_GetFocused( byval hButton as TK_WIDGET ptr ) as boolean
function tkButton_GetHot( byval hButton as TK_WIDGET ptr ) as boolean
function tkButton_GetPressed( byval hButton as TK_WIDGET ptr ) as boolean
function tkButton_GetDefault( byval hButton as TK_WIDGET ptr ) as boolean
sub tkButton_SetDefault( byval hButton as TK_WIDGET ptr, byval isDefault as boolean )
sub tkButton_Click( byval hButton as TK_WIDGET ptr )
sub tkButton_SetTextAlign( byval hButton as TK_WIDGET ptr, byval nTextAlign as long )
sub tkButton_SetPadding( byval hButton as TK_WIDGET ptr, byval l as long, byval t as long, byval r as long, byval b as long )
sub tkButton_GetPadding( byval hButton as TK_WIDGET ptr, byref l as long, byref t as long, byref r as long, byref b as long )
function tkButton_GetIconGap( byval hButton as TK_WIDGET ptr ) as long
sub tkButton_GetIconSize( byval hButton as TK_WIDGET ptr, byref iw as long, byref ih as long )
sub tkButton_GetFocusRing( byval hButton as TK_WIDGET ptr, byref nGap as long, byref nThick as long )
sub tkButton_SetIconGap( byval hButton as TK_WIDGET ptr, byval nGap as long )
sub tkButton_SetIconSize( byval hButton as TK_WIDGET ptr, byval iw as long, byval ih as long )
sub tkButton_SetFocusRing( byval hButton as TK_WIDGET ptr, byval nGap as long, byval nThick as long )
function tkButton_GetBorderWidth( byval hButton as TK_WIDGET ptr ) as long
sub tkButton_SetBorderWidth( byval hButton as TK_WIDGET ptr, byval nWidth as long )
sub tkButton_SetCornerCurvature( byval hButton as TK_WIDGET ptr, byval nCurvature as long )
sub tkButton_SetAutoSize( byval hButton as TK_WIDGET ptr, byval bAutoSize as boolean )
sub tkButton_GetIdealSize( byval hButton as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
sub tkButton_GetTextWidth( byval hButton as TK_WIDGET ptr, byref tw as long, byref th as long )
function tkButton_GetButtonRect( byval hButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkButton_GetTextRect( byval hButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkButton_GetIconLeftRect( byval hButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkButton_GetIconRightRect( byval hButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkButton_GetVisualRect( byval hButton as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkButton_GetColors( byval hButton as TK_WIDGET ptr, byval pColors as TKBUTTON_COLORS ptr )
sub tkButton_SetColors( byval hButton as TK_WIDGET ptr, byval pColors as TKBUTTON_COLORS ptr )
function tkButton_ThemeColors( byref t as TKTHEME_COLORS ) as TKBUTTON_COLORS
sub tkButton_ApplyTheme( byval hButton as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkButton_UnpinColors( byval hButton as TK_WIDGET ptr )
sub tkButton_ApplyFonts( byval hButton as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkButton_SetFont( byval hButton as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkButton_SetGlyphFont( byval hButton as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkButton_SetTooltipText( byval hButton as TK_WIDGET ptr, byval Text as ustring )
function tkButton_GetTooltipText( byval hButton as TK_WIDGET ptr ) as ustring
function tkButton_GetTooltipHandle( byval hButton as TK_WIDGET ptr ) as TK_TIP ptr
sub tkButton_SetHoverTime( byval hButton as TK_WIDGET ptr, byval ms as long )
sub tkButton_SetAutoPopTime( byval hButton as TK_WIDGET ptr, byval ms as long )
sub tkButton_SetReshowTime( byval hButton as TK_WIDGET ptr, byval ms as long )
sub tkButton_SetPaintCallback( byval hButton as TK_WIDGET ptr, byval usersub as BTN_PaintCallbackSub )
sub tkButton_SetMessageCallback( byval hButton as TK_WIDGET ptr, byval userfunc as BTN_MessageCallbackFunc )
sub tkButton_SetTooltipCallback( byval hButton as TK_WIDGET ptr, byval userfunc as BTN_TooltipCallbackFunc )
sub tkButton_SetClickCallback( byval hButton as TK_WIDGET ptr, byval usersub as BTN_ClickCallbackSub )
function tkButton_CountRenderedTones( byval hButton as TK_WIDGET ptr, byval nPart as long ) as long
sub tkButton_PaintDefault( byval p as TKBUTTON_PAINTINFO ptr )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkTheme](tkTheme), [tkTooltip](tkTooltip), [tkPaint](tkPaint)
