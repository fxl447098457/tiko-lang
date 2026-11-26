[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkAutoComplete**

# tkAutoComplete

Draws a text box whose typing narrows a list of suggestions dropped below it; or a search box with
a search glyph, a clear button and a delayed `Search` event.

`tkAutoComplete` is the [tkControls](Category-tkControls) autocomplete and search box. It is a
single-line [tkTextBox](tkTextBox) with the TextBox's look (border, focus border, placeholder,
selection), plus a list popup. The list **never takes the keyboard focus**: the text box keeps it
and its text input while the list is up. The list keeps only the navigation and commit keys and
passes every other key, character and IME composition on to the text box, so typing goes on
normally.

The value is either free text or, as a **lookup**, an item whose id is the value. Suggestions come
from stored items the control filters itself (prefix, word-prefix, contains or fuzzy, with the
matched characters highlighted), or from the host: a synchronous callback, or an asynchronous
fetch whose stale answers are refused.

Every setter is silent; only the user's actions notify. The Form Designer's **AutoComplete** binds
the text and, as a lookup, the item's id.

## Importing

```freebasic
#import "vendor/tkControls/tkAutoComplete"

using tkAutoComplete
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme), [tkPopupMenu](tkPopupMenu) (the list's colours),
[tkVScrollBar](tkVScrollBar), [tkTextBox](tkTextBox) and `tkMatch`, the matching module (no SDL;
also used by tkEdit's fuzzy search).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub City_Selected( byval hAC as TK_WIDGET ptr, byval index as long, byval id as longint )
    print "city #" & index & " (id " & id & ")"
end sub

sub Country_NotInList( byval hAC as TK_WIDGET ptr, byref text as const ustring, byref action as long )
    action = AC_KEEP                    ' keep what was typed, with the error border
end sub

sub Find_Search( byval hAC as TK_WIDGET ptr, byref text as const ustring )
    print "filter the grid by: " & text  ' 150 ms after typing stops, or at once on Enter
end sub

' A free-text box with suggestions
dim as TK_WIDGET ptr city = tkAutoComplete_Create( tkHost_Root( host ), 100 )
tkAutoComplete_AddItem( city, "Amsterdam", 1 )
tkAutoComplete_AddItem( city, "Athens", 2 )
tkAutoComplete_AddItem( city, "Auckland", 3 )
tkAutoComplete_SetFilterMode( city, TKAC_FILTER_CONTAINS )
tkAutoComplete_SetPlaceholderText( city, "City" )
tkAutoComplete_SetItemSelectedCallback( city, @City_Selected )

' A lookup: the value is an item's id
dim as TK_WIDGET ptr country = tkAutoComplete_Create( tkHost_Root( host ), 101 )
tkAutoComplete_SetValuePolicy( country, TKAC_VALUE_LIMITTOLIST )
tkAutoComplete_SetDropButton( country, true )
tkAutoComplete_AddItem( country, "Canada", 124 )
tkAutoComplete_AddItem( country, "Chile", 152 )
tkAutoComplete_SetSelectedId( country, 152 )          ' silent: "Chile" in the box
tkAutoComplete_SetNotInListCallback( country, @Country_NotInList )

' A search box with no suggestions
dim as TK_WIDGET ptr find = tkAutoComplete_Create( tkHost_Root( host ), 102 )
tkAutoComplete_SetStyle( find, TKAC_STYLE_SEARCH )
tkAutoComplete_SetSearchCallback( find, @Find_Search )

tkWidget_SetPos( city, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), tkHost_Scale( host, 240 ), tkHost_Scale( host, 32 ) )
```

## Items and matching

- **Items** have a text (shown, matched, put into the box when chosen), an optional dimmed
  right-aligned **detail** (not matched), an **id** (the value), `itemData`, and an enabled flag.
  `AddItem( h, text, id, itemData )`, `AddItemEx( h, it )` with a `TKAUTOCOMPLETE_ITEM`,
  `InsertItem`, `DeleteItem`, `Clear`, `SetItems( texts() )`, `GetItem` / `SetItem`,
  `FindItemById`, `FindItemByText` (case-blind), and `BeginUpdate` / `EndUpdate`. Every change is
  silent and closes an open list. A disabled item is shown dimmed and cannot be chosen.
