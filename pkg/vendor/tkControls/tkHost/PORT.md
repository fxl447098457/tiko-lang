
## OS drops (2026-10-25, for tiko-studio)

Win32's WM_DROPFILES had no twin: SDL's `SDL_EVENT_DROP_*` were not handled. Now:
- tkHost collects a drop: BEGIN, then one FILE or TEXT per item.
- On COMPLETE it sends ONE message to the widget under the drop point, WM_DROPFILES' shape:
  - `TKM_DROPFILES`: `m->text` = the paths LF-separated (UTF-8 as SDL gives them), `m->nStart`
    = how many, `m->x / y` widget-local;
  - or `TKM_DROPTEXT`.
- A refused drop bubbles up the parents, then to the surface's new `OnDrop`, in window pixels.
- The router maps `SDL_EVENT_DROP_*` to their window.
- `tkTest_PushDrop` pushes the sequence SDL would.

Not done: drag-over feedback (`SDL_EVENT_DROP_POSITION`), and dragging OUT of the app.

Measured: examples/tkControls/tkHost 154/154 (16 new) on Windows, X11 and Wayland. The plant (a refused drop
not bubbling) failed 8 checks. Not verified: a real drag from Explorer / a file manager. The
tests push SDL's events.

## Font sources (2026-11-23, for tkPrint)

tkPrint records text by the font's source, not its `TTF_Font ptr`, and opens it again at a page's
pixel size. `tkHost_OpenFontFace` -- the one place a font is opened by name -- now notes each font's
name or path and face; `tkHost_FontSource( f, path, face )` reads it back. `tkHost_CloseFont` closes
and forgets (tkHost_Destroy uses it for the surface's fonts). A slot is reused when SDL_ttf hands out
the same pointer again, so a font closed with `TTF_CloseFont` directly leaves nothing that misleads.
Measured: examples/tkControls/tkPrint's registry checks (4 per scale).
`tkHost_FontBytes( path, pData, nBytes, bOwned )` (2026-11-23, printing R2): a font's bytes by the name or
path OpenFontFace takes -- a registered resource's own, or the file read whole -- for tkPdf to embed.
