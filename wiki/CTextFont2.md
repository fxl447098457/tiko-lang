[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/richedit](SysWin-RichEdit) › **CTextFont2**

# CTextFont2
Reads and sets the character formatting of rich edit text: font, size, colour and effects.

<!-- scope: CTextFont2 -->

Reads and sets the character formatting of rich edit text: font, size, colour and effects.

`CTextFont2` wraps the Text Object Model's `ITextFont2` interface, the TOM's view of character
formatting. You get one from a range or the selection, and from the document's default font:

| Source | Call | The font object is |
| --- | --- | --- |
| A range of text | [CTextRange2](CTextRange2)`.GetFont()` | attached: every change applies to that text at once |
| The selection | [CTextSelection2](CTextSelection2)`.GetFont()` | attached to the selected text |
| The document default | [CRichEditCtx](CRichEditCtx)`.DocumentFont` | the document's default character format |
| Another font object | [GetDuplicate](#duplicate-getduplicate-setduplicate) | a detached copy: changes go nowhere until applied |

**Ownership.** The constructor takes the `ITextFont2` pointer as it is, without adding a
reference (pass `true` as the second argument to add one), and the destructor releases it. So
`dim f as CTextFont2 = rng.GetFont()` takes over the pointer `GetFont` returned and needs no
release of its own.

**Three forms of each property.** Most attributes come as `GetX()`, which returns the value;
`SetX( Value )`, which returns the `HRESULT`; and a property `X` to read and assign
(`f.Bold = tomTrue`). All three store the `HRESULT` of the call, which `GetLastResult()`
returns; `GetErrorInfo()` turns it into text. Both come from the base class `CTextObjectBase`
(see [Text Object Model](SysWin-RichEdit-TOM)).

**`tomBool` values.** The on/off attributes (bold, italic, hidden …) use `tomTrue` (-1) and
`tomFalse` (0). When setting, `tomToggle` flips the current state and `tomUndefined` leaves it as
it is. When reading a range whose characters differ, the value is `tomUndefined` (-9999999); the
same goes for the numeric attributes, so `Size` on a range that mixes two sizes reads
`-9999999`.

**Units.** `Size`, `Kerning`, `Spacing` and `Position` are `single` values in points.

The examples assume `hCtrl` is a rich edit control made by [CRichEditCtx](CRichEditCtx) and work
on its first five characters.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/richedit"
using win, richedit
```

## Example

A rich edit control whose first words are made bold, red and large through `CTextFont2`. The
**Bold** button toggles bold on the selection and shows the selection's font in the caption.

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/richedit"
using win, gui, richedit

const IDC_RICHEDIT = 101
const IDC_BOLD = 102

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "FontDemo"
    dim hWin as HWND = pWindow.Create( NULL, "CTextFont2", @WndProc )
    SetWindowClientSizeForDpi( hWin, 500, 260 )
    CenterWindow( hWin )
    dim pRichEdit as CRichEditCtx = CRichEditCtx( @pWindow, IDC_RICHEDIT, "", 10, 10, 480, 200 )
    pRichEdit.SetText( "Bold, red and large: character formatting through the Text Object Model." )
    scope
        dim rng as CTextRange2 = pRichEdit.Range( 0, 4 )      ' "Bold"
        dim f as CTextFont2 = rng.GetFont()
        f.Bold = tomTrue
    end scope
    scope
        dim rng as CTextRange2 = pRichEdit.Range( 6, 9 )      ' "red"
        dim f as CTextFont2 = rng.GetFont()
        f.ForeColor = BGR( 220, 0, 0 )
    end scope
    scope
        dim rng as CTextRange2 = pRichEdit.Range( 14, 19 )    ' "large"
        dim f as CTextFont2 = rng.GetFont()
        f.Size = 16
        f.Name = "Georgia"
    end scope
    pWindow.AddControl( "Button", hWin, IDC_BOLD, "&Bold", 10, 220, 100, 28 )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTL( wParam, lParam ) = IDC_BOLD andalso CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                dim pRichEdit as CRichEditCtx ptr = CRichEditCtxPtr( hwnd, IDC_RICHEDIT )
                if pRichEdit then
                    dim sel as CTextSelection2 = pRichEdit->Selection2()
                    dim f as CTextFont2 = sel.GetFont()
                    f.Bold = tomToggle
                    SetWindowText( hwnd, f.Name & ", " & f.Size & " pt" )
                    SetFocus( pRichEdit->hRichEdit )
                end if
            end if
            return 0
        case WM_DESTROY
            PostQuitMessage( 0 )
            return 0
    end select
    return DefWindowProcW( hwnd, uMsg, wParam, lParam )
end function

end main()
```

## Members

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Wraps an `ITextFont2` pointer. |
| [Destructor](#destructor) | Releases the pointer. |
| [Duplicate, GetDuplicate, SetDuplicate](#duplicate-getduplicate-setduplicate) | Makes a detached copy of the formatting, or copies formatting in. |
| [Duplicate2, GetDuplicate2, SetDuplicate2](#duplicate2-getduplicate2-setduplicate2) | The same calls under their `ITextFont2` names. |
| [CanChange](#canchange) | Tells whether the formatting can be changed. |
| [IsEqual](#isequal) | Compares the formatting with another font object. |
| [IsEqual2](#isequal2) | Compares with the `ITextFont2` method. |
| [Reset](#reset) | Resets the formatting to the defaults or to undefined, or controls when changes apply. |
| [Style, GetStyle, SetStyle](#style-getstyle-setstyle) | The character style handle. |
| [AllCaps, GetAllCaps, SetAllCaps](#allcaps-getallcaps-setallcaps) | All capitals. |
| [Animation, GetAnimation, SetAnimation](#animation-getanimation-setanimation) | The animation type. |
| [BackColor, GetBackColor, SetBackColor](#backcolor-getbackcolor-setbackcolor) | The background (highlight) colour. |
| [Bold, GetBold, SetBold](#bold-getbold-setbold) | Bold. |
| [Emboss, GetEmboss, SetEmboss](#emboss-getemboss-setemboss) | Embossed. |
| [ForeColor, GetForeColor, SetForeColor](#forecolor-getforecolor-setforecolor) | The text colour. |
| [Hidden, GetHidden, SetHidden](#hidden-gethidden-sethidden) | Hidden text. |
| [Engrave, GetEngrave, SetEngrave](#engrave-getengrave-setengrave) | Engraved (imprinted). |
| [Italic, GetItalic, SetItalic](#italic-getitalic-setitalic) | Italic. |
| [Kerning, GetKerning, SetKerning](#kerning-getkerning-setkerning) | The smallest size at which kerning applies. |
| [LanguageID, GetLanguageID, SetLanguageID](#languageid-getlanguageid-setlanguageid) | The language. |
| [Name, GetName, SetName](#name-getname-setname) | The font name. |
| [Outline, GetOutline, SetOutline](#outline-getoutline-setoutline) | Outlined. |
| [Position, GetPosition, SetPosition](#position-getposition-setposition) | The vertical offset from the baseline. |
| [Protected_, GetProtected, SetProtected](#protected_-getprotected-setprotected) | Protected against editing. |
| [Shadow, GetShadow, SetShadow](#shadow-getshadow-setshadow) | Shadowed. |
| [Size, GetSize, SetSize](#size-getsize-setsize) | The font size. |
| [SmallCaps, GetSmallCaps, SetSmallCaps](#smallcaps-getsmallcaps-setsmallcaps) | Small capitals. |
| [Spacing, GetSpacing, SetSpacing](#spacing-getspacing-setspacing) | Extra space between characters. |
| [StrikeThrough, GetStrikeThrough, SetStrikeThrough](#strikethrough-getstrikethrough-setstrikethrough) | A line through the text. |
| [Subscript, GetSubscript, SetSubscript](#subscript-getsubscript-setsubscript) | Subscript. |
| [Superscript, GetSuperscript, SetSuperscript](#superscript-getsuperscript-setsuperscript) | Superscript. |
| [Underline, GetUnderline, SetUnderline](#underline-getunderline-setunderline) | The underline type. |
| [Weight, GetWeight, SetWeight](#weight-getweight-setweight) | The font weight. |
| [Count, GetCount](#count-getcount) | The number of extra properties. |
| [AutoLigatures, GetAutoLigatures, SetAutoLigatures](#autoligatures-getautoligatures-setautoligatures) | Automatic ligatures. |
| [AutospaceAlpha, GetAutospaceAlpha, SetAutospaceAlpha](#autospacealpha-getautospacealpha-setautospacealpha) | East Asian autospace for Latin letters. |
| [AutospaceNumeric, GetAutospaceNumeric, SetAutospaceNumeric](#autospacenumeric-getautospacenumeric-setautospacenumeric) | East Asian autospace for digits. |
| [AutospaceParens, GetAutospaceParens, SetAutospaceParens](#autospaceparens-getautospaceparens-setautospaceparens) | East Asian autospace for parentheses. |
| [CharRep, GetCharRep, SetCharRep](#charrep-getcharrep-setcharrep) | The character repertoire (writing system). |
| [CompressionMode, GetCompressionMode, SetCompressionMode](#compressionmode-getcompressionmode-setcompressionmode) | East Asian compression. |
| [Cookie, GetCookie, SetCookie](#cookie-getcookie-setcookie) | A value of your own stored with the formatting. |
| [DoubleStrike, GetDoubleStrike, SetDoubleStrike](#doublestrike-getdoublestrike-setdoublestrike) | Two lines through the text. |
| [LinkType, GetLinkType](#linktype-getlinktype) | The kind of link the text is part of. |
| [MathZone, GetMathZone, SetMathZone](#mathzone-getmathzone-setmathzone) | Whether the text is a math zone. |
| [ModWidthPairs, GetModWidthPairs, SetModWidthPairs](#modwidthpairs-getmodwidthpairs-setmodwidthpairs) | Narrower widths on character pairs. |
| [ModWidthSpace, GetModWidthSpace, SetModWidthSpace](#modwidthspace-getmodwidthspace-setmodwidthspace) | Wider white space. |
| [OldNumbers, GetOldNumbers, SetOldNumbers](#oldnumbers-getoldnumbers-setoldnumbers) | Old-style figures. |
| [Overlapping, GetOverlapping, SetOverlapping](#overlapping-getoverlapping-setoverlapping) | Overlapping text. |
| [PositionSubSuper, GetPositionSubSuper, SetPositionSubSuper](#positionsubsuper-getpositionsubsuper-setpositionsubsuper) | The subscript or superscript offset. |
| [Scaling, GetScaling, SetScaling](#scaling-getscaling-setscaling) | Horizontal scaling. |
| [SpaceExtension, GetSpaceExtension, SetSpaceExtension](#spaceextension-getspaceextension-setspaceextension) | East Asian space extension. |
| [UnderlinePositionMode, GetUnderlinePositionMode, SetUnderlinePositionMode](#underlinepositionmode-getunderlinepositionmode-setunderlinepositionmode) | Where the underline goes. |
| [GetEffects, SetEffects](#geteffects-seteffects) | Several on/off attributes at once. |
| [GetEffects2, SetEffects2](#geteffects2-seteffects2) | Several more on/off attributes at once. |
| [Property_, GetProperty, SetProperty](#property_-getproperty-setproperty) | An extra property by its id. |
| [PropertyInfo, GetPropertyInfo](#propertyinfo-getpropertyinfo) | The type and value of an extra property by index. |

## Reference

### Constructor

```freebasic
constructor( byval pTextFont2 as ITextFont2 ptr, byval fAddRef as boolean = false )
```

Wraps an `ITextFont2` pointer. With `fAddRef` `false` (the default) the object takes over the
reference you hand it, which is right for the result of `GetFont`, `GetDuplicate` or
`DocumentFont`; with `true` it adds a reference of its own and you keep yours.

A `NULL` pointer leaves the object empty with `GetLastResult()` returning `E_INVALIDARG`
(`&h80070057`). Only [PropertyInfo and GetPropertyInfo](#propertyinfo-getpropertyinfo) check for
an empty object (they return `E_POINTER`); every other member calls through the pointer, so do
not use an empty one.

| Parameter | Meaning |
| --- | --- |
| `pTextFont2` | The font interface. |
| `fAddRef` | `true` to add a reference; `false` to take over the caller's. |

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
if f.GetLastResult() = S_OK then print "font: "; f.Name
```

### Destructor

```freebasic
destructor
```

Releases the `ITextFont2` pointer, if there is one. It runs when the variable goes out of scope.

**Example**

```freebasic
scope
    dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
    dim f as CTextFont2 = rng.GetFont()
    f.Italic = tomTrue
end scope   ' f, then rng, released here
```

### Duplicate, GetDuplicate, SetDuplicate

```freebasic
function GetDuplicate() as ITextFont2 ptr
function SetDuplicate( byval pFont as ITextFont2 ptr ) as HRESULT
property Duplicate() as ITextFont2 ptr
property Duplicate( byval pFont as ITextFont2 ptr )
```

`GetDuplicate` (and reading `Duplicate`) returns a new font object holding a copy of this one's
formatting. The copy is not attached to any text: change it freely, compare it with
[IsEqual](#isequal), and apply it to a range later. The caller owns the returned pointer: wrap it
in a `CTextFont2` or release it.

`SetDuplicate` (and assigning `Duplicate`) copies the formatting of `pFont` into this object;
attributes that are `tomUndefined` in `pFont` are left as they are. These members call the
`ITextFont2` methods `GetDuplicate2` and `SetDuplicate2`. On the rich edit control of current
Windows versions `SetDuplicate2` returns `E_NOTIMPL` (`&h80004001`) and nothing changes; the
`ITextFont` method `SetDuplicate`, reached through `m_pTextFont2`, applies the copy.

| Parameter | Meaning |
| --- | --- |
| `pFont` | The font object to copy from. |

**Returns** `GetDuplicate`: the new font object, or `NULL` on failure. `SetDuplicate`: `S_OK`
on success, otherwise an error code.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
dim d as CTextFont2 = f.GetDuplicate()
d.Italic = tomTrue : d.Size = 16
f.m_pTextFont2->lpvtbl->SetDuplicate( f.m_pTextFont2, d.m_pTextFont2 )   ' applies both
```

Microsoft Learn: [ITextFont2::GetDuplicate2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getduplicate2), [ITextFont2::SetDuplicate2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setduplicate2), [ITextFont::SetDuplicate](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setduplicate)

### Duplicate2, GetDuplicate2, SetDuplicate2

```freebasic
function GetDuplicate2() as ITextFont2 ptr
function SetDuplicate2( byval pFont as ITextFont2 ptr ) as HRESULT
property Duplicate2() as ITextFont2 ptr
property Duplicate2( byval pFont as ITextFont2 ptr )
```

The same calls as [Duplicate, GetDuplicate, SetDuplicate](#duplicate-getduplicate-setduplicate),
under the names of the `ITextFont2` methods they call. The returned pointer is the caller's to
release.

| Parameter | Meaning |
| --- | --- |
| `pFont` | The font object to copy from. |

**Returns** `GetDuplicate2`: the new font object, or `NULL`. `SetDuplicate2`: the `HRESULT`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
dim d as CTextFont2 = f.GetDuplicate2()
print "copy of "; d.Name; ","; d.Size; " pt"
```

Microsoft Learn: [ITextFont2::GetDuplicate2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getduplicate2), [ITextFont2::SetDuplicate2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setduplicate2)

### CanChange

```freebasic
function CanChange() as long
```

Tells whether the formatting can be changed: it cannot when part of the attached text is
protected or the document is read-only. A duplicate is not bound by those rules.

**Returns** `tomTrue` if the formatting can change, otherwise `tomFalse`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
if f.CanChange() = tomTrue then f.Bold = tomTrue
```

Microsoft Learn: [ITextFont::CanChange](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-canchange)

### IsEqual

```freebasic
function IsEqual( byval pFont as ITextFont2 ptr ) as long
```

Compares this formatting with that of `pFont`. Attributes that are `tomUndefined` in either
object are not compared. A fresh duplicate compares equal to the object it was made from.

| Parameter | Meaning |
| --- | --- |
| `pFont` | The font object to compare with. |

**Returns** `tomTrue` if the two match, otherwise `tomFalse`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
dim d as CTextFont2 = f.GetDuplicate()
print f.IsEqual( d.m_pTextFont2 )   ' -1
```

Microsoft Learn: [ITextFont::IsEqual](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-isequal)

### IsEqual2

```freebasic
function IsEqual2( byval pFont as ITextFont2 ptr ) as long
```

Compares this formatting with that of `pFont` through the `ITextFont2` method, which also
compares the `ITextFont2` attributes. On the rich edit control of current Windows versions the
method returns `E_NOTIMPL` (`GetLastResult()` is `&h80004001`) and the result is `tomFalse`;
use [IsEqual](#isequal) there.

| Parameter | Meaning |
| --- | --- |
| `pFont` | The font object to compare with. |

**Returns** `tomTrue` if the two match, otherwise `tomFalse`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
dim d as CTextFont2 = f.GetDuplicate()
dim eq as long = f.IsEqual2( d.m_pTextFont2 )
if f.GetLastResult() = E_NOTIMPL then eq = f.IsEqual( d.m_pTextFont2 )
```

Microsoft Learn: [ITextFont2::IsEqual2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-isequal2)

### Reset

```freebasic
function Reset( byval Value as long ) as HRESULT
```

Resets the formatting, or changes how the object applies changes, according to `Value`:

| `Value` | Effect |
| --- | --- |
| `tomDefault` | The document's default character format (for an attached object) or the TOM defaults. |
| `tomUndefined` | Every attribute undefined, so applying the object changes nothing. Only for a duplicate: an attached object returns `E_INVALIDARG`. |
| `tomApplyLater`, `tomApplyNow` | Hold changes back, then apply them to the attached text. |
| `tomCacheParms`, `tomTrackParms` | Stop or resume updating the object from the attached text. |
| `tomApplyTmp` | Apply temporary formatting. |
| `tomDisableSmartFont`, `tomEnableSmartFont` | Turn smart font selection off or on. |
| `tomUsePoints`, `tomUseTwips` | Floating-point measurements in points or in twips. |

**Returns** `S_OK` on success; `S_FALSE` when the text is protected; otherwise an error code.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Reset( tomDefault )   ' back to the document's default font
```

Microsoft Learn: [ITextFont::Reset](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-reset)

### Style, GetStyle, SetStyle

```freebasic
function GetStyle() as long
function SetStyle( byval Value as long ) as HRESULT
property Style() as long
property Style( byval Value as long )
```

The character style handle of the text. The TOM does not define what the handles mean; text with
no character style reads 0.

| Parameter | Meaning |
| --- | --- |
| `Value` | The style handle. |

**Returns** the handle, or the `HRESULT` for `SetStyle`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
print "style"; f.Style
```

Microsoft Learn: [ITextFont::GetStyle](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getstyle), [ITextFont::SetStyle](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setstyle)

### AllCaps, GetAllCaps, SetAllCaps

```freebasic
function GetAllCaps() as long
function SetAllCaps( byval Value as long ) as HRESULT
property AllCaps() as long
property AllCaps( byval Value as long )
```

Whether the text is shown in capitals, whatever its case. The characters themselves do not
change.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetAllCaps`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.AllCaps = tomTrue
```

Microsoft Learn: [ITextFont::GetAllCaps](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getallcaps), [ITextFont::SetAllCaps](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setallcaps)

### Animation, GetAnimation, SetAnimation

```freebasic
function GetAnimation() as long
function SetAnimation( byval Value as long ) as HRESULT
property Animation() as long
property Animation( byval Value as long )
```

The animation type: `tomNoAnimation` (0), `tomLasVegasLights`, `tomBlinkingBackground`,
`tomSparkleText`, `tomMarchingBlackAnts`, `tomMarchingRedAnts`, `tomShimmer`, `tomWipeDown`
or `tomWipeRight`.

| Parameter | Meaning |
| --- | --- |
| `Value` | The animation type. |

**Returns** the animation type, or the `HRESULT` for `SetAnimation`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
if f.Animation <> tomNoAnimation then f.Animation = tomNoAnimation
```

Microsoft Learn: [ITextFont::GetAnimation](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getanimation), [ITextFont::SetAnimation](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setanimation)

### BackColor, GetBackColor, SetBackColor

```freebasic
function GetBackColor() as long
function SetBackColor( byval Value as long ) as HRESULT
property BackColor( byval Value as long )
property BackColor() as long
```

The background (highlight) colour of the text: a `COLORREF` (make one with `BGR( r, g, b )`), a
palette index, or `tomAutoColor` for the control's background colour. Text that has no highlight
reads `tomAutoColor` (-9999997).

| Parameter | Meaning |
| --- | --- |
| `Value` | The colour, `tomAutoColor`, or `tomUndefined` to leave it. |

**Returns** the colour, or the `HRESULT` for `SetBackColor`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.BackColor = BGR( 255, 255, 0 )   ' yellow highlight
```

Microsoft Learn: [ITextFont::GetBackColor](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getbackcolor), [ITextFont::SetBackColor](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setbackcolor)

### Bold, GetBold, SetBold

```freebasic
function GetBold() as long
function SetBold( byval Value as long ) as HRESULT
property Bold() as long
property Bold( byval Value as long )
```

Whether the text is bold. Setting a [Weight](#weight-getweight-setweight) of 700 or more also
makes `Bold` read `tomTrue`.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetBold`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Bold = tomToggle
```

Microsoft Learn: [ITextFont::GetBold](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getbold), [ITextFont::SetBold](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setbold)

### Emboss, GetEmboss, SetEmboss

```freebasic
function GetEmboss() as long
function SetEmboss( byval Value as long ) as HRESULT
property Emboss() as long
property Emboss( byval Value as long ) as HRESULT
```

Whether the text is embossed (raised).

Use `GetEmboss` and `SetEmboss`. The setter of the `Emboss` property is declared with a result,
and a procedure that both assigns and reads the `Emboss` property does not build.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetEmboss`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.SetEmboss( tomTrue )
print "embossed"; f.GetEmboss()
```

Microsoft Learn: [ITextFont::GetEmboss](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getemboss), [ITextFont::SetEmboss](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setemboss)

### ForeColor, GetForeColor, SetForeColor

```freebasic
function GetForeColor() as long
function SetForeColor( byval Value as long ) as HRESULT
property ForeColor() as long
property ForeColor( byval Value as long )
```

The colour of the text: a `COLORREF` (`BGR( r, g, b )`), a palette index, or `tomAutoColor` for
the control's text colour.

| Parameter | Meaning |
| --- | --- |
| `Value` | The colour, `tomAutoColor`, or `tomUndefined` to leave it. |

**Returns** the colour, or the `HRESULT` for `SetForeColor`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.ForeColor = BGR( 0, 0, 255 )
print hex( f.ForeColor )   ' FF0000
```

Microsoft Learn: [ITextFont::GetForeColor](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getforecolor), [ITextFont::SetForeColor](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setforecolor)

### Hidden, GetHidden, SetHidden

```freebasic
function GetHidden() as long
function SetHidden( byval Value as long ) as HRESULT
property Hidden() as long
property Hidden( byval Value as long )
```

Whether the text is hidden. Hidden text stays in the document but is not shown.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetHidden`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Hidden = tomTrue
```

Microsoft Learn: [ITextFont::GetHidden](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-gethidden), [ITextFont::SetHidden](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-sethidden)

### Engrave, GetEngrave, SetEngrave

```freebasic
function GetEngrave() as long
function SetEngrave( byval Value as long ) as HRESULT
property Engrave() as long
property Engrave( byval Value as long )
```

Whether the text is engraved (imprinted, pressed into the page).

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetEngrave`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Engrave = tomTrue
```

Microsoft Learn: [ITextFont::GetEngrave](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getengrave), [ITextFont::SetEngrave](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setengrave)

### Italic, GetItalic, SetItalic

```freebasic
function GetItalic() as long
function SetItalic( byval Value as long ) as HRESULT
property Italic() as long
property Italic( byval Value as long )
```

Whether the text is italic.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetItalic`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.SetItalic( tomToggle )
```

Microsoft Learn: [ITextFont::GetItalic](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getitalic), [ITextFont::SetItalic](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setitalic)

### Kerning, GetKerning, SetKerning

```freebasic
function GetKerning() as single
function SetKerning( byval Value as single ) as HRESULT
property Kerning() as single
property Kerning( byval Value as single )
```

The smallest font size, in points, at which pairs of characters are kerned. 0 turns kerning off.

| Parameter | Meaning |
| --- | --- |
| `Value` | The size in points, or 0. |

**Returns** the size, or the `HRESULT` for `SetKerning`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Kerning = 10   ' kern text of 10 pt and larger
```

Microsoft Learn: [ITextFont::GetKerning](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getkerning), [ITextFont::SetKerning](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setkerning)

### LanguageID, GetLanguageID, SetLanguageID

```freebasic
function GetLanguageID() as long
function SetLanguageID( byval Value as long ) as HRESULT
property LanguageID() as long
property LanguageID( byval Value as long )
```

The language of the text, as a locale identifier (LCID): 1033 is English (United States), 1036
French (France). The spelling checker and the choice of fonts follow it.

| Parameter | Meaning |
| --- | --- |
| `Value` | The LCID. |

**Returns** the LCID, or the `HRESULT` for `SetLanguageID`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.LanguageID = 1036
```

Microsoft Learn: [ITextFont::GetLanguageID](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getlanguageid), [ITextFont::SetLanguageID](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setlanguageid)

### Name, GetName, SetName

```freebasic
function GetName() as ustring
function SetName( byref wszFontName as wstring ) as HRESULT
property Name() as ustring
property Name( byref dwsFontName as ustring )
```

The name of the font, such as `"Arial"`. The text is passed to and from the interface as a
`BSTR`, which the members allocate and free themselves.

| Parameter | Meaning |
| --- | --- |
| `wszFontName`, `dwsFontName` | The font name. |

**Returns** the name, or the `HRESULT` for `SetName`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Name = "Courier New"
print f.GetName()   ' Courier New
```

Microsoft Learn: [ITextFont::GetName](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getname), [ITextFont::SetName](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setname)

### Outline, GetOutline, SetOutline

```freebasic
function GetOutline() as long
function SetOutline( byval Value as long ) as HRESULT
property Outline() as long
property Outline( byval Value as long )
```

Whether the text is drawn as outlines.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetOutline`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Outline = tomTrue
```

Microsoft Learn: [ITextFont::GetOutline](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getoutline), [ITextFont::SetOutline](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setoutline)

### Position, GetPosition, SetPosition

```freebasic
function GetPosition() as single
function SetPosition( byval Value as single ) as HRESULT
property Position() as single
property Position( byval Value as single )
```

How far the text is raised above the baseline, in points; a negative value lowers it. Unlike
[Superscript](#superscript-getsuperscript-setsuperscript), the size of the text does not change.

| Parameter | Meaning |
| --- | --- |
| `Value` | The offset in points. |

**Returns** the offset, or the `HRESULT` for `SetPosition`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Position = 3   ' 3 pt up
```

Microsoft Learn: [ITextFont::GetPosition](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getposition), [ITextFont::SetPosition](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setposition)

### Protected_, GetProtected, SetProtected

```freebasic
function GetProtected() as long
function SetProtected( byval Value as long ) as HRESULT
property Protected_() as long
property Protected_( byval Value as long )
```

Whether the text is protected. When the user tries to change protected text, the control sends
its parent an `EN_PROTECTED` notification (if `ENM_PROTECTED` is in its event mask), and the
parent decides whether to allow the change. The property is `Protected_` because `protected` is
a keyword.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetProtected`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Protected_ = tomTrue
```

Microsoft Learn: [ITextFont::GetProtected](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getprotected), [ITextFont::SetProtected](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setprotected)

### Shadow, GetShadow, SetShadow

```freebasic
function GetShadow() as long
function SetShadow( byval Value as long ) as HRESULT
property Shadow() as long
property Shadow( byval Value as long )
```

Whether the text has a shadow.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetShadow`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Shadow = tomTrue
```

Microsoft Learn: [ITextFont::GetShadow](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getshadow), [ITextFont::SetShadow](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setshadow)

### Size, GetSize, SetSize

```freebasic
function GetSize() as single
function SetSize( byval Value as single ) as HRESULT
property Size() as single
property Size( byval Value as single )
```

The font size in points. A range that mixes sizes reads `tomUndefined` (-9999999).

| Parameter | Meaning |
| --- | --- |
| `Value` | The size in points. |

**Returns** the size, or the `HRESULT` for `SetSize`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Size = f.Size + 2
```

Microsoft Learn: [ITextFont::GetSize](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getsize), [ITextFont::SetSize](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setsize)

### SmallCaps, GetSmallCaps, SetSmallCaps

```freebasic
function GetSmallCaps() as long
function SetSmallCaps( byval Value as long ) as HRESULT
property SmallCaps() as long
property SmallCaps( byval Value as long )
```

Whether lower-case letters are shown as small capitals.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetSmallCaps`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.SmallCaps = tomTrue
```

Microsoft Learn: [ITextFont::GetSmallCaps](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getsmallcaps), [ITextFont::SetSmallCaps](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setsmallcaps)

### Spacing, GetSpacing, SetSpacing

```freebasic
function GetSpacing() as single
function SetSpacing( byval Value as single ) as HRESULT
property Spacing() as single
property Spacing( byval Value as single )
```

Extra horizontal space between characters, in points; a negative value condenses the text.

| Parameter | Meaning |
| --- | --- |
| `Value` | The extra space in points. |

**Returns** the spacing, or the `HRESULT` for `SetSpacing`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Spacing = 2
```

Microsoft Learn: [ITextFont::GetSpacing](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getspacing), [ITextFont::SetSpacing](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setspacing)

### StrikeThrough, GetStrikeThrough, SetStrikeThrough

```freebasic
function GetStrikeThrough() as long
function SetStrikeThrough( byval Value as long ) as HRESULT
property StrikeThrough() as long
property StrikeThrough( byval Value as long )
```

Whether a horizontal line runs through the middle of the text.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetStrikeThrough`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.StrikeThrough = tomTrue
```

Microsoft Learn: [ITextFont::GetStrikeThrough](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getstrikethrough), [ITextFont::SetStrikeThrough](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setstrikethrough)

### Subscript, GetSubscript, SetSubscript

```freebasic
function GetSubscript() as long
function SetSubscript( byval Value as long ) as HRESULT
property Subscript() as long
property Subscript( byval Value as long )
```

Whether the text is subscript: smaller and lowered. Setting it turns
[Superscript](#superscript-getsuperscript-setsuperscript) off.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetSubscript`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 1, 2 )
dim f as CTextFont2 = rng.GetFont()
f.Subscript = tomTrue   ' the second character, as in H2O
```

Microsoft Learn: [ITextFont::GetSubscript](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getsubscript), [ITextFont::SetSubscript](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setsubscript)

### Superscript, GetSuperscript, SetSuperscript

```freebasic
function GetSuperscript() as long
function SetSuperscript( byval Value as long ) as HRESULT
property Superscript() as long
property Superscript( byval Value as long )
```

Whether the text is superscript: smaller and raised. Setting it turns
[Subscript](#subscript-getsubscript-setsubscript) off.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`: `tomTrue`, `tomFalse`, `tomToggle` or `tomUndefined`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetSuperscript`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 4, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Superscript = tomTrue
```

Microsoft Learn: [ITextFont::GetSuperscript](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getsuperscript), [ITextFont::SetSuperscript](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setsuperscript)

### Underline, GetUnderline, SetUnderline

```freebasic
function GetUnderline() as long
function SetUnderline( byval Value as long ) as HRESULT
property Underline() as long
property Underline( byval Value as long )
```

The type of underline: `tomNone` (0), `tomSingle`, `tomWords`, `tomDouble`, `tomDotted`,
`tomDash`, `tomWave`, `tomThick`, `tomHair` and the other `tom*` underline styles, or
`tomToggle` and `tomUndefined` as for a `tomBool`.

| Parameter | Meaning |
| --- | --- |
| `Value` | The underline type. |

**Returns** the underline type, or the `HRESULT` for `SetUnderline`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Underline = tomWave
```

Microsoft Learn: [ITextFont::GetUnderline](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getunderline), [ITextFont::SetUnderline](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setunderline)

### Weight, GetWeight, SetWeight

```freebasic
function GetWeight() as long
function SetWeight( byval Value as long ) as HRESULT
property Weight() as long
property Weight( byval Value as long )
```

The font weight, from 1 to 1000 as for `LOGFONTW`: 400 is normal and 700 bold (`FW_NORMAL`,
`FW_BOLD`).

| Parameter | Meaning |
| --- | --- |
| `Value` | The weight. |

**Returns** the weight, or the `HRESULT` for `SetWeight`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Weight = FW_SEMIBOLD
```

Microsoft Learn: [ITextFont::GetWeight](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-getweight), [ITextFont::SetWeight](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont-setweight)

### Count, GetCount

```freebasic
function GetCount() as long
function Count() as long
```

The number of extra properties in the formatting, the ones [PropertyInfo](#propertyinfo-getpropertyinfo)
enumerates. Text with plain formatting has none.

**Returns** the count.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
print "extra properties:"; f.Count()   ' 0
```

Microsoft Learn: [ITextFont2::GetCount](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getcount)

### AutoLigatures, GetAutoLigatures, SetAutoLigatures

```freebasic
function GetAutoLigatures() as long
function SetAutoLigatures( byval Value as long ) as HRESULT
property AutoLigatures() as long
property AutoLigatures( byval Value as long )
```

Whether the font's ligatures (such as "fi" drawn as one glyph) are used automatically.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetAutoLigatures`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.AutoLigatures = tomTrue
```

Microsoft Learn: [ITextFont2::GetAutoLigatures](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getautoligatures), [ITextFont2::SetAutoLigatures](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setautoligatures)

### AutospaceAlpha, GetAutospaceAlpha, SetAutospaceAlpha

```freebasic
function GetAutospaceAlpha() as long
function SetAutospaceAlpha( byval Value as long ) as HRESULT
property AutospaceAlpha() as long
property AutospaceAlpha( byval Value as long )
```

The East Asian "autospace alphabetics" setting: extra space between East Asian and Latin text.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetAutospaceAlpha`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.AutospaceAlpha = tomTrue
```

Microsoft Learn: [ITextFont2::GetAutospaceAlpha](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getautospacealpha), [ITextFont2::SetAutospaceAlpha](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setautospacealpha)

### AutospaceNumeric, GetAutospaceNumeric, SetAutospaceNumeric

```freebasic
function GetAutospaceNumeric() as long
function SetAutospaceNumeric( byval Value as long ) as HRESULT
property AutospaceNumeric() as long
property AutospaceNumeric( byval Value as long )
```

The East Asian "autospace numeric" setting: extra space between East Asian text and digits.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetAutospaceNumeric`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.AutospaceNumeric = tomTrue
```

Microsoft Learn: [ITextFont2::GetAutospaceNumeric](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getautospacenumeric), [ITextFont2::SetAutospaceNumeric](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setautospacenumeric)

### AutospaceParens, GetAutospaceParens, SetAutospaceParens

```freebasic
function GetAutospaceParens() as long
function SetAutospaceParens( byval Value as long ) as HRESULT
property AutospaceParens() as long
property AutospaceParens( byval Value as long )
```

The East Asian "autospace parentheses" setting: adjusted space around parentheses.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetAutospaceParens`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.AutospaceParens = tomTrue
```

Microsoft Learn: [ITextFont2::GetAutospaceParens](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getautospaceparens), [ITextFont2::SetAutospaceParens](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setautospaceparens)

### CharRep, GetCharRep, SetCharRep

```freebasic
function GetCharRep() as long
function SetCharRep( byval Value as long ) as HRESULT
property CharRep() as long
property CharRep( byval Value as long )
```

The character repertoire, the writing system the font is chosen for: `tomAnsi` (0, Latin),
`tomEastEurope`, `tomCyrillic`, `tomGreek`, `tomHebrew`, `tomArabic` and the other `tom*`
repertoires up to `tomCharRepMax`.

| Parameter | Meaning |
| --- | --- |
| `Value` | The repertoire. |

**Returns** the repertoire, or the `HRESULT` for `SetCharRep`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.CharRep = tomGreek
```

Microsoft Learn: [ITextFont2::GetCharRep](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getcharrep), [ITextFont2::SetCharRep](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setcharrep)

### CompressionMode, GetCompressionMode, SetCompressionMode

```freebasic
function GetCompressionMode() as long
function SetCompressionMode( byval Value as long = tomCompressNone ) as HRESULT
property CompressionMode() as long
property CompressionMode( byval Value as long )
```

The East Asian compression mode: `tomCompressNone` (0, the default of `SetCompressionMode`),
`tomCompressPunctuation` or `tomCompressPunctuationAndKana`. On the control `CRichEditCtx`
creates, reading it returns `tomUndefined`.

| Parameter | Meaning |
| --- | --- |
| `Value` | The compression mode. |

**Returns** the mode, or the `HRESULT` for `SetCompressionMode`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.SetCompressionMode( tomCompressPunctuation )
```

Microsoft Learn: [ITextFont2::GetCompressionMode](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getcompressionmode), [ITextFont2::SetCompressionMode](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setcompressionmode)

### Cookie, GetCookie, SetCookie

```freebasic
function GetCookie() as long
function SetCookie( byval Value as long ) as HRESULT
property Cookie() as long
property Cookie( byval Value as long )
```

A 32-bit value of your own kept with the character formatting. The control does not use it.

| Parameter | Meaning |
| --- | --- |
| `Value` | The value to store. |

**Returns** the value, or the `HRESULT` for `SetCookie`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Cookie = 42
print f.Cookie   ' 42
```

Microsoft Learn: [ITextFont2::GetCookie](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getcookie), [ITextFont2::SetCookie](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setcookie)

### DoubleStrike, GetDoubleStrike, SetDoubleStrike

```freebasic
function GetDoubleStrike() as long
function SetDoubleStrike( byval Value as long ) as HRESULT
property DoubleStrike() as long
property DoubleStrike( byval Value as long )
```

Whether two horizontal lines run through the middle of the text.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetDoubleStrike`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.DoubleStrike = tomTrue
```

Microsoft Learn: [ITextFont2::GetDoubleStrike](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getdoublestrike), [ITextFont2::SetDoubleStrike](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setdoublestrike)

### LinkType, GetLinkType

```freebasic
function GetLinkType() as long
function LinkType() as long
```

The kind of link the text belongs to: `tomNoLink` (0), `tomClientLink`, `tomFriendlyLinkName`,
`tomFriendlyLinkAddress`, `tomAutoLinkURL`, `tomAutoLinkEmail`, `tomAutoLinkPhone` or
`tomAutoLinkPath`. It is read-only.

**Returns** the link type.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
if f.LinkType() = tomAutoLinkURL then print "a URL"
```

Microsoft Learn: [ITextFont2::GetLinkType](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getlinktype)

### MathZone, GetMathZone, SetMathZone

```freebasic
function GetMathZone() as long
function SetMathZone( byval Value as long ) as HRESULT
property MathZone() as long
property MathZone( byval Value as long )
```

Whether the text is a math zone, laid out as mathematics.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetMathZone`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
print "math zone"; f.MathZone
```

Microsoft Learn: [ITextFont2::GetMathZone](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getmathzone), [ITextFont2::SetMathZone](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setmathzone)

### ModWidthPairs, GetModWidthPairs, SetModWidthPairs

```freebasic
function GetModWidthPairs() as long
function SetModWidthPairs( byval Value as long ) as HRESULT
property ModWidthPairs() as long
property ModWidthPairs( byval Value as long )
```

The "decrease widths on pairs" setting: narrower spacing for certain pairs of East Asian
characters.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetModWidthPairs`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.ModWidthPairs = tomTrue
```

Microsoft Learn: [ITextFont2::GetModWidthPairs](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getmodwidthpairs), [ITextFont2::SetModWidthPairs](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setmodwidthpairs)

### ModWidthSpace, GetModWidthSpace, SetModWidthSpace

```freebasic
function GetModWidthSpace() as long
function SetModWidthSpace( byval Value as long ) as HRESULT
property ModWidthSpace() as long
property ModWidthSpace( byval Value as long )
```

The "increase width of white space" setting.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetModWidthSpace`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.ModWidthSpace = tomTrue
```

Microsoft Learn: [ITextFont2::GetModWidthSpace](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getmodwidthspace), [ITextFont2::SetModWidthSpace](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setmodwidthspace)

### OldNumbers, GetOldNumbers, SetOldNumbers

```freebasic
function GetOldNumbers() as long
function SetOldNumbers( byval Value as long ) as HRESULT
property OldNumbers() as long
property OldNumbers( byval Value as long )
```

Whether digits use the font's old-style (text) figures, which rise and descend like lower-case
letters.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetOldNumbers`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.OldNumbers = tomTrue
```

Microsoft Learn: [ITextFont2::GetOldNumbers](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getoldnumbers), [ITextFont2::SetOldNumbers](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setoldnumbers)

### Overlapping, GetOverlapping, SetOverlapping

```freebasic
function GetOverlapping() as long
function SetOverlapping( byval Value as long ) as HRESULT
property Overlapping() as long
property Overlapping( byval Value as long )
```

Whether overlapping text is active.

| Parameter | Meaning |
| --- | --- |
| `Value` | A `tomBool`. |

**Returns** the `tomBool`, or the `HRESULT` for `SetOverlapping`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Overlapping = tomTrue
```

Microsoft Learn: [ITextFont2::GetOverlapping](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getoverlapping), [ITextFont2::SetOverlapping](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setoverlapping)

### PositionSubSuper, GetPositionSubSuper, SetPositionSubSuper

```freebasic
function GetPositionSubSuper() as long
function SetPositionSubSuper( byval Value as long ) as HRESULT
property PositionSubSuper() as long
property PositionSubSuper( byval Value as long )
```

How far subscript or superscript text sits from the baseline, as a percentage of the font
height.

| Parameter | Meaning |
| --- | --- |
| `Value` | The offset in percent. |

**Returns** the offset, or the `HRESULT` for `SetPositionSubSuper`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 4, 5 )
dim f as CTextFont2 = rng.GetFont()
f.Superscript = tomTrue
f.PositionSubSuper = 30
```

Microsoft Learn: [ITextFont2::GetPositionSubSuper](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getpositionsubsuper), [ITextFont2::SetPositionSubSuper](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setpositionsubsuper)

### Scaling, GetScaling, SetScaling

```freebasic
function GetScaling() as long
function SetScaling( byval Value as long ) as HRESULT
property Scaling() as long
property Scaling( byval Value as long )
```

The horizontal scaling of the text, in percent: 100 is normal width. On the control
`CRichEditCtx` creates, reading it returns `tomUndefined`, and setting it returns `S_OK` without
changing what is read back.

| Parameter | Meaning |
| --- | --- |
| `Value` | The scaling in percent. |

**Returns** the scaling, or the `HRESULT` for `SetScaling`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.SetScaling( 150 )
```

Microsoft Learn: [ITextFont2::GetScaling](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getscaling), [ITextFont2::SetScaling](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setscaling)

### SpaceExtension, GetSpaceExtension, SetSpaceExtension

```freebasic
function GetSpaceExtension() as long
function SetSpaceExtension( byval Value as long ) as HRESULT
property SpaceExtension() as long
property SpaceExtension( byval Value as long )
```

The East Asian space extension value.

| Parameter | Meaning |
| --- | --- |
| `Value` | The space extension. |

**Returns** the value, or the `HRESULT` for `SetSpaceExtension`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
print "space extension"; f.SpaceExtension
```

Microsoft Learn: [ITextFont2::GetSpaceExtension](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getspaceextension), [ITextFont2::SetSpaceExtension](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setspaceextension)

### UnderlinePositionMode, GetUnderlinePositionMode, SetUnderlinePositionMode

```freebasic
function GetUnderlinePositionMode() as long
function SetUnderlinePositionMode( byval Value as long = tomUnderlinePositionAuto ) as HRESULT
property UnderlinePositionMode() as long
property UnderlinePositionMode( byval Value as long )
```

Where the underline is drawn: `tomUnderlinePositionAuto` (0, the default of
`SetUnderlinePositionMode`), `tomUnderlinePositionBelow` or `tomUnderlinePositionAbove`. On the
control `CRichEditCtx` creates, reading it returns `tomUndefined`, and setting it returns `S_OK`
without changing what is read back.

| Parameter | Meaning |
| --- | --- |
| `Value` | The position mode. |

**Returns** the mode, or the `HRESULT` for `SetUnderlinePositionMode`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.SetUnderlinePositionMode( tomUnderlinePositionBelow )
```

Microsoft Learn: [ITextFont2::GetUnderlinePositionMode](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getunderlinepositionmode), [ITextFont2::SetUnderlinePositionMode](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setunderlinepositionmode)

### GetEffects, SetEffects

```freebasic
function GetEffects( byref Value as long, byref Mask as long ) as HRESULT
function SetEffects( byval Value as long, byval Mask as long ) as HRESULT
```

Reads or sets several on/off attributes in one call, as bits: `tomBold`, `tomItalic`,
`tomUnderline`, `tomStrikeout`, `tomProtected`, `tomLink`, `tomSmallCaps`, `tomAllCaps`,
`tomHidden`, `tomOutline`, `tomShadow`, `tomEmboss`, `tomImprint`, `tomSubscriptCF`,
`tomSuperscriptCF` and the other `tom*` effect flags. `Mask` says which bits count: for
`GetEffects` it receives the bits whose value is the same throughout the text, for `SetEffects`
it names the bits to change.

| Parameter | Meaning |
| --- | --- |
| `Value` | The effect bits (received by `GetEffects`). |
| `Mask` | Which bits are defined (`GetEffects`) or to change (`SetEffects`). |

**Returns** `S_OK` on success, otherwise an error code.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.SetEffects( tomBold or tomItalic, tomBold or tomItalic )   ' both on
dim as long v, m
f.GetEffects( v, m )
```

Microsoft Learn: [ITextFont2::GetEffects](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-geteffects), [ITextFont2::SetEffects](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-seteffects)

### GetEffects2, SetEffects2

```freebasic
function GetEffects2( byref Value as long, byref Mask as long ) as HRESULT
function SetEffects2( byval Value as long, byval Mask as long ) as HRESULT
```

The same for the `ITextFont2` attributes: `tomModWidthPairs`, `tomModWidthSpace`,
`tomAutoSpaceAlpha`, `tomAutoSpaceNumeric`, `tomAutoSpaceParens`, `tomEmbeddedFont`,
`tomDoublestrike` and `tomOverlapping`. `GetEffects2` works on the rich edit control of current
Windows versions; `SetEffects2` returns `E_NOTIMPL` (`&h80004001`) there, so set these one at a
time with their own properties.

| Parameter | Meaning |
| --- | --- |
| `Value` | The effect bits (received by `GetEffects2`). |
| `Mask` | Which bits are defined (`GetEffects2`) or to change (`SetEffects2`). |

**Returns** `S_OK` on success, otherwise an error code.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
dim as long v, m
if f.GetEffects2( v, m ) = S_OK andalso ( m and tomDoublestrike ) then print "double strike:"; ( v and tomDoublestrike ) <> 0
```

Microsoft Learn: [ITextFont2::GetEffects2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-geteffects2), [ITextFont2::SetEffects2](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-seteffects2)

### Property_, GetProperty, SetProperty

```freebasic
function GetProperty( byval nType as long ) as long
function SetProperty( byval nType as long, byval Value as long ) as HRESULT
property Property_( byval nType as long ) as long
property Property_( byval nType as long, byval Value as long )
```

Reads or sets an extra property by its id: `tomFontStretch`, `tomFontStyle`, `tomFontPropAlign`,
`tomFontPropTeXStyle` and the other `tomFont*` ids. The property is `Property_` because
`property` is a keyword.

| Parameter | Meaning |
| --- | --- |
| `nType` | The property id. |
| `Value` | The new value. |

**Returns** the value, or the `HRESULT` for `SetProperty`.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
f.SetProperty( tomFontStretch, 3 )
print f.GetProperty( tomFontStretch )   ' 3
```

Microsoft Learn: [ITextFont2::GetProperty](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getproperty), [ITextFont2::SetProperty](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-setproperty)

### PropertyInfo, GetPropertyInfo

```freebasic
function GetPropertyInfo( byval Index as long, byval pType as long ptr, byval pValue as long ptr ) as HRESULT
function PropertyInfo( byval Index as long, byval pType as long ptr, byval pValue as long ptr ) as HRESULT
```

Reads the id and value of the extra property at `Index` (0 to [Count](#count-getcount) - 1).
These are the only members that check for an empty object: then they return `E_POINTER`. On the
rich edit control of current Windows versions the method returns `E_NOTIMPL` (`&h80004001`).

| Parameter | Meaning |
| --- | --- |
| `Index` | The index of the property. |
| `pType` | Receives the property id. |
| `pValue` | Receives the value. |

**Returns** `S_OK` on success, otherwise an error code.

**Example**

```freebasic
dim rng as CTextRange2 = CRichEditCtxPtr( hCtrl )->Range( 0, 5 )
dim f as CTextFont2 = rng.GetFont()
dim as long id, v
for i as long = 0 to f.Count() - 1
    if f.GetPropertyInfo( i, @id, @v ) = S_OK then print hex( id ); " ="; v
next
```

Microsoft Learn: [ITextFont2::GetPropertyInfo](https://learn.microsoft.com/en-us/windows/win32/api/tom/nf-tom-itextfont2-getpropertyinfo)

## See also

- [sys/win/richedit](SysWin-RichEdit)
- [CTextRange2](CTextRange2) and [CTextSelection2](CTextSelection2), where a font object comes from
- [CTextPara2](CTextPara2) for paragraph formatting
- [CRichEditCtx: document](CRichEditCtx-Document) for the document's default font
- [Text Object Model](SysWin-RichEdit-TOM)
- [Colours](SysWin-Colors) for ready-made `COLORREF` values
