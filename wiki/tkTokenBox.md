[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTokenBox**

# tkTokenBox

Draws an input whose values are chips, typed or picked, each with a remove button.

`tkTokenBox` is the [tkControls](Category-tkControls) token (tag) box. Text typed into it becomes a
**token** on a separator character or Enter, or is completed from a list of suggestions. Each token
shows as a chip with a × that removes it. The chips wrap onto more lines, and they can be walked and
deleted from the keyboard. A token is either one of the control's **items** (it carries the item's
key, ID and data) or **free** text.

Every setter is silent. The user's gestures fire `TokenAdding` / `TokenRemoving` before (vetoable) and
`TokensChanged` once after each gesture. The Form Designer's **TokenBox** binds its value as text.

## Importing

```freebasic
#import "vendor/tkControls/tkTokenBox"

using tkTokenBox
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint) and SDL3), [tkTheme](tkTheme),
[tkTextBox](tkTextBox), `tkMatch` and the suggestion dropdown, `tkItemPopup` (with
[tkListTree](tkListTree)). Add `using tkPaint` for a chip paint callback.

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub People_Changed( byval hBox as TK_WIDGET ptr )
    print "people: " & tkTokenBox_GetTokensText( hBox )      ' "ann;bob;Carol"
end sub

function People_Adding( byval hBox as TK_WIDGET ptr, byref Text as ustring, byref Key as ustring ) as boolean
    return len( Text ) <= 40                ' refuse very long free text (it stays in the input)
end function

dim as TK_WIDGET ptr tb = tkTokenBox_Create( tkHost_Root( host ), 300 )
tkTokenBox_AddItem( tb, "Ann Smith", "ann" )         ' the suggestions: text, key
tkTokenBox_AddItem( tb, "Bob Jones", "bob" )
tkTokenBox_SetPlaceholderText( tb, "Add people" )
tkTokenBox_SetAutoHeight( tb, true, 3 )
tkTokenBox_SetTokensText( tb, "ann;bob" )            ' silent: two item tokens
tkTokenBox_SetTokenAddingCallback( tb, @People_Adding )
tkTokenBox_SetTokensChangedCallback( tb, @People_Changed )
tkWidget_SetPos( tb, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), tkHost_Scale( host, 300 ), tkHost_Scale( host, 32 ) )
```

## The parts

The handle is a container that paints the field, its border and the chips. Inside it, a borderless
single-line [tkTextBox](tkTextBox) (the **input**, `GetInput`) takes the rest of the last line and has
the keyboard focus, so text input and the IME work as in any text box. Focus given to the control goes
to the input. The input's callbacks are the token box's own: use the token box's events.

The suggestions are a popup list that never takes the keyboard focus. While it is up, the keys go to
it: it keeps Up / Down / PgUp / PgDn, Enter, Tab and Escape, and hands every other key, character and
IME composition on to the input. A click on a chip's × while the list is up closes the list and
still removes the chip.

## Tokens

- **What a token is.** Typed text that matches an item's text (case ignored), or a picked suggestion,
  becomes that **item's** token: its text, key, ID and data. Any other text is a **free** token whose
  key is its text (`IsTokenFree`). `SetEntryMode( h, TKTB_ENTRY_ITEMS )` refuses free text;
  `TKTB_ENTRY_FREE` (the default) accepts it, and `TokenAdding` decides.
- **Refusals.** A duplicate key is refused unless `SetAllowDuplicates( h, true )`, and `SetMaxTokens(
  h, n )` refuses the n+1-th. Refused text stays in the input.
