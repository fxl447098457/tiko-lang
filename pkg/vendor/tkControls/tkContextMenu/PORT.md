# tkContextMenu -- not a port

PsControls has no context-menu component: a Win32 program answers `WM_CONTEXTMENU` and calls
`TrackPopupMenu`. tkContextMenu is new to tkControls, written for the form designer's second
component (`visual = false` in `tkMeta/controls.toml`, the designer's **PopupMenu**).

**Built on:** tkPopupMenu (the menu itself, which the component owns and destroys) and tkHost's
context-menu routing: `tkWidget_SetContextMenu`, `TKM_CONTEXTMENU`, `tkWidget_ClearContextMenuRefs`.

**Shape:** a hidden, zero-size child widget (never shown, never focusable, never hit), so it has a
handle and a parent and goes when its parent goes. A TK_MENU carries no pointer of its own, so the
module keeps a small table from its menus to their components for the select callback.

**Rules:** tkHost sends `TKM_CONTEXTMENU` for the right button's release over an attached widget
(or anything inside it) and for the Menu key or Shift+F10 on the focused one, INSTEAD of giving the
control the release or the key -- an attached menu replaces a control's own (tkTextBox, tkCodeEdit).
The Popup callback runs before it shows; the Command callback gets the chosen id, from a submenu too.
Disabled, it opens nothing. On `TKM_DESTROY` it clears every attachment and destroys its menu.
Attachments are within one surface. Setters are silent.
