[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkNavigator**

# tkNavigator

Draws a record navigator: First, Previous, the position ("3 of 120"), Next, Last, New and Delete, in
one strip.

`tkNavigator` is the [tkControls](Category-tkControls) record navigator. It holds a **count** and a
**position** and nothing else: what a move means (loading a record into a form, saving the one on
show) is the program's. A click on a button asks the `Navigate` callback first; allowed, the
navigator takes the new position and count itself.

Every setter is silent. The buttons at an end grey themselves: First and Previous at the first record,
Next and Last at the last, Delete when there is no record. The Form Designer's **Navigator** steps
through an array of the form's records, saving the one on show before it moves.

## Importing

```freebasic
#import "vendor/tkControls/tkNavigator"

using tkNavigator
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and
SDL_image), [tkTheme](tkTheme) and [tkTooltip](tkTooltip).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
dim shared as long gRecords = 120

function Nav_Navigate( byval hNav as TK_WIDGET ptr, byval action as int32, byval target as int32 ) as boolean
    select case action
    case TKNAV_DELETE
        print "delete record " & target
        gRecords -= 1
    case TKNAV_NEW
        print "a new record at " & target       ' target = the index it will have
        gRecords += 1
    case else
        print "go to record " & target          ' First / Previous / Next / Last
    end select
    return true                                 ' Allow: the navigator moves itself
end function

dim as TK_WIDGET ptr nav = tkNavigator_Create( tkHost_Root( host ), 100 )
tkNavigator_SetCount( nav, gRecords )
tkNavigator_SetPosition( nav, 0 )                ' silent: no callback
tkNavigator_SetPositionText( nav, "Record {1} of {2}" )
tkNavigator_SetNavigateCallback( nav, @Nav_Navigate )
tkWidget_SetPos( nav, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkNavigator_GetIdealWidth( nav ), tkHost_Scale( host, 30 ) )
```

## Count and position

- `SetCount( n )` (negative is 0) clamps the position to the new last record.
- `SetPosition( i )`: `-1` is no record; below -1 is -1, past the count is the last. A new navigator
  has no records and position -1.
- Both are silent, and neither checks anything with the program: a program that changes its list
  calls them to keep the navigator in step.
- `GetText` answers what the position part shows now.

## What a click does

A press on an **enabled** button, released on the same button, fires `Navigate( action, target )`:

| Button | `action` | `target` | Enabled when | Allowed, the navigator |
| --- | --- | --- | --- | --- |
| First | `TKNAV_FIRST` | 0 | there are records and the position is not 0 | goes to 0 |
| Previous | `TKNAV_PREV` | position − 1 | there is a record on show and it is not the first | goes to target |
| Next | `TKNAV_NEXT` | position + 1 | the position is before the last | goes to target |
| Last | `TKNAV_LAST` | count − 1 | there are records and the position is not the last | goes to target |
| New | `TKNAV_NEW` | count (the new record's index) | always | adds one to the count and goes to it |
| Delete | `TKNAV_DELETE` | position | there is a record on show | takes one from the count and stays, or goes to the new last; -1 when none are left |

With position -1 and records to show, First, Next (to 0) and Last are enabled.

The callback answers **Allow**: TRUE lets the navigator move as above; FALSE leaves the count and the
position as they were. With no callback, every click is allowed. A program that sets the count and
position itself inside the callback (as a designed form does) answers FALSE so the navigator takes
nothing on top.

A press that slides off its button and is released elsewhere does nothing. The navigator is not a
focus stop and claims no keys, so it never takes the caret from a form's boxes.

## Parts and layout

- The parts, left to right: First, Previous, the position text, Next, Last, New, Delete.
  `SetShowNew( false )` and `SetShowDelete( false )` hide those two; a hidden part takes no room.
- Each button is 28 pixels wide (scaled) and the control's height tall. The text part is as wide as
  the widest text it can show (the count against itself) plus 10 pixels a side, never under 64
  (all scaled). The rest of the control's width is left blank.
- `GetIdealWidth` answers the width the visible parts take. `GetPartRect( part, rc )` answers a
  part's control-local rect (FALSE for a hidden part); `GetPartEnabled( part )` whether a click on
  it would do anything now; `GetHot` the button under the mouse (-1 for none).
- `SetPositionText( fmt )`: `{1}` is the 1-based position ("-" for none), `{2}` the count. The
  default is `"{1} of {2}"`.
- The glyphs (bars and triangles, a plus, a cross) are drawn, not taken from a glyph font.

## Tooltips

Each button has a tooltip, "First", "Previous", "Next", "Last", "New" and "Delete" by default.
`SetButtonTip( part, text )` changes one ("" for none); `GetButtonTip` reads it. They show after 250
ms. A disabled button is not hot and shows none.

## Colours and theme

`TKNAVIGATOR_COLORS` has `BackColor`, `BorderColor`, `ButtonBackHot`, `ButtonBackPressed`,
`GlyphColor`, `GlyphColorDisabled` and `TextColor`. `tkNavigator_ThemeColors( t )` maps them from the
theme's roles (Window, Border, SurfaceHot, Selected, Text, TextDisabled), with any theme recipe for
`"Navigator"` on top; the navigator follows every theme change. `SetColors` pins the struct (a theme
change leaves it) until `UnpinColors`.

`SetFont` sets the position text's font (borrowed; 0 is the host's default).

## In the Form Designer

The toolbox's **Navigator** (in Lists) has the properties Font, ShowNew, ShowDelete and
PositionText, and the event **Navigate**. A form's handler takes `byref Allow as boolean`, TRUE on
entry; setting it to FALSE refuses the click (a confirmation before a delete, for instance):

```freebasic
sub Form.navPeople_Navigate( byval action as int32, byval target as int32, byref Allow as boolean )
    if (action = TKNAV_DELETE) andalso Locked then Allow = false     ' Locked: a field of your form
end sub
```

Set the navigator's **ItemsSource** to an `Array( of <DataType> )` the form holds (a name, such as
`People`) and, when a ListTree or ComboBox shows the same array, its **Follows** to that list. The
generated file then has `navPeople_Refresh( )`, `navPeople_MoveTo( i )`, `navPeople_Current( )` and
`IsDirty( r )`. Your handler runs first; then a move saves a changed record with `SaveTo` (a refusal
keeps the form where it is) and loads the new one, New appends a blank record, Delete removes the one
on show, and the followed list's row follows. See [Form Designer](Form-Designer), Stepping through
records.