- **TokenAdding** may veto, or rewrite the text and key, before a user's token is added.
- **Order.** Tokens keep the order they were added. `GetTokenCount`, `GetTokenText`, `GetTokenKey`,
  `GetTokenID`, `FindToken( h, key )`. `SetTokenInvalid( h, idx, true )` draws a chip with the
  invalid border (a host's validation result).
- **From code:** `AddToken( h, text, key )` (an item's token when the text or key names one, else a
  free one), `RemoveToken`, `ClearTokens`. All are silent.

## Typing

| Input | Effect |
| --- | --- |
| a separator character (`SetTokenSeparators`, default `,;`), typed or pasted | commits every piece before the last separator as a token; the rest stays in the input. A paste of `a;b;c` adds `a` and `b` and leaves `c` |
| Enter | commits the input; with the suggestions up, picks the current suggestion |
| Tab, suggestions up | picks the current suggestion and moves the focus on |
| Down | opens the suggestions; on an empty input, every item not yet a token |
| Backspace, at the start of the input with nothing selected | removes the last token |
| Left, at the start of the input | walks into the chips (chip focus) |
| focus leaving the input | commits it (`SetCommitOnBlur`, on by default) |

**Chip focus** highlights a chip while the input keeps the keyboard focus. Left / Right move between
chips; Right past the last one, or End, returns to the input. Home goes to the first chip. Backspace
removes the chip and moves to the previous one; Delete removes it and stays at its place. Escape, or
any typing, returns to the input. A click on a chip gives it the chip focus and fires `ChipClick`; a
click on its × removes it.

## Suggestions

Typing opens the items that match the input (`SetMatchMode`: `TKMATCH_CONTAINS` by default, or
`TKMATCH_PREFIX`, `_WORDPREFIX`, `_FUZZY`). Items already chosen are left out unless duplicates are
allowed, and at most `SetMaxSuggestions` (8) show. `Suggest( h, text )` runs before the match: a host
can `ClearItems` / `AddItem` there to supply items for the text. `IsSuggesting`, `GetSuggestList` and
`GetSuggestHost` reach the open list.

## Layout

Chips flow left to right and wrap. The input needs at least 48 pixels (scaled) of a line, else it
starts a new one. A chip is at most `SetMaxChipWidth` (200, unscaled) wide, with its text ellipsised.
`SetAutoHeight( h, true, maxLines )` grows and shrinks the control to its lines of chips, up to
`maxLines`. Beyond that, and in a fixed height, the input's line is kept in view and the first lines
scroll off. `GetChipRect` and `GetChipCloseRect` answer in control-local pixels; `GetFocusedChip` the
chip-focus chip, or -1.

## The value

The value is the tokens' keys, in order: `GetTokenKeys` / `SetTokenKeys`, and the bind pair
`GetTokensText` / `SetTokensText`, which join and split on the ValueSeparator (`;`). A key that names
an item gives that item's token; anything else gives a free token. `GetInputText` / `SetInputText`
read and set the text not yet committed.

## Callbacks

| Callback | Fires |
| --- | --- |
| `SetTokenAddingCallback` | `TKB_TokenAddingCallbackFunc( h, byref Text, byref Key ) as boolean`: before a user's token is added; false refuses it |
| `SetTokenRemovingCallback` | `TKB_TokenRemovingCallbackFunc( h, idx ) as boolean`: before a user removes a token; false keeps it |
| `SetTokensChangedCallback` | `TKB_NotifyCallbackSub( h )`: once after each gesture that added or removed tokens |
| `SetInputChangedCallback` | `TKB_NotifyCallbackSub( h )`: the user edited the input |
| `SetChipClickCallback` | `TKB_ChipClickCallbackSub( h, idx )`: a click on a chip (not its ×) |
| `SetSuggestCallback` | `TKB_SuggestCallbackSub( h, text )`: the suggestions are about to be matched against `text` |
| `SetPaintCallback` | `TKB_ChipPaintCallbackSub( ci )`: one chip; `tkTokenBox_PaintChipDefault( ci )` draws the stock one. `TKTOKENBOX_CHIPINFO` carries the chip, text and × rects, the text, and the hot, ×-hot, ×-pressed, focused, free, invalid and enabled flags |

## Colours and theme

`TKTOKENBOX_COLORS` has the field's back, border, focused border, text and placeholder colours. For
the chips it has back (normal, hot, focused), text (normal, focused), the invalid border, the × and
its hot back, and the disabled back and text. `tkTokenBox_ThemeColors( t )` maps them from the
theme's roles (the field `Surface`, chips `SurfaceHot`, the focused chip `Selected`, the invalid border
`Error`). A theme's **TokenBox** recipes apply on top. `SetColors` pins the struct until
`UnpinColors`. The × is two drawn strokes, so it needs no glyph font.

