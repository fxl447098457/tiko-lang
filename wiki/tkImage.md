[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkImage**

# tkImage

Loads an image file once and draws it in any tkControls window.

`tkImageFile` holds one decoded image. You declare it, load it once, keep it as long as something shows it, and draw it with `tkImage_Paint` from a paint callback. The decoded pixels stay in memory; a texture is made the first time the image is drawn in a window and kept for that window, so the same image can appear in the main window, a popup menu and a tooltip. When a window goes, its textures go with it.

Formats are SDL_image's: `.png`, `.bmp`, `.jpg` / `.jpeg`, `.gif`, `.ico` / `.cur`, `.tga`, `.qoi` and more. Controls with an image slot load one for you from a path, for example `tkToolbar_SetItemImage` and `tkIconPanel_SetImage`.

## Importing

```freebasic
#import "vendor/tkControls/tkImage"

using tkImage
using tkHost
using tkPaint
```

tkImage re-exports [tkHost](tkHost), and through it [tkPaint](tkPaint), which holds `TK_IMGFIT_*`.

## Example

```freebasic
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkImage"
using tkApp
using tkHost
using tkPaint
using tkImage

dim shared as tkImageFile gLogo

sub Main_Paint( byval f as TK_FORM ptr, byval b as TK_PAINT ptr )
    dim as TKRECT rc
    tkRect_Set( rc, 0, 0, tkForm_Scale( f, 96 ), tkForm_Scale( f, 96 ) )
    tkImage_Paint( b, @gLogo, @rc, TK_IMGFIT_ASPECT )   ' nothing when the load failed
end sub

tkApp_Init()
if gLogo.Load( "logo.png" ) = 0 then print "logo.png: " & *SDL_GetError()
dim as TK_FORM ptr f = tkApp_NewForm( "Logo", 320, 200 )
tkForm_OnPaint( f, @Main_Paint )
end tkApp_Run( f )
```

- `Load( path )` takes a file or a name registered with [tkHost](tkHost) (`tkHost_AddResourceData` / `tkHost_AddResourceFile`, such as a Form Designer project's `res:logo`). `Load( path )`, `LoadFromSurface( s )` (copies an `SDL_Surface`; you keep yours) and `LoadFromPixels( w, h, argb )` (rows of `&hAARRGGBB`) return non-zero on success. A failed load clears the image held before.
- `NaturalWidth` / `NaturalHeight` give the size in pixels; `IsValid` says whether an image is held; `Dispose` frees it early.
- `TK_IMGFIT_ASPECT` fits the image inside the rect with its proportions kept, `_STRETCH` fills the rect, `_CENTER` draws it at its natural size, centred and clipped.
- `Surface()` and `Texture( renderer )` hand out what the object owns: never destroy them.

## API

| Member | Returns | Description |
| --- | --- | --- |
| `Load( path as ustring )` | `long` | Decode a file, or a name registered with [tkHost](tkHost). Non-zero on success; 0 on failure (bad path, unsupported or corrupt file). |
| `LoadFromSurface( s as SDL_Surface ptr )` | `long` | Copy an existing surface; you keep ownership of `s`. Non-zero on success. |
| `LoadFromPixels( w, h, argb as ulong ptr )` | `long` | Copy `w` x `h` pixels, `&hAARRGGBB`, row after row. 0 when `w` or `h` is not positive or `argb` is null. |
| `IsValid()` | `long` | Non-zero while an image is held. |
| `NaturalWidth()` / `NaturalHeight()` | `long` | Decoded size in pixels, or 0 when nothing is held. |
| `Dispose()` | | Free the image and its textures now; the destructor does the same. |
| `Surface()` | `SDL_Surface ptr` | The decoded pixels (ARGB8888), or null. Owned by the object. |
| `Texture( r as SDL_Renderer ptr )` | `SDL_Texture ptr` | The texture for that renderer, made on first use and cached. Owned by the object. |

Every load starts by freeing what was held, so a failed load leaves the object empty.

## Drawing

`tkImage_Paint( b, @img, @rc, nFit )` draws into the paint context `b`, clipped to `rc`. It draws nothing when the image is not valid.

| `nFit` | Placement |
| --- | --- |
| `TK_IMGFIT_ASPECT` (default) | Scale to fit inside `rc`, proportions kept, then centre. |
| `TK_IMGFIT_STRETCH` | Fill `rc` exactly, proportions ignored. |
| `TK_IMGFIT_CENTER` | Natural size, centred, clipped by `rc` when larger. No scaling. |

- **Decode happens once, at natural size.** Scaling is done at draw time with linear filtering, so one `tkImageFile` can be drawn into rects of different sizes without reloading.
- **Alpha is kept.** A transparent image composites over whatever is already painted in the rect, so fill the background first if you want one.
- **One object draws in every window.** Each window's texture is made the first time the image is drawn there; when that window's renderer goes, its cached texture is forgotten, so a stale texture is never drawn.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Types

```freebasic
type TKIMG_TEX
    r   as SDL_Renderer ptr
    tex as SDL_Texture ptr
end type

type tkImageFile
    pSurf      as SDL_Surface ptr
    cache(0 to 7) as TKIMG_TEX
    pNextLive  as tkImageFile ptr
    pPrevLive  as tkImageFile ptr
    declare sub DropTextures()
    declare constructor()
    declare destructor()
    declare function Load( byval path as ustring ) as long
    declare function LoadFromSurface( byval s as SDL_Surface ptr ) as long
    declare function LoadFromPixels( byval w as long, byval h as long, byval argb as ulong ptr ) as long
    declare sub Dispose()
    declare function IsValid() as long
    declare function NaturalWidth() as long
    declare function NaturalHeight() as long
    declare function Surface() as SDL_Surface ptr
    declare function Texture( byval r as SDL_Renderer ptr ) as SDL_Texture ptr
    declare sub PurgeRenderer( byval r as SDL_Renderer ptr )
end type
```

### Procedures

```freebasic
sub tkImage_Paint( byval p as TK_PAINT ptr, byval img as tkImageFile ptr, byval rc as TKRECT ptr, byval nFit as long = TK_IMGFIT_ASPECT )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost), [tkPaint](tkPaint)