- **`SetFilterMode`**:
  - `TKAC_FILTER_PREFIX` (the default): the text starts with what was typed.
  - `TKAC_FILTER_WORDPREFIX`: a word starts with it (after a space or punctuation, at a camel-case
    step, or between letters and digits).
  - `TKAC_FILTER_CONTAINS`: anywhere.
  - `TKAC_FILTER_FUZZY`: the typed characters in order, ranked best first.
- **Case and order:** matching is case-blind unless `SetCaseSensitive( true )`. Case folding
  covers Latin-1, Latin Extended-A, Greek and Cyrillic letters. Rows keep the items' order, except in fuzzy mode;
  `SetRankPrefixFirst( true )` puts rows whose text starts with the query first.
- **Folding and narrowing:** item texts are folded once, when added. A keystroke that adds to the
  query filters only the rows of the last one, not every item.
- **`SetMinChars( n )`** (1): the text length below which the list closes. **`SetDelay( ms )`**
  waits that long after the last change before filtering. The default is 0 for stored items and
  200 ms for the host feeds below.
- **`SetMaxResults( n )`** (100, 0 = no cap): rows past the cap are not shown. A status row says so,
  from `SetMoreText` ("{0}+ matches, keep typing", where `{0}` is the rows shown).
  `SetEmptyText` gives a "no matches" row; with none, nothing matching closes the list.
- **Highlighting:** the matched characters are painted in `MatchForeColor`, and also in a bold face
  with `SetMatchBold( h, true, fBold )`.

## The list

- **Opening:** typing opens it. **Down** / **Up** on a closed list open it with the first / last row
  highlighted, or the selected item's row when it is listed. **Alt+Down** opens it with no row
  highlighted (the first, with AutoHighlight). `tkAutoComplete_DropDown` opens it from code.
  `SetShowAllOnEmpty( true )` lists every item when Down is pressed in an empty box.
- **Highlight and preview:** the arrows highlight a row, and with `SetPreviewOnNavigate` (on by
  default) put its text in the box. `GetText` is then the row's text, while `GetQueryText` is still
  what was typed. The arrows wrap through "no row", which brings the typed text back.
  `SetAutoHighlight( true )` highlights the first row as soon as the list opens, so Enter takes it.
- **Keys while the list is open:**

  | Key | Does |
  | --- | --- |
  | Down / Up | the next / previous enabled row, wrapping through "no row" |
  | Page Down / Page Up | a page |
  | Ctrl+Home / Ctrl+End | the first / last row |
  | Enter | commits the highlighted row; with none highlighted, submits the text |
  | Tab / Shift+Tab | commits the highlighted row (if any) and moves the focus on / back |
  | Escape | closes the list and puts the typed text back |
  | Alt+Up | closes the list and keeps the text shown |
  | other keys | Left, Right, Home, End, Backspace, characters and Ctrl+A go to the text box and re-filter |

  A key with Ctrl, Alt or the GUI key is offered to the window's accelerators (`OnPreKey`) first;
  if they take it, the list closes.
- **The mouse:** hovering highlights a row but never previews it. Releasing the button on a row
  commits it. The wheel scrolls three rows a notch. A click in the text box closes the list and
  places the caret. The list closes when the focus leaves the box.
- **Sizing:** `SetListMaxRows` (8) rows show before the list scrolls; `SetListItemHeight` (24,
  unscaled). `SetListWidth( 0 )` gives the control's width, `-1` the widest row up to
  `SetListMaxWidth` (480), and a positive value a fixed width. The list opens below the control, or
  above when the screen ends first.
- **Committing a row:** the list closes first; then the text goes in, the row's item becomes the
  selected item, and `TextChanged( true )` and `ItemSelected( index, id )` fire, in that order.

## Text and value

- `GetText` / `SetText` (silent; selects nothing), `GetQueryText`, `GetSelectedIndex` /
  `SetSelectedIndex`, `GetSelectedId` / `SetSelectedId( id )`. `SetSelectedId` returns FALSE, and
  empties the box, when no item has that id.
- **`SetValuePolicy( TKAC_VALUE_FREETEXT )`** (the default): the value is the text. Typing
  unselects the item. Leaving the box (the focus moving on, or Enter on a closed list) with text
  that equals an item's text, ignoring case, selects that item, as a commit does.