## In the Form Designer

The toolbox's **TokenBox** (Common) has EntryMode, TokenSeparators, ValueSeparator, AllowDuplicates,
MaxTokens, MaxChipWidth, AutoHeight (On, MaxLines), PlaceholderText, CommitOnBlur, MaxSuggestions and
Font. Its events are TokensChanged (the default), TokenAdding and TokenRemoving (the handler sets
`Allow`), InputChanged, ChipClick, Suggest and Paint. Its design-time Items are the suggestions.

**Bind** moves the tokens' keys, as text, into and out of a field of the form's DataType. An
**ItemsSource** or **ItemsField** fills the suggestions from an `Array( of T )`: **DisplayField** is
each item's text and **ValueField** its key. See [Form Designer](Form-Designer), Data binding.

## Public declarations

### Constants

`TKTB_ENTRY_FREE`, `TKTB_ENTRY_ITEMS` · `TKTOKENBOX_DEFAULT_PAD`, `_CHIPPADX`, `_CHIPGAP`, `_CLOSEBOX`,
`_MININPUT`, `_MAXCHIP` (unscaled design units) · `TKTOKENBOX_DEFAULT_SEPARATORS` (`",;"`),
`TKTOKENBOX_DEFAULT_VALUESEP` (`";"`).

### Types

`TKTOKENBOX_COLORS`, `TKTOKENBOX_TOKEN` (Text, Key, id, itemData, bFree, bInvalid), `TKTOKENBOX_ITEM`
(Text, Key, id, itemData), `TKTOKENBOX_CHIPINFO`, `TKTOKENBOX_STATE` (per-instance), and the callback
types `TKB_ChipPaintCallbackSub`, `TKB_TokenAddingCallbackFunc`, `TKB_TokenRemovingCallbackFunc`,
`TKB_NotifyCallbackSub`, `TKB_ChipClickCallbackSub`, `TKB_SuggestCallbackSub`.

### Procedures

