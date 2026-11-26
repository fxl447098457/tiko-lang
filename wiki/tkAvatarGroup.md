[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkAvatarGroup**

# tkAvatarGroup

Draws a row of avatars, overlapping (stacked) or spread apart, with a "+N" disc for the ones that do
not fit.

`tkAvatarGroup` is the [tkControls](Category-tkControls) avatar group: the people on a document, in a
meeting or on a team. Its items are data in the group, not child widgets, and each is drawn with
[tkAvatar](tkAvatar)'s `tkAvatar_PaintInto`, so an item has a photo or initials, a palette colour and
a presence mark as a tkAvatar has. Size, shape and colour mode apply to every item.

Every setter is silent. `ItemClick` fires when the user clicks an item, `OverflowClick` when they
click the "+N"; with `Interactive` on, Enter and Space click too. The Form Designer's
**AvatarGroup** has no Bind: the items are added in code.

## Importing

```freebasic
#import "vendor/tkControls/tkAvatarGroup"

using tkAvatarGroup
using tkAvatar
using tkBadge
using tkHost
```

The module brings in [tkAvatar](tkAvatar), [tkBadge](tkBadge), [tkPopupMenu](tkPopupMenu),
[tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and SDL_image),
[tkTheme](tkTheme), [tkTooltip](tkTooltip) and [tkImage](tkImage). `using tkAvatar` names the
`TKAVATAR_*` shape and colour-mode constants; `using tkBadge` the `TKBADGE_PRESENCE_*` ones.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Team_ItemClick( byval hGroup as TK_WIDGET ptr, byval idx as long )
    print "open " & tkAvatarGroup_GetItemName( hGroup, idx )
end sub

sub Team_OverflowClick( byval hGroup as TK_WIDGET ptr )
    tkAvatarGroup_ShowOverflowMenu( hGroup )      ' the hidden names; a pick fires ItemClick
end sub

dim as ustring names(0 to 6) = { "Ada Lovelace", "Grace Hopper", "Alan Turing", "Edsger Dijkstra", _
                                 "Barbara Liskov", "Ken Thompson", "Niklaus Wirth" }
dim as TK_WIDGET ptr team = tkAvatarGroup_Create( tkHost_Root( host ), 200 )
for i as long = 0 to 6
    tkAvatarGroup_AddItem( team, names(i) )
next
tkAvatarGroup_SetItemPresence( team, 0, TKBADGE_PRESENCE_AVAILABLE )
tkAvatarGroup_SetItemImageFile( team, 1, "photos/grace.jpg" )
tkAvatarGroup_SetInteractive( team, true )        ' a tab stop: arrows, Enter
tkAvatarGroup_SetItemClickCallback( team, @Team_ItemClick )
tkAvatarGroup_SetOverflowClickCallback( team, @Team_OverflowClick )

dim as long w, h
tkAvatarGroup_GetIdealSize( team, w, h )          ' four avatars and "+3"
tkWidget_SetPos( team, tkHost_Scale( host, 20 ), tkHost_Scale( host, 80 ), w, h )
```

## Items

- `AddItem( name, colorKey = "", pImage = 0 )` appends an item and returns its index;
  `InsertItem( before, ... )` puts it before `before` (-1 or out of range: at the end). `pImage` is
  a borrowed `tkImageFile` and must outlive the item.
- The **name** gives the initials and the tip; the **colour key**, else the name, picks the palette
  colour, by tkAvatar's rules. Items have no initials override, glyph or active state.
- `SetItemImageFile` and `SetItemImagePixels` give the item a picture it owns, freed with the item.
  A failed load falls back to the initials.
- `SetItemPresence( idx, n )`: `TKAVATAR_PRESENCE_NONE` or a `TKBADGE_PRESENCE_*`.
- `SetItemData` / `GetItemData`: an `integer` for the host.
- `RemoveItem`, `Clear`, `GetCount`, `GetItemName`. `FindItemByKey( key )` returns the first item
  whose colour key (else name) is `key`, or -1.

## Layout, overflow and order

- `SetLayout( TKAVGROUP_STACK )` (default): each item overlaps the one before by `SetOverlap`
  percent of the diameter (0..60, default 20). `TKAVGROUP_SPREAD`: the items sit `SetSpacing`
  design units apart (default 4).
- **The first item is on top** of the stack, the most important one whole. Every item has a
  cut-out ring of `BackColor`, `TKAVGROUP_RING` (2) pixels wide, where it overlaps the next.
- `SetSize` is every item's diameter in design units (16..128, default 32). `SetShape` takes
  `TKAVATAR_CIRCLE`, `_ROUNDED` or `_SQUARE`; `SetColorMode` takes `TKAVATAR_COLORFUL`, `_NEUTRAL`,
  `_ACCENT` or `_CUSTOM`.
- **Overflow:** with more people than `SetMaxVisible` (at least 1, default 5), the group shows the
  **first** MaxVisible − 1 items and a "+N" disc for the rest. Seven items at MaxVisible 5 show four
  and "+3"; five items show all five.
- `SetTotal( n )` is the real count when more exist than the items held (-1, the default, is the
  items held). Four items loaded with Total 42 show the four and "+38".
- `GetShownCount` and `GetOverflowCount` answer what is shown; `GetOverflowCount` is 0 without a
  disc.
- The "+N" is drawn in `OverflowInk` on `OverflowBack`, fitted to the disc. In STACK it is centred
  in the part of the disc the item before leaves visible, so the "+" is not covered.
- Disabled, the items and the disc's fill are drawn at half opacity.

## Mouse and keyboard

- A press and a release on the same item fire `ItemClick( idx )`; on the "+N", `OverflowClick`.
  Where items overlap, the hit goes to the item on top. Circles are hit as circles, their ring
  included.
- The group is **not a tab stop** until `SetInteractive( true )`. Then a press focuses it, and an
  item focus ring in `FocusRingColor` marks the focus item. **Left** / **Right** / **Home** / **End**
  move it, with no wrap; the "+N" is the last stop. **Enter** and **Space** click the focus item or
  the "+N"; a held key does not repeat the click. A click moves the focus item to what was clicked.
  `GetFocusItem` answers it: an item index, or the shown count for the "+N". It stays on a shown
  slot when RemoveItem, SetMaxVisible or SetTotal take slots away. Keys with Ctrl, Alt or the GUI
  key held are not the group's.
- The tip shows the item's name. On the "+N" it lists the hidden names, one per line, ten and then
  "...", or "N more" when the hidden people are only counted by Total. `GetTipText( idx )` answers
  it; pass `TKAVGROUP_OVERFLOW` for the "+N".
- `ShowOverflowMenu` lists the hidden names in a [tkPopupMenu](tkPopupMenu) under the "+N"; picking
  one fires `ItemClick` with that item's index. The group does not open it by itself: call it from
  `OverflowClick`. It does nothing when no item held is hidden. One group's overflow menu can be open
  at a time. `GetOverflowMenu` returns the menu (0 until it is first shown).

## Notifications

| Callback | When |
| --- | --- |
| `SetItemClickCallback` | a click on an item, Enter / Space on it, or a pick in the overflow menu |
| `SetOverflowClickCallback` | a click on the "+N", or Enter / Space on it |
| `SetMessageCallback` | the input stream, with the item under the pointer (or the focus item, for a key); TRUE on a left press or a key claims it |

`TKAVGROUP_MESSAGEINFO.idx` is an item index, `TKAVGROUP_OVERFLOW` or `TKAVGROUP_HIT_NONE`. A click
callback runs last. There is no paint callback: a host that wants its own look draws the avatars
with `tkAvatar_PaintInto`.

## Geometry

- `GetIdealSize` is valid before the control is sized: the shown items and the disc, overlapped or
  spread, plus a margin round the row for the rings and the focus ring. It changes with the items.
- `GetItemRect( idx, rc )` is the item's square, FALSE for a hidden item; `GetOverflowRect` the
  disc's, FALSE without one. Both are control-local.
- `HitTest( x, y )` returns an item index, `TKAVGROUP_OVERFLOW` or `TKAVGROUP_HIT_NONE`.

## Colours and theme

`TKAVGROUP_COLORS` has `BackColor` (under the group, and every cut-out ring), `FocusRingColor`,
`OverflowBack` and `OverflowInk`. `tkAvatarGroup_ThemeColors( t )` maps them from the theme's
Window, FocusRing, Surface and Text. `SetColors` pins the struct (a theme change leaves it) until
`UnpinColors`.

The items take tkAvatar's theme colours (`tkAvatar_ThemeColors`), and the palette half follows the
theme's darkness, pinned or not. There is no per-group custom pair: `TKAVATAR_CUSTOM` draws the
theme's Surface and Text.

## In the Form Designer

The toolbox's **AvatarGroup** (Lists) has the properties above, in the order the form sets them:
Layout, MaxVisible, Total, Overlap, Spacing, Size, Shape, ColorMode, Interactive. Its events are
ItemClick (the default), OverflowClick and Message.

**Edit items** lists the people: each item's text is a name (`AddItem( h, name )`), shown on the
surface as it will be in the program. There is no Bind; pictures, colour keys and presence are set
in code. See [Form Designer](Form-Designer).

## Public declarations

### Constants

`TKAVGROUP_STACK`, `TKAVGROUP_SPREAD` · `TKAVGROUP_OVERFLOW` (-1), `TKAVGROUP_HIT_NONE` (-2) ·
`TKAVGROUP_DEFAULT_SIZE` (32), `TKAVGROUP_DEFAULT_MAX` (5), `TKAVGROUP_DEFAULT_OVERLAP` (20),
`TKAVGROUP_DEFAULT_SPACING` (4) · `TKAVGROUP_RING`, `TKAVGROUP_FOCUSGAP`, `TKAVGROUP_FOCUSTHICK`.

### Types

`TKAVGROUP_COLORS`, `TKAVGROUP_MESSAGEINFO` (the message, the point, the key, the item under it),
`TKAVGROUP_ITEM` (name, colour key, image, presence, data), `TKAVGROUP_STATE` (the widget's state),
and the callback types `AVG_ItemClickCallbackSub`, `AVG_OverflowClickCallbackSub`,
`AVG_MessageCallbackFunc`.

### Procedures

```freebasic
function tkAvatarGroup_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkAvatarGroup_GetID( byval hGroup as TK_WIDGET ptr ) as long
sub tkAvatarGroup_SetEnabled( byval hGroup as TK_WIDGET ptr, byval isEnabled as boolean )
function tkAvatarGroup_InsertItem( byval hGroup as TK_WIDGET ptr, byval nBefore as long, byval Name_ as ustring, byval ColorKey as ustring = "", byval pImage as tkImageFile ptr = 0 ) as long
function tkAvatarGroup_AddItem( byval hGroup as TK_WIDGET ptr, byval Name_ as ustring, byval ColorKey as ustring = "", byval pImage as tkImageFile ptr = 0 ) as long
sub tkAvatarGroup_RemoveItem( byval hGroup as TK_WIDGET ptr, byval idx as long )
sub tkAvatarGroup_Clear( byval hGroup as TK_WIDGET ptr )
function tkAvatarGroup_GetCount( byval hGroup as TK_WIDGET ptr ) as long
function tkAvatarGroup_GetItemName( byval hGroup as TK_WIDGET ptr, byval idx as long ) as ustring
function tkAvatarGroup_FindItemByKey( byval hGroup as TK_WIDGET ptr, byval Key as ustring ) as long
sub tkAvatarGroup_SetItemImageFile( byval hGroup as TK_WIDGET ptr, byval idx as long, byval Path as ustring )
sub tkAvatarGroup_SetItemImagePixels( byval hGroup as TK_WIDGET ptr, byval idx as long, byval w as long, byval h as long, byval argb as ulong ptr )
sub tkAvatarGroup_SetItemPresence( byval hGroup as TK_WIDGET ptr, byval idx as long, byval nPresence as long )
sub tkAvatarGroup_SetItemData( byval hGroup as TK_WIDGET ptr, byval idx as long, byval nData as integer )
function tkAvatarGroup_GetItemData( byval hGroup as TK_WIDGET ptr, byval idx as long ) as integer
sub tkAvatarGroup_SetLayout( byval hGroup as TK_WIDGET ptr, byval nLayout as long )
function tkAvatarGroup_GetLayout( byval hGroup as TK_WIDGET ptr ) as long
sub tkAvatarGroup_SetMaxVisible( byval hGroup as TK_WIDGET ptr, byval nMax as long )
function tkAvatarGroup_GetMaxVisible( byval hGroup as TK_WIDGET ptr ) as long
sub tkAvatarGroup_SetTotal( byval hGroup as TK_WIDGET ptr, byval nTotal as long )
function tkAvatarGroup_GetOverflowCount( byval hGroup as TK_WIDGET ptr ) as long
function tkAvatarGroup_GetShownCount( byval hGroup as TK_WIDGET ptr ) as long
sub tkAvatarGroup_SetOverlap( byval hGroup as TK_WIDGET ptr, byval nPercent as long )
sub tkAvatarGroup_SetSpacing( byval hGroup as TK_WIDGET ptr, byval nDu as long )
sub tkAvatarGroup_SetSize( byval hGroup as TK_WIDGET ptr, byval nDu as long )
sub tkAvatarGroup_SetShape( byval hGroup as TK_WIDGET ptr, byval nShape as long )
sub tkAvatarGroup_SetColorMode( byval hGroup as TK_WIDGET ptr, byval nMode as long )
sub tkAvatarGroup_GetIdealSize( byval hGroup as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkAvatarGroup_GetItemRect( byval hGroup as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkAvatarGroup_GetOverflowRect( byval hGroup as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkAvatarGroup_HitTest( byval hGroup as TK_WIDGET ptr, byval x as long, byval y as long ) as long
sub tkAvatarGroup_SetInteractive( byval hGroup as TK_WIDGET ptr, byval bOn as boolean )
function tkAvatarGroup_GetFocusItem( byval hGroup as TK_WIDGET ptr ) as long
function tkAvatarGroup_GetTipText( byval hGroup as TK_WIDGET ptr, byval idx as long ) as ustring
sub tkAvatarGroup_ShowOverflowMenu( byval hGroup as TK_WIDGET ptr )
function tkAvatarGroup_GetOverflowMenu( byval hGroup as TK_WIDGET ptr ) as TK_MENU ptr
sub tkAvatarGroup_SetItemClickCallback( byval hGroup as TK_WIDGET ptr, byval usersub as AVG_ItemClickCallbackSub )
sub tkAvatarGroup_SetOverflowClickCallback( byval hGroup as TK_WIDGET ptr, byval usersub as AVG_OverflowClickCallbackSub )
sub tkAvatarGroup_SetMessageCallback( byval hGroup as TK_WIDGET ptr, byval userfunc as AVG_MessageCallbackFunc )
sub tkAvatarGroup_GetColors( byval hGroup as TK_WIDGET ptr, byval pColors as TKAVGROUP_COLORS ptr )
sub tkAvatarGroup_SetColors( byval hGroup as TK_WIDGET ptr, byval pColors as TKAVGROUP_COLORS ptr )
function tkAvatarGroup_ThemeColors( byref t as TKTHEME_COLORS ) as TKAVGROUP_COLORS
sub tkAvatarGroup_ApplyTheme( byval hGroup as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkAvatarGroup_UnpinColors( byval hGroup as TK_WIDGET ptr )
```

### See also

- [tkControls](Category-tkControls)
- [tkAvatar](tkAvatar), one avatar, and the drawing the items use
- [tkBadge](tkBadge), the presence marks
- [tkPopupMenu](tkPopupMenu), the overflow menu
- [tkSelectBar](tkSelectBar), the same items-as-data model
- [Form Designer](Form-Designer)