- **`SetValuePolicy( TKAC_VALUE_LIMITTOLIST )`** makes the control a **lookup**: the value is an
  item.
  - The value stands while the user types and is settled when they leave the box:
    - the selected item's own text, or an empty box, stands;
    - emptying the box clears the value (`ItemSelected( -1, NoValueId )`);
    - a full match selects its item;
    - anything else fires **`NotInList( text, action )`**.
  - The handler sets `action`:
    - `AC_REVERT` (the default) puts the selected item's text back;
    - `AC_ACCEPT` says the handler added an item for the text, which is then looked up and selected;
    - `AC_KEEP` keeps the text, unselected, with the border in `ErrorColor` until the next change
      (`GetError`).
  - LimitToList also turns `AutoHighlight` and `ShowAllOnEmpty` on.
- `SetNoValueId` sets what `GetSelectedId` answers while nothing is selected (0 by default).
- `SetSelectedItem( id, text )` sets a value the items do not hold, such as an asynchronous lookup's
  value loaded from a record. It stands while its text does.
- **Enter on a closed list** settles the value as leaving does. It then fires
  `Submit( text, index )`, where index is the selected item while the text is still its, else −1,
  if there is a Submit or a Search handler. With neither, Enter is not claimed, so a dialog's
  default button still works.

## Inline completion

`SetMode( TKAC_MODE_APPEND )` completes the box inline, with no list. It adds the rest of the first
enabled item whose text starts with what was typed, **selected**, so the next character types over
it. The typed part keeps the user's case, and the completion can be undone.

- There is no completion after Backspace or Delete, during IME composition, or when the caret is
  not at the end.
- Escape takes the completion away.

`TKAC_MODE_SUGGESTAPPEND` does both: the list filters by what was typed, and the box shows the
completion. `TKAC_MODE_SUGGEST` (the default) lists only.

## The search face

`SetStyle( TKAC_STYLE_SEARCH )` turns on the search face:

- a **search glyph** at the left;
- a **clear button** at the right, shown only while there is text;
- **Escape clears** the box when the list is closed and there is text. On an empty box Escape is
  left to the dialog. With the list open, the first Escape closes the list and the second clears.

Each part can be set on its own: `SetSearchGlyph( codepoint )` (0 = none), `SetClearButton`,
`SetClearOnEscape`. `TKAC_STYLE_INPUT` turns all three off.

- **`Search( text )`** (`SetSearchCallback`, in either style) fires:
  - `SetSearchDelay` ms (150) after the user's last change, including the change to an empty box,
    so a filter driven by it resets;
  - at once on Enter, the clear button, Escape-clear and a commit.

  `SetSearchDelay( 0 )` fires it on every change.
- **The glyphs** are drawn as shapes (a lens, a cross, a chevron) until a glyph font is set with
  `SetGlyphFont` or `ApplyFonts`; then they are the font's characters (`TK_ICON_SEARCH`,
  `TK_ICON_CLOSE`, `TK_ICON_CHEVRON_DOWN`).
- **`SetDropButton( true )`** adds a chevron at the far right, with the clear button to its left. A
  click lists every item with the selected one highlighted; a second click closes the list.
- **Geometry:** `GetGlyphRect`, `GetClearRect` and `GetDropRect` give the cells in control-local
  pixels. The text box's margins keep its text clear of them.

## Rows from the host

- **`SetItemsNeededCallback`** lets the host filter. `ItemsNeeded( query )` fires after the delay;
  inside it the host calls `ClearResults` and then `AddResult( text, id, detail )` for each row,
  already filtered and in its own order.
- **`SetPopulateCallback`** is asynchronous. `Populate( query, requestId )` fires; the host starts
  its fetch and returns.
  - Later, on the UI thread (`tkApp_RunOnUI` from a worker), it calls `BeginSupply( requestId )`.
    That returns FALSE when a newer request has replaced this one: the answer must then be dropped.
  - Otherwise the host calls `AddResult` for each row, then `EndSupply`.
  - While an answer is awaited, the last rows stay up under a status row (`SetStatusText`,
    "Searching..." by default).
  - `CancelPending`, a newer request, or text below MinChars makes the old id stale.
    `GetPendingRequest` gives the id being awaited.
  - The control owns no thread, and the host must not call into a destroyed control.
- **Supplied rows are not items.** `GetResultItem( row )` returns −1 for them; `GetResultText` and
  `GetResultId` read them. Committing one makes its id the value: `GetSelectedId` returns it,
  `GetSelectedIndex` returns −1, and `ItemSelected( -1, id )` fires. Setting either callback clears the
  rows the earlier feed gave. With both callbacks 0, the stored items are used again.