```freebasic
function tkTokenBox_ThemeColors( byref t as TKTHEME_COLORS ) as TKTOKENBOX_COLORS
function tkTokenBox_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
function tkTokenBox_GetID( byval h as TK_WIDGET ptr ) as long
function tkTokenBox_GetInput( byval h as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkTokenBox_AddItem( byval h as TK_WIDGET ptr, byval Text as ustring, byval Key as ustring = "", byval id as long = 0, byval itemData as integer = 0 ) as long
sub tkTokenBox_ClearItems( byval h as TK_WIDGET ptr )
function tkTokenBox_GetItemCount( byval h as TK_WIDGET ptr ) as long
function tkTokenBox_AddToken( byval h as TK_WIDGET ptr, byval Text as ustring, byval Key as ustring = "" ) as long
function tkTokenBox_RemoveToken( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkTokenBox_ClearTokens( byval h as TK_WIDGET ptr )
function tkTokenBox_GetTokenCount( byval h as TK_WIDGET ptr ) as long
function tkTokenBox_GetTokenText( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
function tkTokenBox_GetTokenKey( byval h as TK_WIDGET ptr, byval idx as long ) as ustring
function tkTokenBox_GetTokenID( byval h as TK_WIDGET ptr, byval idx as long ) as long
function tkTokenBox_IsTokenFree( byval h as TK_WIDGET ptr, byval idx as long ) as boolean
sub tkTokenBox_SetTokenInvalid( byval h as TK_WIDGET ptr, byval idx as long, byval bInvalid as boolean )
function tkTokenBox_FindToken( byval h as TK_WIDGET ptr, byval Key as ustring ) as long
function tkTokenBox_GetTokenKeys( byval h as TK_WIDGET ptr, keys() as ustring ) as long
sub tkTokenBox_SetTokenKeys( byval h as TK_WIDGET ptr, keys() as ustring )
sub tkTokenBox_SetValueSeparator( byval h as TK_WIDGET ptr, byval Sep as ustring )
function tkTokenBox_GetTokensText( byval h as TK_WIDGET ptr ) as ustring
sub tkTokenBox_SetTokensText( byval h as TK_WIDGET ptr, byval s as ustring )
function tkTokenBox_GetInputText( byval h as TK_WIDGET ptr ) as ustring
sub tkTokenBox_SetInputText( byval h as TK_WIDGET ptr, byval Text as ustring )
sub tkTokenBox_SetEntryMode( byval h as TK_WIDGET ptr, byval nMode as long )
sub tkTokenBox_SetTokenSeparators( byval h as TK_WIDGET ptr, byval Seps as ustring )
sub tkTokenBox_SetAllowDuplicates( byval h as TK_WIDGET ptr, byval bAllow as boolean )
sub tkTokenBox_SetMaxTokens( byval h as TK_WIDGET ptr, byval nMax as long )
sub tkTokenBox_SetMaxChipWidth( byval h as TK_WIDGET ptr, byval nWidth as long )
sub tkTokenBox_SetAutoHeight( byval h as TK_WIDGET ptr, byval bAuto as boolean, byval nMaxLines as long = 4 )
sub tkTokenBox_SetPlaceholderText( byval h as TK_WIDGET ptr, byval Text as ustring )
sub tkTokenBox_SetCommitOnBlur( byval h as TK_WIDGET ptr, byval bCommit as boolean )
sub tkTokenBox_SetMatchMode( byval h as TK_WIDGET ptr, byval nMode as long )
sub tkTokenBox_SetMaxSuggestions( byval h as TK_WIDGET ptr, byval n as long )
sub tkTokenBox_SetFont( byval h as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkTokenBox_SetEnabled( byval h as TK_WIDGET ptr, byval bEnabled as boolean )
function tkTokenBox_GetChipRect( byval h as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkTokenBox_GetChipCloseRect( byval h as TK_WIDGET ptr, byval idx as long, byref rc as TKRECT ) as boolean
function tkTokenBox_GetFocusedChip( byval h as TK_WIDGET ptr ) as long
function tkTokenBox_IsSuggesting( byval h as TK_WIDGET ptr ) as boolean
function tkTokenBox_GetSuggestList( byval h as TK_WIDGET ptr ) as TK_WIDGET ptr
function tkTokenBox_GetSuggestHost( byval h as TK_WIDGET ptr ) as TK_HOST ptr
sub tkTokenBox_GetColors( byval h as TK_WIDGET ptr, byval pColors as TKTOKENBOX_COLORS ptr )
sub tkTokenBox_SetColors( byval h as TK_WIDGET ptr, byval pColors as TKTOKENBOX_COLORS ptr )
sub tkTokenBox_ApplyTheme( byval hBox as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkTokenBox_UnpinColors( byval h as TK_WIDGET ptr )
sub tkTokenBox_PaintChipDefault( byval ci as TKTOKENBOX_CHIPINFO ptr )
sub tkTokenBox_SetPaintCallback( byval h as TK_WIDGET ptr, byval usersub as TKB_ChipPaintCallbackSub )
sub tkTokenBox_SetTokenAddingCallback( byval h as TK_WIDGET ptr, byval userfunc as TKB_TokenAddingCallbackFunc )
sub tkTokenBox_SetTokenRemovingCallback( byval h as TK_WIDGET ptr, byval userfunc as TKB_TokenRemovingCallbackFunc )
sub tkTokenBox_SetTokensChangedCallback( byval h as TK_WIDGET ptr, byval usersub as TKB_NotifyCallbackSub )
sub tkTokenBox_SetInputChangedCallback( byval h as TK_WIDGET ptr, byval usersub as TKB_NotifyCallbackSub )
sub tkTokenBox_SetChipClickCallback( byval h as TK_WIDGET ptr, byval usersub as TKB_ChipClickCallbackSub )
sub tkTokenBox_SetSuggestCallback( byval h as TK_WIDGET ptr, byval usersub as TKB_SuggestCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkTextBox](tkTextBox), the input; [tkAutoComplete](tkAutoComplete), one value with suggestions
- [tkCheckedCombo](tkCheckedCombo) and [tkCheckedList](tkCheckedList), the same choice with check boxes
- [Form Designer](Form-Designer), data binding
