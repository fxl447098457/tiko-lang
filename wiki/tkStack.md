[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkStack**

# tkStack

Lays out controls one after another in a column or a row, the layout of a phone screen.

```freebasic
#import "vendor/tkControls/tkStack"
using tkStack

dim as TK_STACK ptr s = tkStack_Create( page )          ' page: the scroll panel's panel
tkStack_SetPadding( s, 16, 16, 16, 16 ) : tkStack_SetGap( s, 16 )
tkStack_Add( s, lblTitle, 28 )                           ' fixed: 28 design units tall
dim as TK_STACK ptr card = tkStack_Create( pnlCard )     ' a card: a panel with a stack of its own
tkStack_SetPadding( card, 16, 16, 16, 16 ) : tkStack_SetGap( card, 12 )
tkStack_Add( card, txtWeight, 48 )
tkStack_AddFunc( card, lblNote, @NoteHeight )            ' its own height for the width it gets
tkStack_AddStack( s, pnlCard, card )                     ' the card is as tall as its stack
dim as long contentH = tkStack_ApplyToParent( s, true )  ' place everything; the page grows to fit
```

`tkStack` is no widget. It places its items inside a rectangle of their parent and says how tall
the whole column is for a width -- what a [tkScrollPanel](tkScrollPanel) needs as its content
height. [tkLayout](tkLayout) places controls on a designed form by Anchor and Dock; a stack is for
screens built in code, one item under another.

Every size is in **design units**, scaled by the parent's host when applied. An item's extent along
the stack is **fixed** (`tkStack_Add`), the control's **own** for the cross extent it gets
(`tkStack_AddFunc`, a callback in pixels -- a wrapped label), or a **FILL** weight sharing what is
left (`tkStack_AddFill`; the last FILL item takes the remainder, so the shares always add up).
Across, an item takes the stack's whole extent unless `tkStack_SetAlign` gives it a size and START,
CENTER or END. A **hidden** item takes no space and no gap. `tkStack_AddStack` nests a stack inside
a container (a card): the container is as tall as the inner stack measures, and applying the outer
stack applies the inner one; the outer stack owns it. A `size` given to `tkStack_AddStack` wins over
the measure -- a row of a fixed height inside a column. `tkStack_Remove` takes an item out (a list
that grows keeps its "Show more" last by removing and re-adding it).

## Functions

| Function | |
|---|---|
| `tkStack_Create( parent, orient = TK_STACK_VERTICAL ) as TK_STACK ptr` | A stack of `parent`'s children. `TK_STACK_HORIZONTAL` for a row. |
| `tkStack_Destroy( s )` | Frees it and the stacks added to it (not the widgets). |
| `tkStack_SetPadding( s, l, t, r, b )`, `tkStack_SetGap( s, gap )` | Design units: around the items, and between two visible ones. |
| `tkStack_Add( s, w, size )` | A fixed extent along the stack. |
| `tkStack_AddFunc( s, w, fn )` | `fn( w, crossPx ) as long`: its extent in pixels for the cross extent it gets. |
| `tkStack_AddFill( s, w, weight = 1, minSize = 0 )` | A share of what is left, by weight; at least `minSize`. |
| `tkStack_AddStack( s, w, inner, size = 0 )` | A container laid out by its own stack: as long as `inner` measures (one of the same orientation), or `size` design units when it is given. |
| `tkStack_Remove( s, w )` | Takes `w`'s item out, the stack nested for it freed; the widget stays. |
| `tkStack_SetAlign( s, align, crossSize = 0 )` | The LAST item added: `TK_STACK_STRETCH` (the default), `START`, `CENTER`, `END`, and its cross size (design units). |
| `tkStack_SetSpaceBefore( s, space )` | The LAST item added: extra space before it, beyond the gap. |
| `tkStack_Measure( s, crossPx ) as long` | The whole stack's extent along it, padding included, FILL items at their minimum. |
| `tkStack_Layout( s, rc, out )` | Where each item would go inside `rc` (parent-relative pixels), one `TKRECT` per item (an empty one for a hidden item); moves nothing. |
| `tkStack_Apply( s, rc )` | Places every item inside `rc`, and each nested stack inside its container. |
| `tkStack_ApplyToParent( s, bGrow = false ) as long` | Lays it out in the parent's client area -- grown to the stack's extent with `bGrow` (a scroll panel's panel) -- and returns that extent. |