- **`SetSource( @src )`** fills the stored items from a `TKAUTOCOMPLETE_SOURCE`: a procedure table
  of `pCtx`, `Count`, `GetText`, `GetId` (0 = the index is the id) and `GetDetail` (0 = none). The
  control reads the source in; call `SourceChanged` after the data changes.

## Notifications

| Callback | When |
| --- | --- |
| `SetItemSelectedCallback` | a row committed (keys or mouse), a full match selected on leaving, a lookup emptied (`-1`) |
| `SetTextChangedCallback` | the user changed the text (`bFromList` FALSE) or a commit put it in (TRUE) |
| `SetSubmitCallback` | Enter with no row highlighted, or on a closed list |
| `SetSearchCallback` | the search text: after SearchDelay, or at once (see above) |
| `SetHighlightCallback` | the highlighted row changed by keys or the mouse: its item, or −1 (no row, or a host-supplied row) |
| `SetDropDownCallback` | the list opened or closed, for any reason |
| `SetNotInListCallback` | a lookup was left with text that is no item's |
| `SetItemsNeededCallback` | the synchronous feed: give the rows for this query |
| `SetPopulateCallback` | the asynchronous feed: start fetching the rows for this query |

Do not replace the text box's own callbacks (`tkTextBox_Set*Callback` on `GetEditHandle`), because
the control runs on them. `GetEditHandle` is there for anything else the TextBox offers.

## Colours and theme

`TKAUTOCOMPLETE_COLORS` holds:

- the text box's nine colours (fore, back, placeholder, border, focus border, outer back,
  selection back and fore, disabled fore);
- the list's back, fore and border, the highlighted row's back and fore, and the disabled row's
  fore;
- `MatchForeColor`, `DetailForeColor` (details and status rows), `GlyphColor` / `GlyphColorHot`
  (the glyphs and buttons) and `ErrorColor`.

`tkAutoComplete_ThemeColors( t )` maps them from the theme's roles (the list's from the popup
roles, the match colour from Accent, the error colour from Error); theme recipes apply under
"AutoComplete". `SetColors` pins the struct, so a theme change leaves it, until `UnpinColors`. The
text box's shape (corner radius, border width) follows the theme as a TextBox's does. Sizes are in
design units, scaled at use; a scale change closes the list.

## In the Form Designer

The toolbox's **AutoComplete** (under Common) has these properties:

- **Style, Mode and ValuePolicy** come first, because Style and ValuePolicy set defaults.
- **The rest:** FilterMode, DropButton, CaseSensitive, RankPrefixFirst, MinChars, MaxResults,
  SearchDelay, PreviewOnNavigate, PlaceholderText, EmptyText, ListMaxRows, ListItemHeight,
  ListWidth and Font.
- **Code only:** ClearButton, ClearOnEscape, AutoHighlight and ShowAllOnEmpty follow from Style and
  ValuePolicy.
- **Events:** ItemSelected (the default event), TextChanged, Submit, Search, Highlight, DropDown,
  NotInList, ItemsNeeded and Populate.

Binding:

- **Bind** moves the text into and out of a field of the form's DataType.
- **BindValue**, offered when ValuePolicy is LimitToList, moves the selected item's id. A lookup can
  bind both: LoadFrom sets the text, then the id.
- **The list** fills from an `Array( of T )` (ItemsSource or ItemsField) with **DisplayField** as
  each item's text and **ValueField** as its id.
- **Fill before LoadFrom.** With an ItemsSource the program calls `<name>_Fill( )`, and it must do so
  before `LoadFrom`; otherwise the id finds no item and the box comes up empty.
- **Design-time Items** become AddItem calls.

