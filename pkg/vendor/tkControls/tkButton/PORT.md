# tkButton: port notes (from vendor PsButton)

**Name map:** `PsButton_*` → `tkButton_*`; `PSBUTTON_*` → `TKBUTTON_*`. `BTN_ALIGN_*`,
`BTN_MOOD_*` and `BTN_PART_*` are unchanged. The handle is `TK_WIDGET ptr`.

**Kept verbatim:**
- LayoutButton and its geometry;
- ResolveMood / ResolveColors;
- the colour struct and its defaults;
- the four callbacks;
- press → slide off → release;
- silent setters, with `Click` as the one notifying action;
- AutoSize;
- GetIdealSize before sizing;
- the rect queries;
- CountRenderedTones (now `SDL_RenderReadPixels`).

**Changed:**
- `Create( hParent as TK_WIDGET ptr, id )`; a top-level parent is `tkHost_Root( h )`.
- The tooltip is a tkTooltip owned through tkTipHost. `GetTooltipHandle` returns it (vendor's
  `GetPsTooltipHandle`); `SetHoverTime` / `SetAutoPopTime` / `SetReshowTime` → tkTipHost delays.
- Images load through SDL_image (`.png .bmp .jpg .gif .ico ...`).
- Colours start from the current theme (`tkTheme_Get()`, identical to the struct defaults
  under the dark preset).

**Dropped (Win32-only):**
- `WM_SETTEXT` / `WM_GETTEXT` (no window text);
- `WM_GETDLGCODE` (the host owns Tab);
- the WM_CHAR swallow (SDL never beeps);
- the 100 ms hover poll (the host guarantees the leave);
- `SetTooltipMode` / `GetTooltipMode` and the comctl32 handle;
- `Rescale(oldDpi, newDpi)` → `TKM_SCALECHANGED`;
- PsRegistry.

**Added:** `tkButton_GetHot`, `tkButton_GetPressed`, `tkButton_GetTextWidth` (test probes).
`tkButton_SetIconGap`, `SetIconSize`, `SetFocusRing`, `Get` / `SetBorderWidth` (the border also follows
the theme's BorderWidth until set) and `tkButton_PaintDefault` (the stock drawing, for a paint callback):
for the form designer. PsButton keeps none of them.