## Public declarations

### Constants

`TKNAV_FIRST`, `TKNAV_PREV`, `TKNAV_NEXT`, `TKNAV_LAST`, `TKNAV_NEW`, `TKNAV_DELETE` (the actions, and
the button parts) · `TKNAV_TEXT` (the position part, no action) · `TKNAVIGATOR_PARTS` (7) ·
`TKNAVIGATOR_DEFAULT_BUTTONW` (28), `TKNAVIGATOR_DEFAULT_TEXTPAD` (10),
`TKNAVIGATOR_DEFAULT_TEXTMINW` (64), in design units.

### Types

`TKNAVIGATOR_COLORS`; the callback type `NAV_NavigateCallbackFunc`
(`function( byval hNav as TK_WIDGET ptr, byval action as int32, byval target as int32 ) as boolean`);
`Navigator`, the typed value of the forms layer (`Handle`, `Create`, `Enabled`, `Visible`,
`SetFocus`, `Font`, `ShowNew`, `ShowDelete`, `PositionText`).

### Procedures

```freebasic
function tkNavigator_Create( byval hParent as TK_WIDGET ptr, byval CtrlID as long ) as TK_WIDGET ptr
sub tkNavigator_SetCount( byval hNav as TK_WIDGET ptr, byval n as long )
function tkNavigator_GetCount( byval hNav as TK_WIDGET ptr ) as long
sub tkNavigator_SetPosition( byval hNav as TK_WIDGET ptr, byval i as long )
function tkNavigator_GetPosition( byval hNav as TK_WIDGET ptr ) as long
sub tkNavigator_SetShowNew( byval hNav as TK_WIDGET ptr, byval bShow as boolean )
function tkNavigator_GetShowNew( byval hNav as TK_WIDGET ptr ) as boolean
sub tkNavigator_SetShowDelete( byval hNav as TK_WIDGET ptr, byval bShow as boolean )
function tkNavigator_GetShowDelete( byval hNav as TK_WIDGET ptr ) as boolean
sub tkNavigator_SetPositionText( byval hNav as TK_WIDGET ptr, byval fmt as ustring )
function tkNavigator_GetPositionText( byval hNav as TK_WIDGET ptr ) as ustring
function tkNavigator_GetText( byval hNav as TK_WIDGET ptr ) as ustring
sub tkNavigator_SetButtonTip( byval hNav as TK_WIDGET ptr, byval part as long, byval text as ustring )
function tkNavigator_GetButtonTip( byval hNav as TK_WIDGET ptr, byval part as long ) as ustring
function tkNavigator_GetPartRect( byval hNav as TK_WIDGET ptr, byval part as long, byref rc as TKRECT ) as boolean
function tkNavigator_GetPartEnabled( byval hNav as TK_WIDGET ptr, byval part as long ) as boolean
function tkNavigator_GetIdealWidth( byval hNav as TK_WIDGET ptr ) as long
function tkNavigator_GetHot( byval hNav as TK_WIDGET ptr ) as long
function tkNavigator_GetFont( byval hNav as TK_WIDGET ptr ) as TTF_Font ptr
sub tkNavigator_SetFont( byval hNav as TK_WIDGET ptr, byval f as TTF_Font ptr )
sub tkNavigator_GetColors( byval hNav as TK_WIDGET ptr, byval pColors as TKNAVIGATOR_COLORS ptr )
sub tkNavigator_SetColors( byval hNav as TK_WIDGET ptr, byval pColors as TKNAVIGATOR_COLORS ptr )
function tkNavigator_ThemeColors( byref t as TKTHEME_COLORS ) as TKNAVIGATOR_COLORS
sub tkNavigator_ApplyTheme( byval hNav as TK_WIDGET ptr, byref t as TKTHEME_COLORS )
sub tkNavigator_UnpinColors( byval hNav as TK_WIDGET ptr )
sub tkNavigator_SetNavigateCallback( byval hNav as TK_WIDGET ptr, byval userfunc as NAV_NavigateCallbackFunc )
```

### See also

- [tkControls](Category-tkControls)
- [tkHost](tkHost), [tkTheme](tkTheme), [tkTooltip](tkTooltip)
- [tkListTree](tkListTree), [tkComboBox](tkComboBox), the lists a navigator follows
- [Form Designer](Form-Designer), data binding
