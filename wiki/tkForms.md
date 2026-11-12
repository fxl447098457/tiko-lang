[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkForms**

# tkForms

Provides the base a designed form extends: a window, its layout, show and close.

`tkForms` gives a form a `FormBase` to extend. `FormBase` holds the form's window (`Wnd`, a `TK_FORM ptr` from [tkApp](tkApp)) and its [tkLayout](tkLayout) (`Layout`), reflows the layout whenever the window is resized or changes scale, and wraps showing the form modally or not. Forms made by the [Form Designer](Form-Designer) extend it, and a hand-written form can too.

A form is an object you declare, build and keep. `OpenWindow` creates the window hidden. The form object's address is stored in the window's `Tag`, so event thunks can find the object again with `tkForms_ObjectOf`. That is also why a form can never be copied: a copy would leave the window pointing at the original. The copy constructor and the assignment operator of `FormBase` are private.

When the window goes, whoever closed it (the close button, `Close`, or the object's destructor), `Wnd` and `Layout` are set to 0 and the layout is destroyed. Nothing in the form is valid to touch after that. `IsOpen` tells you which side of that line you are on.

`tkForms_SetTranslator` and `tkForms_Tr` let generated code show captions in another language.

## Importing

```freebasic
#import "vendor/tkControls/tkForms"

using tkForms
using tkApp
using tkLayout
using tkHost
```

The module brings in [tkApp](tkApp) and [tkLayout](tkLayout), and so [tkHost](tkHost). It does not import any control: import the controls the form uses, for their typed wrappers.

## Example

A form written by hand, the way the designer generates one: a type that extends `FormBase`, controls as typed wrappers, and a thunk that reaches the form object from a control's event.

```freebasic
#import "vendor/tkControls/tkForms"
#import "vendor/tkControls/tkButton"
#import "vendor/tkControls/tkLabel"
using tkForms
using tkApp
using tkLayout
using tkButton
using tkLabel
using tkHost
using tkPaint

type Form extends FormBase
    btnOK as Button
    lblInfo as Label
    Clicks as long
    declare sub Build( byval owner as TK_FORM ptr = nullptr )
    declare sub btnOK_Click( )
end type

private sub Thunk_btnOK_Click( byval h as TK_WIDGET ptr, byval id as long )
    dim as Form ptr f = tkForms_ObjectOf( h )
    if f then f->btnOK_Click( )
end sub

sub Form.Build( byval owner as TK_FORM ptr = nullptr )
    OpenWindow( "Form", 400, 300, owner )              ' design units
    dim as TK_WIDGET ptr root_ = tkForm_Widget( Wnd )
    tkLayout_AddContainer( Layout, root_, 400, 300 )

    btnOK.Create( root_, 1 )
    btnOK.Text = "OK"
    tkButton_SetClickCallback( btnOK.Handle, @Thunk_btnOK_Click )
    tkLayout_Add( Layout, btnOK.Handle, 300, 260, 88, 30, TK_ANCHOR_RIGHT or TK_ANCHOR_BOTTOM )

    lblInfo.Create( root_, 2 )
    tkLayout_Add( Layout, lblInfo.Handle, 12, 12, 300, 24 )
end sub

sub Form.btnOK_Click( )
    Clicks += 1
    lblInfo.Text = "Clicked " & Clicks
end sub

dim as TKAPP_OPTIONS opts
if tkApp_Init( opts ) = false then end 1

dim as Form f
f.Build( )
f.Show( )
end tkApp_Run( f.Wnd )
```

A modal form, read after it closes:

```freebasic
dim as Form dlg
dlg.Build( mainWnd )                  ' mainWnd is the owner's TK_FORM ptr
dim as long code = dlg.ShowModal( )   ' runs until dlg.EndModal( code ) or the window closes
print "closed with " & code
```

## Translating captions

```freebasic
function MyLookup( byref key as const ustring, byref text as const ustring ) as ustring
    return text      ' look the key up in your own table here
end function

tkForms_SetTranslator( @MyLookup )
print tkForms_Tr( "greeting", "Hello" )
```

With no translator installed, `tkForms_Tr` returns the text it was given. `tkForms_SetTranslator( 0 )` removes the translator.

## FormBase

```freebasic
type FormBase extends object
    Wnd as TK_FORM ptr
    Layout as TK_LAYOUT ptr

    declare constructor( )
    declare destructor( )

    declare sub OpenWindow( byref title as const ustring, byval cx as long, byval cy as long, byval owner as TK_FORM ptr = nullptr )
    declare sub Show( )
    declare function ShowModal( ) as long
    declare sub EndModal( byval code as long )
    declare sub Close( )
    declare function IsOpen( ) as boolean
end type
```

| Member | What it does |
|---|---|
| `Wnd` | The form's window. 0 until `OpenWindow`, and 0 again once the window is gone. Pass it to `tkForm_Widget`, `tkApp_Run` and the other [tkApp](tkApp) form calls. |
| `Layout` | The form's [tkLayout](tkLayout), created by `OpenWindow`. Add containers and controls to it; `FormBase` calls `tkLayout_Apply` on every size and scale change. 0 once the window is gone. |
| `OpenWindow( title, cx, cy [, owner] )` | Creates the window, hidden, `cx` by `cy` in design units, and its layout. `owner = 0` makes a top-level window. Does nothing if the window already exists. |
| `Show( )` | Shows the window. Does nothing when there is no window. |
| `ShowModal( ) as long` | Shows the form modally and runs until it is closed. The result is the code given to `EndModal`. Afterwards the window is hidden, not destroyed: the controls can still be read, and the form can be shown again. Returns 0 when there is no window. |
| `EndModal( code )` | Ends a running `ShowModal`, which then returns `code`. |
| `Close( )` | Closes the window as the close button does: the form's close callback is asked first. When the window closes it is destroyed. |
| `IsOpen( ) as boolean` | True while the window exists. |

The destructor destroys the window if it is still there, so a form that goes out of scope takes its window with it.

## Procedures

- `tkForms_ObjectOf( w )` returns the form object a control belongs to, as an `any ptr` that you cast to your form type. It returns 0 when the control's window is gone or is not a designed form, so a thunk can check before it calls in.
- `tkForms_SetTranslator( f )` installs the program's caption lookup. It takes a `tkForms_TranslateFunc`, a function of the key and the default text that returns the text to show.
- `tkForms_Tr( key, text )` asks the translator, and returns `text` unchanged when none is installed.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Types

```freebasic
type tkForms_TranslateFunc as function( byref key as const ustring, byref text as const ustring ) as ustring

type FormBase extends object
    Wnd as TK_FORM ptr
    Layout as TK_LAYOUT ptr
    declare constructor( )
    declare destructor( )
    declare sub OpenWindow( byref title as const ustring, byval cx as long, byval cy as long, byval owner as TK_FORM ptr = nullptr )
    declare sub Show( )
    declare function ShowModal( ) as long
    declare sub EndModal( byval code as long )
    declare sub Close( )
    declare function IsOpen( ) as boolean
end type
```

### Procedures

```freebasic
sub tkForms_SetTranslator( byval f as tkForms_TranslateFunc )
function tkForms_Tr( byref key as const ustring, byref text as const ustring ) as ustring
function tkForms_ObjectOf( byval w as TK_WIDGET ptr ) as any ptr
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [tkLayout](tkLayout), [Form Designer](Form-Designer)
