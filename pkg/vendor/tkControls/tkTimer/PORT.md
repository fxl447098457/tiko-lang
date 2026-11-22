# tkTimer -- not a port

PsControls has no timer control: a Win32 program calls `SetTimer` on a window. tkTimer is new to
tkControls, written for the form designer's first component (a control with `visual = false` in
`tkMeta/controls.toml`): something a form creates and sets up like a control but never shows or lays
out.

**Built on:** `tkWidget_SetTimer` / `tkWidget_KillTimer` (tkHost), whose ticks are posted from SDL's
timer thread and delivered as `TKM_TIMER` on the UI thread -- to a hidden widget as to any other.

**Shape:** a hidden, zero-size child widget (never shown, never focusable, never hit), so it has a
handle, an id and a parent, and goes when its parent goes. Its id is `TK_TIMER_APP`.

**Rules:** it runs while it is enabled and its interval is above 0. `tkWidget_Enable` (`TKM_ENABLE`)
starts and stops it; `tkTimer_SetInterval` re-arms it; `TKM_DESTROY` kills it; a `TKM_SHOW` that
would show it hides it again. Setters are silent.
