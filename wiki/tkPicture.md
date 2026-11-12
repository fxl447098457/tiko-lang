[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkPicture**

# tkPicture

Shows an image, scaled or clipped to its area.

`tkPicture` is the [tkControls](Category-tkControls) image box. It is never a tab stop. It can load a file itself (`tkPicture_SetFile`, which decodes the file and owns the result) or show a [tkImage](tkImage) `tkImageFile` that your program keeps (`tkPicture_SetImage`, borrowed).

The fit decides how the image meets the control's size: `TK_IMGFIT_ASPECT` fits it inside with its proportions kept and centres it, `TK_IMGFIT_STRETCH` fills the whole client area, and `TK_IMGFIT_CENTER` draws it at its natural size, centred and clipped. The default is `TK_IMGFIT_ASPECT`.

The picture is transparent by default. `tkPicture_SetBackColor` gives it a background of its own. A click is reported only when a click callback is set; without one the picture takes no mouse input of its own. The callback runs on the mouse release, and only if the cursor is still inside the picture.

## Importing

```freebasic
#import "vendor/tkControls/tkPicture"

using tkPicture
using tkHost
```

The module brings in [tkHost](tkHost) (and through it [tkPaint](tkPaint), SDL3, SDL_ttf and SDL_image), [tkTheme](tkTheme) and [tkImage](tkImage).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example.

```freebasic
sub Logo_Click( byval hPicture as TK_WIDGET ptr, byval id as long )
    print "logo clicked"
end sub

dim as TK_WIDGET ptr pic = tkPicture_Create( tkHost_Root( host ), 2300 )
if tkPicture_SetFile( pic, "logo.png" ) = false then print "logo.png could not be read"
tkPicture_SetFit( pic, TK_IMGFIT_ASPECT )
tkPicture_SetClickCallback( pic, @Logo_Click )

dim as long w, h
tkPicture_GetNaturalSize( pic, w, h )
tkWidget_SetPos( pic, tkHost_Scale( host, 20 ), tkHost_Scale( host, 20 ), _
                 tkHost_Scale( host, 200 ), tkHost_Scale( host, 120 ) )
```

Showing an image the program owns:

```freebasic
dim shared as tkImageFile gIcon          ' must outlive the picture
gIcon.Load( "icon.png" )
tkPicture_SetImage( pic, @gIcon )
```

## Typed wrapper

The module also provides `Picture`, a typed value for designed forms (see [tkForms](tkForms) and the [Form Designer](Form-Designer)). `Picture.Handle` is the `TK_WIDGET ptr`. It has `Create( hParent, id )`, `SetFocus( )`, and these properties, each read and write:

`Enabled`, `Visible`, `File`, `Fit`, `BackColor`, `Transparent`.

## Behaviour notes

- `tkPicture_SetFile` returns false when the file cannot be read, and the picture is then empty. `tkPicture_GetFile` returns the last path given, whether or not it loaded.
- `tkPicture_SetFile` replaces a borrowed image: after it, the picture shows the file.
- `tkPicture_SetImage` borrows the image: it must outlive the picture, or be replaced first. Pass 0 to empty the picture; this also frees any image the picture loaded from a file.
- `tkPicture_HasImage` is true only when an image is held and valid. `tkPicture_GetNaturalSize` gives 0 by 0 when there is none.
- `tkPicture_SetFit` ignores a value that is not one of the three `TK_IMGFIT_*` constants.
- `tkPicture_SetBackColor` also turns the background on.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Types

```freebasic
type TKPICTURE_STATE   ' per-instance state; reach it through the procedures

type PIC_ClickCallbackSub as sub( byval hPicture as TK_WIDGET ptr, byval id as long )
```

The fit constants `TK_IMGFIT_ASPECT`, `TK_IMGFIT_STRETCH` and `TK_IMGFIT_CENTER` are declared by [tkPaint](tkPaint).

### Procedures

```freebasic
function tkPicture_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkPicture_SetFile( byval h as TK_WIDGET ptr, byref path as const ustring ) as boolean
function tkPicture_GetFile( byval h as TK_WIDGET ptr ) as ustring
sub tkPicture_SetImage( byval h as TK_WIDGET ptr, byval img as tkImageFile ptr )
function tkPicture_HasImage( byval h as TK_WIDGET ptr ) as boolean
sub tkPicture_GetNaturalSize( byval h as TK_WIDGET ptr, byref nWidth as long, byref nHeight as long )
function tkPicture_GetFit( byval h as TK_WIDGET ptr ) as long
sub tkPicture_SetFit( byval h as TK_WIDGET ptr, byval nFit as long )
function tkPicture_GetBackColor( byval h as TK_WIDGET ptr ) as ulong
sub tkPicture_SetBackColor( byval h as TK_WIDGET ptr, byval clr as ulong )
function tkPicture_GetTransparent( byval h as TK_WIDGET ptr ) as boolean
sub tkPicture_SetTransparent( byval h as TK_WIDGET ptr, byval bTransparent as boolean )
sub tkPicture_SetClickCallback( byval h as TK_WIDGET ptr, byval usersub as PIC_ClickCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkTheme](tkTheme)
- [tkImage](tkImage), [tkPaint](tkPaint)