See [Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKAC_STYLE_INPUT`, `TKAC_STYLE_SEARCH` · `TKAC_MODE_SUGGEST`, `TKAC_MODE_APPEND`,
`TKAC_MODE_SUGGESTAPPEND` · `TKAC_VALUE_FREETEXT`, `TKAC_VALUE_LIMITTOLIST` · `TKAC_FILTER_PREFIX`,
`TKAC_FILTER_WORDPREFIX`, `TKAC_FILTER_CONTAINS`, `TKAC_FILTER_FUZZY` · `AC_REVERT`, `AC_ACCEPT`,
`AC_KEEP` · `TKAUTOCOMPLETE_DEFAULT_LISTITEMHEIGHT` (24), `TKAUTOCOMPLETE_DEFAULT_LISTMAXROWS` (8),
`TKAUTOCOMPLETE_DEFAULT_LISTMAXWIDTH` (480), `TKAUTOCOMPLETE_DEFAULT_MAXRESULTS` (100),
`TKAUTOCOMPLETE_DEFAULT_SEARCHDELAY` (150), `TKAUTOCOMPLETE_ROWPAD`, `TKAUTOCOMPLETE_DETAILGAP`,
`TKAUTOCOMPLETE_GLYPHCELL`, `TKAUTOCOMPLETE_GLYPHSIZE`.

### Types

`TKAUTOCOMPLETE_COLORS`, `TKAUTOCOMPLETE_ITEM` (`text`, `detail`, `id`, `itemData`, `enabled`),
`TKAUTOCOMPLETE_SOURCE`, and the callback types `AC_ItemSelectedSub`, `AC_TextChangedSub`,
`AC_SubmitSub`, `AC_SearchSub`, `AC_HighlightSub`, `AC_DropDownSub`, `AC_NotInListSub`,
`AC_ItemsNeededSub`, `AC_PopulateSub`. The Form Designer's typed wrapper is `AutoComplete`
(`tkAutoComplete.forms.tiko`).

### Procedures

```freebasic
function tkAutoComplete_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkAutoComplete_GetID( byval hAC as TK_WIDGET ptr ) as long
function tkAutoComplete_GetEditHandle( byval hAC as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkAutoComplete_GetListHandle( byval hAC as TK_WIDGET ptr ) as TK_HOST ptr
function tkAutoComplete_GetListGeneration( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetFilterMode( byval hAC as TK_WIDGET ptr, byval v as long )
function tkAutoComplete_GetFilterMode( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetCaseSensitive( byval hAC as TK_WIDGET ptr, byval v as boolean )
function tkAutoComplete_GetCaseSensitive( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_SetRankPrefixFirst( byval hAC as TK_WIDGET ptr, byval v as boolean )
function tkAutoComplete_GetRankPrefixFirst( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_SetMinChars( byval hAC as TK_WIDGET ptr, byval v as long )
function tkAutoComplete_GetMinChars( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetDelay( byval hAC as TK_WIDGET ptr, byval v as long )
function tkAutoComplete_GetDelay( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetMaxResults( byval hAC as TK_WIDGET ptr, byval v as long )
function tkAutoComplete_GetMaxResults( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetAutoHighlight( byval hAC as TK_WIDGET ptr, byval v as boolean )
function tkAutoComplete_GetAutoHighlight( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_SetPreviewOnNavigate( byval hAC as TK_WIDGET ptr, byval v as boolean )
function tkAutoComplete_GetPreviewOnNavigate( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_SetEmptyText( byval hAC as TK_WIDGET ptr, byval s as ustring )
function tkAutoComplete_GetEmptyText( byval hAC as TK_WIDGET ptr ) as ustring
sub tkAutoComplete_SetMoreText( byval hAC as TK_WIDGET ptr, byval s as ustring )
function tkAutoComplete_GetMoreText( byval hAC as TK_WIDGET ptr ) as ustring
sub tkAutoComplete_SetPlaceholderText( byval hAC as TK_WIDGET ptr, byval s as ustring )
function tkAutoComplete_GetPlaceholderText( byval hAC as TK_WIDGET ptr ) as ustring
function tkAutoComplete_AddItemEx( byval hAC as TK_WIDGET ptr, byref it as const TKAUTOCOMPLETE_ITEM ) as long
function tkAutoComplete_AddItem( byval hAC as TK_WIDGET ptr, byval text as ustring, byval id as longint = 0, byval itemData as integer = 0 ) as long
function tkAutoComplete_InsertItem( byval hAC as TK_WIDGET ptr, byval idx as long, byref it as const TKAUTOCOMPLETE_ITEM ) as long
function tkAutoComplete_DeleteItem( byval hAC as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkAutoComplete_Clear( byval hAC as TK_WIDGET ptr )
sub tkAutoComplete_SetItems( byval hAC as TK_WIDGET ptr, texts() as ustring )
function tkAutoComplete_GetCount( byval hAC as TK_WIDGET ptr ) as long
function tkAutoComplete_GetItem( byval hAC as TK_WIDGET ptr, byval idx as long, byref it as TKAUTOCOMPLETE_ITEM ) as boolean
function tkAutoComplete_SetItem( byval hAC as TK_WIDGET ptr, byval idx as long, byref it as const TKAUTOCOMPLETE_ITEM ) as boolean
function tkAutoComplete_GetItemText( byval hAC as TK_WIDGET ptr, byval idx as long ) as ustring
function tkAutoComplete_FindItemById( byval hAC as TK_WIDGET ptr, byval id as longint ) as long
function tkAutoComplete_FindItemByText( byval hAC as TK_WIDGET ptr, byval text as ustring ) as long
sub tkAutoComplete_BeginUpdate( byval hAC as TK_WIDGET ptr )
sub tkAutoComplete_EndUpdate( byval hAC as TK_WIDGET ptr )
function tkAutoComplete_IsDroppedDown( byval hAC as TK_WIDGET ptr ) as boolean
function tkAutoComplete_DropDown( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_CloseUp( byval hAC as TK_WIDGET ptr )
function tkAutoComplete_GetResultCount( byval hAC as TK_WIDGET ptr ) as long
function tkAutoComplete_GetMatchCount( byval hAC as TK_WIDGET ptr ) as long
function tkAutoComplete_GetResultItem( byval hAC as TK_WIDGET ptr, byval row as long ) as long
function tkAutoComplete_GetHighlight( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetHighlight( byval hAC as TK_WIDGET ptr, byval row as long )
function tkAutoComplete_GetListItemRect( byval hAC as TK_WIDGET ptr, byval row as long, byref rc as TKRECT ) as boolean
function tkAutoComplete_GetListTopIndex( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetListMaxRows( byval hAC as TK_WIDGET ptr, byval v as long )
function tkAutoComplete_GetListMaxRows( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetListItemHeight( byval hAC as TK_WIDGET ptr, byval v as long )
function tkAutoComplete_GetListItemHeight( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetListWidth( byval hAC as TK_WIDGET ptr, byval v as long )
function tkAutoComplete_GetListWidth( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetListMaxWidth( byval hAC as TK_WIDGET ptr, byval v as long )
function tkAutoComplete_GetListMaxWidth( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetTextChangedCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_TextChangedSub )
sub tkAutoComplete_SetSubmitCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_SubmitSub )
sub tkAutoComplete_SetItemSelectedCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_ItemSelectedSub )
sub tkAutoComplete_SetHighlightCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_HighlightSub )
sub tkAutoComplete_SetSearchCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_SearchSub )
sub tkAutoComplete_SetDropDownCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_DropDownSub )
sub tkAutoComplete_SetStyle( byval hAC as TK_WIDGET ptr, byval nStyle as long )
function tkAutoComplete_GetStyle( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetClearButton( byval hAC as TK_WIDGET ptr, byval bShow as boolean )
function tkAutoComplete_GetClearButton( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_SetClearOnEscape( byval hAC as TK_WIDGET ptr, byval b as boolean )
function tkAutoComplete_GetClearOnEscape( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_SetSearchGlyph( byval hAC as TK_WIDGET ptr, byval code as ulong )
function tkAutoComplete_GetSearchGlyph( byval hAC as TK_WIDGET ptr ) as ulong
sub tkAutoComplete_SetSearchDelay( byval hAC as TK_WIDGET ptr, byval ms as long )
function tkAutoComplete_GetSearchDelay( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetGlyphFont( byval hAC as TK_WIDGET ptr, byval f as TTF_Font ptr )
function tkAutoComplete_GetGlyphFont( byval hAC as TK_WIDGET ptr ) as TTF_Font ptr
function tkAutoComplete_GetGlyphRect( byval hAC as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
function tkAutoComplete_GetDropRect( byval hAC as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkAutoComplete_SetDropButton( byval hAC as TK_WIDGET ptr, byval bShow as boolean )
function tkAutoComplete_GetDropButton( byval hAC as TK_WIDGET ptr ) as boolean
function tkAutoComplete_GetClearRect( byval hAC as TK_WIDGET ptr, byref rc as TKRECT ) as boolean
sub tkAutoComplete_GetColors( byval hAC as TK_WIDGET ptr, byval pColors as TKAUTOCOMPLETE_COLORS ptr )
sub tkAutoComplete_SetColors( byval hAC as TK_WIDGET ptr, byval pColors as TKAUTOCOMPLETE_COLORS ptr )
function tkAutoComplete_ThemeColors( byref t as TKTHEME_COLORS ) as TKAUTOCOMPLETE_COLORS
sub tkAutoComplete_ApplyTheme( byval hAC as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkAutoComplete_UnpinColors( byval hAC as TK_WIDGET ptr )
function tkAutoComplete_GetFont( byval hAC as TK_WIDGET ptr ) as TTF_Font ptr
sub tkAutoComplete_SetFont( byval hAC as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkAutoComplete_ApplyFonts( byval hAC as TK_WIDGET ptr, byval fText as TTF_Font ptr, byval fGlyph as TTF_Font ptr )
sub tkAutoComplete_SetMatchBold( byval hAC as TK_WIDGET ptr, byval bBold as boolean, byval fBold as TTF_Font ptr = 0 )
function tkAutoComplete_GetMatchBold( byval hAC as TK_WIDGET ptr ) as boolean
function tkAutoComplete_GetText( byval hAC as TK_WIDGET ptr ) as ustring
sub tkAutoComplete_SetText( byval hAC as TK_WIDGET ptr, byval s as ustring )
function tkAutoComplete_GetQueryText( byval hAC as TK_WIDGET ptr ) as ustring
function tkAutoComplete_GetSelectedIndex( byval hAC as TK_WIDGET ptr ) as long
function tkAutoComplete_SetSelectedIndex( byval hAC as TK_WIDGET ptr, byval idx as long ) as boolean
function tkAutoComplete_GetSelectedId( byval hAC as TK_WIDGET ptr ) as longint
sub tkAutoComplete_SetMode( byval hAC as TK_WIDGET ptr, byval nMode as long )
function tkAutoComplete_GetMode( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetValuePolicy( byval hAC as TK_WIDGET ptr, byval nPolicy as long )
function tkAutoComplete_GetValuePolicy( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetShowAllOnEmpty( byval hAC as TK_WIDGET ptr, byval b as boolean )
function tkAutoComplete_GetShowAllOnEmpty( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_SetNoValueId( byval hAC as TK_WIDGET ptr, byval id as longint )
function tkAutoComplete_GetNoValueId( byval hAC as TK_WIDGET ptr ) as longint
function tkAutoComplete_SetSelectedId( byval hAC as TK_WIDGET ptr, byval id as longint ) as boolean
function tkAutoComplete_GetError( byval hAC as TK_WIDGET ptr ) as boolean
sub tkAutoComplete_SetNotInListCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_NotInListSub )
sub tkAutoComplete_SetItemsNeededCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_ItemsNeededSub )
sub tkAutoComplete_SetPopulateCallback( byval hAC as TK_WIDGET ptr, byval cb as AC_PopulateSub )
sub tkAutoComplete_ClearResults( byval hAC as TK_WIDGET ptr )
sub tkAutoComplete_AddResult( byval hAC as TK_WIDGET ptr, byval text as ustring, byval id as longint = 0, byval detail as ustring = "" )
function tkAutoComplete_BeginSupply( byval hAC as TK_WIDGET ptr, byval requestId as long ) as boolean
sub tkAutoComplete_EndSupply( byval hAC as TK_WIDGET ptr )
sub tkAutoComplete_CancelPending( byval hAC as TK_WIDGET ptr )
function tkAutoComplete_GetPendingRequest( byval hAC as TK_WIDGET ptr ) as long
sub tkAutoComplete_SetStatusText( byval hAC as TK_WIDGET ptr, byval s as ustring )
function tkAutoComplete_GetStatusText( byval hAC as TK_WIDGET ptr ) as ustring
function tkAutoComplete_GetResultText( byval hAC as TK_WIDGET ptr, byval row as long ) as ustring
function tkAutoComplete_GetResultId( byval hAC as TK_WIDGET ptr, byval row as long ) as longint
sub tkAutoComplete_SetSource( byval hAC as TK_WIDGET ptr, byval src as TKAUTOCOMPLETE_SOURCE ptr )
sub tkAutoComplete_SourceChanged( byval hAC as TK_WIDGET ptr )
sub tkAutoComplete_SetSelectedItem( byval hAC as TK_WIDGET ptr, byval id as longint, byval text as ustring )
```

### See also

- [tkControls](Category-tkControls)
- [tkTextBox](tkTextBox), the text box inside; [tkComboBox](tkComboBox), the pick-from-a-closed-list control
- [tkHost](tkHost), [tkTheme](tkTheme), [tkPopupMenu](tkPopupMenu)
- [Form Designer](Form-Designer), data binding
