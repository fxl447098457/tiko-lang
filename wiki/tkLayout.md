[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkLayout**

# tkLayout

Keeps controls placed as the window resizes, by Anchor or Dock.

`tkLayout` keeps controls where they belong when their parent is resized or the scale changes. Each control has a rectangle in **design units** and either an **anchor** or a **dock**. A design unit is scaled when the layout is applied, so one layout serves every display scale and you never call `tkHost_Scale` for a laid-out control.

Coordinates are relative to the parent widget's origin. The parent is called a **container**, and must be declared to the layout with the size its children were designed against.

The arithmetic is one pure procedure, `tkLayout_Compute`. The [Form Designer](Form-Designer)'s canvas and a running program both use it, so they cannot disagree.

## Anchor rules

An anchor keeps an edge's distance from the matching edge of the parent. The flags are `TK_ANCHOR_LEFT`, `TK_ANCHOR_TOP`, `TK_ANCHOR_RIGHT` and `TK_ANCHOR_BOTTOM`, joined with `or`. The default, `TK_ANCHOR_DEFAULT`, is left and top.

Each axis is worked out on its own, from how much the container has grown or shrunk since the design size:

| Anchored on the axis | What the control does as the container grows |
|---|---|
| Both edges (left and right, or top and bottom) | Stretches: the far edge follows the container. |
| Far edge only (right, or bottom) | Moves: both edges follow the container. |
| Near edge only (left, or top) | Stays where it is. |
| Neither (`TK_ANCHOR_NONE`) | Stays centred: moves by half of the growth. |

A control's far edge never ends before its near edge.

## Dock rules

A dock takes a slice off the container's remaining client area. Docks are taken in the order the controls were added to the layout.

| Dock | Slice taken |
|---|---|
| `TK_DOCK_TOP` | The full width of what is left, as tall as the control's design height (`cy`), from the top. |
| `TK_DOCK_BOTTOM` | The full width of what is left, as tall as `cy`, from the bottom. |
| `TK_DOCK_LEFT` | The full height of what is left, as wide as the control's design width (`cx`), from the left. |
| `TK_DOCK_RIGHT` | The full height of what is left, as wide as `cx`, from the right. |
| `TK_DOCK_FILL` | Whatever is left after every other dock has taken its slice, whatever the order. |
| `TK_DOCK_NONE` | Not docked: the control follows its anchor. |

A slice is cut short when less than its size remains. A docked control's other dimension is ignored, since the slice already fixes it. Docked controls ignore their anchor.

A container can restrict the area docks may use, for a frame that leaves a margin. Give `tkLayout_AddContainer` a client function and the docks use the rectangle it answers. [tkGroupBox](tkGroupBox)'s `tkGroupBox_GetClientRect` has the right shape.

## Importing

```freebasic
#import "vendor/tkControls/tkLayout"

using tkLayout
using tkHost
```

The module brings in [tkHost](tkHost) and [tkSplitter](tkSplitter). [tkForms](tkForms) imports it for you and gives each form a layout.

## Example

A form with a docked toolbar strip, a left pane with a draggable splitter, a fill area, and a button that holds the bottom right corner. `OnSize` and `OnScale` apply the layout.

```freebasic
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkLayout"
#import "vendor/tkControls/tkPanel"
#import "vendor/tkControls/tkButton"
using tkApp
using tkLayout
using tkPanel
using tkButton
using tkHost
using tkPaint
using tkSplitter

dim shared as TK_LAYOUT ptr gLayout

sub OnSize( byval f as TK_FORM ptr, byval cx as long, byval cy as long )
    tkLayout_Apply( gLayout )
end sub

sub OnScale( byval f as TK_FORM ptr, byval fOld as single, byval fNew as single )
    tkLayout_Apply( gLayout )
end sub

dim as TKAPP_OPTIONS opts
if tkApp_Init( opts ) = false then end 98
dim as TK_FORM ptr f = tkApp_NewForm( "Layout", 720, 480 )
dim as TK_WIDGET ptr root_ = tkForm_Widget( f )

dim as TK_WIDGET ptr top = tkPanel_Create( root_, 1 )
dim as TK_WIDGET ptr left_ = tkPanel_Create( root_, 2 )
dim as TK_WIDGET ptr bar = tkSplitter_Create( root_, 3, TKSPLITTER_VERTICAL )
dim as TK_WIDGET ptr body = tkPanel_Create( root_, 4 )
dim as TK_WIDGET ptr ok = tkButton_Create( body, 5 )
tkButton_SetText( ok, "OK" )

gLayout = tkLayout_Create( )
tkLayout_AddContainer( gLayout, root_, 720, 480 )
tkLayout_Add( gLayout, top, 0, 0, 0, 36, TK_ANCHOR_NONE, TK_DOCK_TOP )
tkLayout_Add( gLayout, left_, 0, 0, 160, 0, TK_ANCHOR_NONE, TK_DOCK_LEFT )
tkLayout_Add( gLayout, bar, 0, 0, 5, 0, TK_ANCHOR_NONE, TK_DOCK_LEFT )
tkLayout_Add( gLayout, body, 0, 0, 0, 0, TK_ANCHOR_NONE, TK_DOCK_FILL )
tkLayout_BindSplitter( gLayout, bar, left_ )

tkLayout_AddContainer( gLayout, body, 555, 444 )   ' the body's design size
tkLayout_Add( gLayout, ok, 450, 400, 90, 32, TK_ANCHOR_RIGHT or TK_ANCHOR_BOTTOM )

tkForm_OnSize( f, @OnSize )
tkForm_OnScaleChanged( f, @OnScale )
dim as long code = tkApp_Run( f )
tkLayout_Destroy( gLayout )
end code
```

The toolchain's `examples/tkControls/tkLayout/` has a fuller demo, with a tab control, a group box whose docks stay inside its frame, and anchors on all four sides.

## Containers

Declare the parent with `tkLayout_AddContainer( layout, parent, designW, designH [, clientFn] )` before adding anything that sits inside it. `tkLayout_Apply` works through the containers in the order they were added, so a parent is placed before its children are laid out against its new size. Adding the same widget again updates its design size and client function.

A control is laid out by the container that is its parent widget. If its parent was never declared, nothing moves it.

`designW` and `designH` are the size the children's design rectangles were drawn against. How far the container has grown since then is what the anchors react to.

## tkLayout_Compute

```freebasic
sub tkLayout_Compute( byval items as TKLAYOUT_ITEM ptr, byval n as long, _
                      byval designW as long, byval designH as long, _
                      byval cw as long, byval ch as long, byref rcDock as TKRECT, _
                      byval fScale as single, byval rcOut as TKRECT ptr )
```

The whole layout rule, with no widgets involved. `items` is an array of `n` `TKLAYOUT_ITEM`s. `designW` and `designH` are the container size the items were designed against, `cw` and `ch` its size now in pixels, `rcDock` the area docks may take in the container's pixels, and `fScale` the scale. It writes one pixel rectangle per item to `rcOut`, which must hold `n` of them. Rectangles are in the container's pixels.

```freebasic
dim as TKLAYOUT_ITEM items( 0 to 1 )
items(0).dock = TK_DOCK_TOP
items(0).cy = 40
items(1).dock = TK_DOCK_FILL

dim as TKRECT rcDock, rects( 0 to 1 )
tkRect_Set( rcDock, 0, 0, 800, 600 )
tkLayout_Compute( @items(0), 2, 400, 300, 800, 600, rcDock, 1.0, @rects(0) )
' rects(0) is 0,0 to 800,40 and rects(1) is 0,40 to 800,600
```

## tkLayout_BindSplitter

`tkLayout_BindSplitter( layout, splitter, pane )` ties a [tkSplitter](tkSplitter) to a docked pane. Dragging the bar resizes the pane, and the docks reflow around it.

Both must be controls of this layout, docked on the same side, with the bar added straight after the pane. The bar's position-changed callback belongs to the layout from then on.

The new size is stored back in design units, so it survives a scale change. Destroying the layout removes its bindings.

## Behaviour notes

- `tkLayout_Add` adds a control with its design rectangle (`x`, `y`, `cx`, `cy`), an anchor and a dock. Adding a control again replaces its entry.
- `tkLayout_Remove` takes a control out of the layout. Its widget is not touched.
- `tkLayout_SetAnchor`, `tkLayout_SetDock` and `tkLayout_SetDesignRect` change an entry that is already in the layout and do nothing otherwise. They take effect at the next `tkLayout_Apply`.
- `tkLayout_GetAnchor` and `tkLayout_GetDock` return `TK_ANCHOR_NONE` and `TK_DOCK_NONE` for a control the layout does not know. `tkLayout_GetDesignRect` returns false for one.
- `tkLayout_Apply` places every control of every container, with `tkWidget_SetPos`. Call it from the form's size and scale-changed handlers. [tkForms](tkForms) does this for you.
- `tkLayout_Create` returns a layout you own: free it with `tkLayout_Destroy`. A `FormBase` frees its own.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Constants

```freebasic
const as long TK_ANCHOR_NONE   = 0
const as long TK_ANCHOR_LEFT   = 1
const as long TK_ANCHOR_TOP    = 2
const as long TK_ANCHOR_RIGHT  = 4
const as long TK_ANCHOR_BOTTOM = 8
const as long TK_ANCHOR_DEFAULT = TK_ANCHOR_LEFT or TK_ANCHOR_TOP

enum
    TK_DOCK_NONE = 0
    TK_DOCK_TOP
    TK_DOCK_BOTTOM
    TK_DOCK_LEFT
    TK_DOCK_RIGHT
    TK_DOCK_FILL
end enum
```

### Types

```freebasic
type TKLAYOUT_ITEM
    x      as long
    y      as long
    cx     as long
    cy     as long
    anchor as long = TK_ANCHOR_DEFAULT
    dock   as long = TK_DOCK_NONE
end type

type TKLAYOUT_ClientFunc as function( byval w as TK_WIDGET ptr, byref rc as TKRECT ) as boolean

type TKLAYOUT_ENTRY
    w      as TK_WIDGET ptr
    item   as TKLAYOUT_ITEM
end type

type TKLAYOUT_CONTAINER
    w        as TK_WIDGET ptr
    designW  as long
    designH  as long
    clientFn as TKLAYOUT_ClientFunc
end type

type TK_LAYOUT
    entries( any )    as TKLAYOUT_ENTRY
    nEntries          as long
    containers( any ) as TKLAYOUT_CONTAINER
    nContainers       as long
end type
```

### Procedures

```freebasic
sub tkLayout_Compute( byval items as TKLAYOUT_ITEM ptr, byval n as long, _
                      byval designW as long, byval designH as long, _
                      byval cw as long, byval ch as long, byref rcDock as TKRECT, _
                      byval fScale as single, byval rcOut as TKRECT ptr )
function tkLayout_Create( ) as TK_LAYOUT ptr
sub tkLayout_Destroy( byval l as TK_LAYOUT ptr )
sub tkLayout_AddContainer( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr, byval designW as long, _
                           byval designH as long, byval clientFn as TKLAYOUT_ClientFunc = 0 )
sub tkLayout_Add( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr, byval x as long, byval y as long, _
                  byval cx as long, byval cy as long, byval anchor as long = TK_ANCHOR_DEFAULT, _
                  byval dock as long = TK_DOCK_NONE )
sub tkLayout_Remove( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr )
sub tkLayout_SetAnchor( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr, byval anchor as long )
function tkLayout_GetAnchor( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr ) as long
sub tkLayout_SetDock( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr, byval dock as long )
function tkLayout_GetDock( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr ) as long
sub tkLayout_SetDesignRect( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr, byval x as long, byval y as long, _
                            byval cx as long, byval cy as long )
function tkLayout_GetDesignRect( byval l as TK_LAYOUT ptr, byval w as TK_WIDGET ptr, byref item as TKLAYOUT_ITEM ) as boolean
sub tkLayout_Apply( byval l as TK_LAYOUT ptr )
sub tkLayout_BindSplitter( byval l as TK_LAYOUT ptr, byval split as TK_WIDGET ptr, byval pane as TK_WIDGET ptr )
```

### See also

- [tkControls](Category-tkControls)
- [tkHost](tkHost), [tkSplitter](tkSplitter)
- [tkForms](tkForms), [Form Designer](Form-Designer)
- [tkGroupBox](tkGroupBox), [tkPanel](tkPanel), [tkTabControl](tkTabControl)
