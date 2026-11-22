# tkMenuBar: port notes (from vendor PsMenuBar)

**Name map:** `PsMenuBar_*` → `tkMenuBar_*`; `PSMENUBAR_*` → `TKMENUBAR_*` (`_ITEM`,
`_COLORS`, `_PAINTINFO`, `_STATE`, `_DEFAULT_PADDING`). The `MB_*Callback*` types are unchanged.
The bar is a `TK_WIDGET ptr`; its dropdowns are `TK_MENU ptr` (tkPopupMenu).

**Kept:** items measured from the font and laid end to end from x = 0 at full height; lazy layout;
`GetIdealWidth` / `GetItemRect` empty until the bar has a height; append-only items, the id stored
and never read; hot and active as two facts painted alike; click opens (nothing selected),
hover-switch while open, click the bar again closes, an item without a dropdown does nothing, a
`clicks = 2` press is the same toggle; no capture for the mouse; init-popup: the bar's, then the
popup's, for every open (programmatic too); the dropdown anchored under the item, merged into the
bar's bottom edge; Left at the root / Right on a row without an enabled submenu step to the
previous / next item WITH a dropdown (wrapping) and open it with its first row selected, while
Left inside a submenu and Right on a submenu row stay the menu's; Escape at the root drops back to
the keyboard highlight; the highlight-only mode (Left / Right over ANY item, wrapping; Down /
Enter open with the first row; Escape clears; a click elsewhere abandons it and still lands); the
command reported with the chain closed and the highlight cleared, the dropdown's own select
callback running too; an outside press closes the chain and still reaches its target; silent
setters; dropdowns owned (attaching over one destroys it, 0 detaches) and destroyed with the bar;
theme roles; rescale of the padding.

**Changed (there is no pump filter):**
- `FilterMessage` is gone. With a dropdown open, tkHost already routes keys to the open popup;
  the bar's Left / Right moves go through tkPopupMenu's key hook, which the bar installs on a
  dropdown when it opens it (the dropdown's own select / closed callbacks and key hook are kept
  and chained behind the bar's).
- The highlight-only mode has no popup to receive keys, so for its duration the bar takes the
  keyboard focus and the mouse capture -- what vendor's filter saw for free -- and gives both back
  (the focus to whoever had it) when the highlight ends. A press outside the bar during it is
  handed to the widget under it; a Tab moves the focus on and ends the highlight.
- "Click the bar again closes": the host closes the chain on that press before the bar sees it
  (the dropdown lets the press through), so the bar remembers a dismissal for 250 ms and treats
  the press as the closing click instead of reopening.
- The chain closing behind the bar's back (another popup opened elsewhere) is re-synced on the
  next paint, mouse event or `IsMenuOpen`.
- `CPM_NOTIFY_*` / `SetNotifyWindow` → the dropdown's select and closed callbacks.
- Added `GetColors` (vendor has none) and `GetHotIndex`.
- Added `PaintItemDefault( p )`: the stock item, for an item-paint callback (the form designer's
  Paint event).

**Dropped as Win32-only:** `FilterMessage`, the 100 ms hot-track poll (`IDT_CMENUBAR_HOTTRACK`,
`PSMENUBAR_HOTTRACK_MS`), `WM_ERASEBKGND`, `CS_DBLCLKS`, `WM_ACTIVATEAPP` advice (the host
closes popups when focus leaves the application), PsRegistry.

**Vendor bugs found:** none.

**Test note:** parallel test runs on one desktop steal the OS focus, and the host then dismisses
every open popup 150 ms later (correct behaviour) -- an open dropdown vanished mid-sequence in 4
runs of 4 while three other suites ran. The selftest filters the OS's focus-lost and mouse-leave
window events with `SDL_SetEventFilter`; no check is about either. The demo's `--shot` does the
same for focus-lost, since a window started from a script is often not in the foreground. Real
pointer grabs by X11/Wayland popups are not exercised by synthetic events (as for tkPopupMenu).
