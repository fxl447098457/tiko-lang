[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gdiplus](SysWin-GdiPlus) › **CGpStringFormat**

# CGpStringFormat

Sets how GDI+ lays out text in a rectangle: alignment, wrapping, trimming and tab stops.

A `CGpStringFormat` wraps one GDI+ `StringFormat` object. You pass its address to the
`DrawString`, `MeasureString` and `MeasureCharacterRanges` methods of
[CGpGraphics](CGpGraphics) (and to `AddString` of a [path](CGpGraphicsPath)); without one, text
is drawn left-aligned from the top-left corner and wraps at word boundaries.

The settings, and the values they take:

| Setting | Values | Default |
| --- | --- | --- |
| [Alignment](#setalignment) (along the line) and [line alignment](#setlinealignment) (across lines) | `StringAlignmentNear` (0), `StringAlignmentCenter` (1), `StringAlignmentFar` (2) | `StringAlignmentNear` |
| [Format flags](#setformatflags) | `StringFormatFlags*`, combined with `or`: `DirectionRightToLeft` (1), `DirectionVertical` (2), `NoFitBlackBox` (4), `DisplayFormatControl` (&h20), `NoFontFallback` (&h400), `MeasureTrailingSpaces` (&h800), `NoWrap` (&h1000), `LineLimit` (&h2000), `NoClip` (&h4000), `BypassGDI` (&h80000000) | 0 |
| [Trimming](#settrimming), when the text does not fit | `StringTrimmingNone` (0), `Character` (1), `Word` (2), `EllipsisCharacter` (3), `EllipsisWord` (4), `EllipsisPath` (5) | `StringTrimmingCharacter` |
| [Hot-key prefix](#sethotkeyprefix), what `&` does | `HotkeyPrefixNone` (0), `HotkeyPrefixShow` (1, underlines the next character), `HotkeyPrefixHide` (2) | `HotkeyPrefixNone` |

"Near" is the left edge (the top, for line alignment) in left-to-right text and the right edge
with `StringFormatFlagsDirectionRightToLeft`.

**Lifetime.** The destructor deletes the GDI+ object. Never copy a `CGpStringFormat` by value
(no `=` from another one, no `byval` parameter): both copies would delete the same object. Copy
with `dim b as CGpStringFormat = @a` or [Clone](#clone).

**Status.** The setters return a `GpStatus`: `Ok` (0) on success, otherwise the reason. The
status is also stored, the getters store theirs, and `GetLastStatus()`, inherited from
[CGpBase](SysWin-GdiPlus-Procedures#cgpbase), returns it.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gdiplus"
using win, gdiplus
```

## Example

A window that centres a caption in a box, both ways, and fits a long line into a narrower box
on one line, cut at a word with an ellipsis:

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/gdiplus"
using win, gui, gdiplus

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim token as ULONG_PTR = gdiplus.Init()
    dim pWindow as CWindow = "GpStringFormatDemo"
    pWindow.Create( NULL, "CGpStringFormat", @WndProc )
    pWindow.SetClientSize( 360, 200 )
    pWindow.Center
    dim nResult as long = pWindow.DoEvents( SW_NORMAL )
    gdiplus.Uninit( token )
    return nResult
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_PAINT
            dim ps as PAINTSTRUCT
            dim hdc as HDC = BeginPaint( hwnd, @ps )
            scope
                dim g as CGpGraphics = hdc
                g.ScaleTransformForDpi()
                g.SetTextRenderingHint( TextRenderingHintAntiAlias )
                g.Clear( ARGB_White )
                dim fnt as CGpFont = CGpFont( "Segoe UI", 16 )
                dim ink as CGpSolidBrush = CGpSolidBrush( ARGB_Black )
                dim frame as CGpPen = CGpPen( ARGB_Gray )

                ' centred both ways
                dim centred as CGpStringFormat
                centred.SetAlignment( StringAlignmentCenter )
                centred.SetLineAlignment( StringAlignmentCenter )
                dim box1 as GpRectF = GDIP_RECTF( 20, 20, 320, 80 )
                g.DrawRectangle( @frame, @box1 )
                g.DrawString( "Centred in the box", -1, @fnt, @box1, @centred, @ink )

                ' one line, trimmed at a word with an ellipsis
                dim oneLine as CGpStringFormat = CGpStringFormat( StringFormatFlagsNoWrap )
                oneLine.SetTrimming( StringTrimmingEllipsisWord )
                oneLine.SetLineAlignment( StringAlignmentCenter )
                dim box2 as GpRectF = GDIP_RECTF( 20, 120, 220, 40 )
                g.DrawRectangle( @frame, @box2 )
                g.DrawString( "This sentence is far too long to fit in the box", -1, @fnt, @box2, @oneLine, @ink )
            end scope
            EndPaint( hwnd, @ps )
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
| [Constructor](#constructor) | Creates a string format from flags and a language, or copies one. |
| [Destructor](#destructor) | Deletes the GDI+ string format. |
| [Clone](#clone) | Copies this string format into another `CGpStringFormat`. |
| [GenericDefault](#genericdefault) | Puts a copy of the generic default format into another object. |
| [GenericTypographic](#generictypographic) | Puts a copy of the generic typographic format into another object. |
| [SetFormatFlags](#setformatflags) | Sets the format flags. |
| [GetFormatFlags](#getformatflags) | Returns the format flags. |
| [SetAlignment](#setalignment) | Sets the alignment along each line. |
| [GetAlignment](#getalignment) | Returns the alignment. |
| [SetLineAlignment](#setlinealignment) | Sets the alignment of the lines in the rectangle. |
| [GetLineAlignment](#getlinealignment) | Returns the line alignment. |
| [SetHotkeyPrefix](#sethotkeyprefix) | Sets what an `&` in the text does. |
| [GetHotkeyPrefix](#gethotkeyprefix) | Returns what an `&` in the text does. |
| [SetTabStops](#settabstops) | Sets the tab stops. |
| [GetTabStopCount](#gettabstopcount) | Returns how many tab stops are set. |
| [GetTabStops](#gettabstops) | Copies the tab stops into an array. |
| [SetDigitSubstitution](#setdigitsubstitution) | Sets which digits are drawn for `0`–`9`. |
| [GetDigitSubstitutionLanguage](#getdigitsubstitutionlanguage) | Returns the language used for digit substitution. |
| [GetDigitSubstitutionMethod](#getdigitsubstitutionmethod) | Returns the digit substitution method. |
| [SetTrimming](#settrimming) | Sets how text that does not fit is cut. |
| [GetTrimming](#gettrimming) | Returns how text that does not fit is cut. |
| [SetMeasurableCharacterRanges](#setmeasurablecharacterranges) | Sets the character ranges `MeasureCharacterRanges` measures. |
| [GetMeasurableCharacterRangeCount](#getmeasurablecharacterrangecount) | Returns how many character ranges are set. |

## Reference

### Constructor

```freebasic
constructor( byval pStringFormat as CGpStringFormat ptr )
constructor( byval formatFlags as INT_ = 0, byval language as LANGID = LANG_NEUTRAL )
```

Creates the GDI+ string format:

- **No argument, or flags and a language**: a new format with those `StringFormatFlags*` and
  everything else at its default (see the table at the top). `language` is the language of
  the text; `LANG_NEUTRAL` (the default) uses the user's.
- **`pStringFormat`**: an independent copy of another string format, with all its settings.
  The pointer must not be `NULL`.

| Parameter | Meaning |
| --- | --- |
| `pStringFormat` | The string format to copy. |
| `formatFlags` | `StringFormatFlags*` values, combined with `or`. |
| `language` | A `LANGID`. |

**Example**

```freebasic
dim sf as CGpStringFormat                                  ' defaults
dim vert as CGpStringFormat = CGpStringFormat( StringFormatFlagsDirectionVertical )
dim copy as CGpStringFormat = @vert
print copy.GetFormatFlags()                                ' 2
```

Microsoft Learn: [StringFormat::StringFormat](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-stringformat%28int_langid%29)

### Destructor

```freebasic
destructor
```

Deletes the GDI+ string format.

**Example**

```freebasic
dim pFormat as CGpStringFormat ptr = new CGpStringFormat( StringFormatFlagsNoWrap )
delete pFormat
```

### Clone

```freebasic
function Clone( byval pStringFormat as CGpStringFormat ptr ) as GpStatus
```

Copies this string format, with all its settings, into the existing `CGpStringFormat` that
`pStringFormat` points to; the object's previous GDI+ format is deleted first.

**Returns** `Ok` on success; `InvalidParameter` when the pointer is `NULL`.

**Example**

```freebasic
dim a as CGpStringFormat
a.SetLineAlignment( StringAlignmentFar )
dim b as CGpStringFormat
if a.Clone( @b ) = Ok then print b.GetLineAlignment()   ' 2
```

Microsoft Learn: [StringFormat::Clone](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-clone)

### GenericDefault

```freebasic
function GenericDefault( byval pStringFormat as CGpStringFormat ptr ) as GpStatus
```

Replaces the format held by the `CGpStringFormat` that `pStringFormat` points to with a copy of
GDI+'s **generic default** format: no flags, near alignment, character trimming. The object the
method is called on is not changed; you can call it on the target itself.

**Returns** `Ok` on success; `InvalidParameter` when the pointer is `NULL`.

**Example**

```freebasic
dim sf as CGpStringFormat = CGpStringFormat( StringFormatFlagsNoWrap )
sf.GenericDefault( @sf )
print sf.GetFormatFlags(); sf.GetTrimming()   ' 0 1
```

Microsoft Learn: [StringFormat::GenericDefault](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-genericdefault)

### GenericTypographic

```freebasic
function GenericTypographic( byval pStringFormat as CGpStringFormat ptr ) as GpStatus
```

Replaces the format held by the `CGpStringFormat` that `pStringFormat` points to with a copy of
GDI+'s **generic typographic** format, which measures and draws text without the extra space
GDI+ normally adds around it: the flags `StringFormatFlagsNoFitBlackBox`,
`StringFormatFlagsLineLimit` and `StringFormatFlagsNoClip` (&h6004) and no trimming. Use it
with `MeasureString` when strings are measured to be placed side by side.

**Returns** `Ok` on success; `InvalidParameter` when the pointer is `NULL`.

**Example**

```freebasic
dim typo as CGpStringFormat
typo.GenericTypographic( @typo )
print hex( typo.GetFormatFlags() ); typo.GetTrimming()   ' 6004 0
```

Microsoft Learn: [StringFormat::GenericTypographic](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-generictypographic)

### SetFormatFlags

```freebasic
function SetFormatFlags( byval flags as INT_ ) as GpStatus
```

Replaces the format flags with `flags`, `StringFormatFlags*` values combined with `or` (see the
table at the top). To add one flag, `or` it into [GetFormatFlags](#getformatflags).

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetFormatFlags( sf.GetFormatFlags() or StringFormatFlagsNoWrap or StringFormatFlagsNoClip )
```

Microsoft Learn: [StringFormat::SetFormatFlags](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-setformatflags)

### GetFormatFlags

```freebasic
function GetFormatFlags() as INT_
```

Returns the format flags.

**Example**

```freebasic
dim sf as CGpStringFormat = CGpStringFormat( StringFormatFlagsNoWrap )
if sf.GetFormatFlags() and StringFormatFlagsNoWrap then print "one line"
```

Microsoft Learn: [StringFormat::GetFormatFlags](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-getformatflags)

### SetAlignment

```freebasic
function SetAlignment( byval nAlign as StringAlignment ) as GpStatus
```

Sets where each line goes along the width of the layout rectangle: `StringAlignmentNear`
(left in left-to-right text), `StringAlignmentCenter` or `StringAlignmentFar`. With a point
instead of a rectangle, the text is placed relative to the point.

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetAlignment( StringAlignmentFar )   ' right-aligned
```

Microsoft Learn: [StringFormat::SetAlignment](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-setalignment)

### GetAlignment

```freebasic
function GetAlignment() as StringAlignment
```

**Returns** the alignment set by [SetAlignment](#setalignment).

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetAlignment( StringAlignmentCenter )
print sf.GetAlignment()
```

Microsoft Learn: [StringFormat::GetAlignment](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-getalignment)

### SetLineAlignment

```freebasic
function SetLineAlignment( byval nAlign as StringAlignment ) as GpStatus
```

Sets where the block of lines goes across the layout rectangle: `StringAlignmentNear` (the top),
`StringAlignmentCenter` or `StringAlignmentFar` (the bottom).

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetLineAlignment( StringAlignmentCenter )   ' vertically centred
```

Microsoft Learn: [StringFormat::SetLineAlignment](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-setlinealignment)

### GetLineAlignment

```freebasic
function GetLineAlignment() as StringAlignment
```

Returns the line alignment.

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetLineAlignment( StringAlignmentFar )
print sf.GetLineAlignment()   ' 2
```

Microsoft Learn: [StringFormat::GetLineAlignment](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-getlinealignment)

### SetHotkeyPrefix

```freebasic
function SetHotkeyPrefix( byval nHotkeyPrefix as HotkeyPrefix ) as GpStatus
```

Sets what an ampersand in the text does: `HotkeyPrefixNone` draws it, `HotkeyPrefixShow` hides it
and underlines the character after it, as in menus, and `HotkeyPrefixHide` hides it without
underlining.

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetHotkeyPrefix( HotkeyPrefixShow )   ' "&Open" draws Open with O underlined
```

Microsoft Learn: [StringFormat::SetHotkeyPrefix](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-sethotkeyprefix)

### GetHotkeyPrefix

```freebasic
function GetHotkeyPrefix() as HotkeyPrefix
```

Returns what an ampersand in the text does.

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetHotkeyPrefix( HotkeyPrefixShow )
print sf.GetHotkeyPrefix()   ' 1
```

Microsoft Learn: [StringFormat::GetHotkeyPrefix](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-gethotkeyprefix)

### SetTabStops

```freebasic
function SetTabStops( byval firstTabOffset as single, byval nCount as INT_, byval tabStops as single ptr ) as GpStatus
```

Sets the tab stops that a tab character (`!"\t"`) moves to. The first stop is `firstTabOffset`
plus `tabStops[0]` from the start of the line; each further stop is `tabStops[i]` after the one
before. Distances are in the units of the graphics object that draws the text.

| Parameter | Meaning |
| --- | --- |
| `firstTabOffset` | Where the tab stops start, from the start of the line. |
| `nCount` | How many tab stops. |
| `tabStops` | The first element of an array of `nCount` distances. |

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim tabs(0 to 2) as single = { 80, 80, 120 }
dim sf as CGpStringFormat
sf.SetTabStops( 0, 3, @tabs(0) )   ' stops at 80, 160 and 280
```

Microsoft Learn: [StringFormat::SetTabStops](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-settabstops)

### GetTabStopCount

```freebasic
function GetTabStopCount() as INT_
```

Returns how many tab stops are set.

**Example**

```freebasic
dim tabs(0 to 2) as single = { 40, 40, 80 }
dim sf as CGpStringFormat
sf.SetTabStops( 10, 3, @tabs(0) )
print sf.GetTabStopCount()   ' 3
```

Microsoft Learn: [StringFormat::GetTabStopCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-gettabstopcount)

### GetTabStops

```freebasic
function GetTabStops( byval nCount as INT_, byval firstTabOffset as single ptr, byval tabStops as single ptr ) as GpStatus
```

Copies the first tab-stop offset into `*firstTabOffset` and up to `nCount` tab-stop distances
into the array `tabStops`. Get the number to ask for with [GetTabStopCount](#gettabstopcount).

| Parameter | Meaning |
| --- | --- |
| `nCount` | The size of the array. |
| `firstTabOffset` | Receives the offset of the first stop. |
| `tabStops` | The first element of the array that receives the distances. |

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim tabs(0 to 2) as single = { 40, 40, 80 }
dim sf as CGpStringFormat
sf.SetTabStops( 10, 3, @tabs(0) )
dim first as single, got(0 to 2) as single
if sf.GetTabStops( 3, @first, @got(0) ) = Ok then print first; got(0); got(1); got(2)   ' 10 40 40 80
```

Microsoft Learn: [StringFormat::GetTabStops](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-gettabstops)

### SetDigitSubstitution

```freebasic
function SetDigitSubstitution( byval language as LANGID, byval substitute as StringDigitSubstitute ) as GpStatus
```

Sets which digit shapes are drawn for the characters `0` to `9`: those of `language`, chosen by
the method `substitute`, one of `StringDigitSubstituteUser` (0, as the user's settings say),
`StringDigitSubstituteNone` (1, always the Latin digits), `StringDigitSubstituteNational` (2,
the language's own digits) or `StringDigitSubstituteTraditional` (3, the digits of the script
around them).

| Parameter | Meaning |
| --- | --- |
| `language` | The language whose digits are used, such as `LANG_ARABIC`. |
| `substitute` | The method. |

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetDigitSubstitution( LANG_ARABIC, StringDigitSubstituteNational )
```

Microsoft Learn: [StringFormat::SetDigitSubstitution](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-setdigitsubstitution)

### GetDigitSubstitutionLanguage

```freebasic
function GetDigitSubstitutionLanguage() as LANGID
```

Returns the language set by [SetDigitSubstitution](#setdigitsubstitution).

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetDigitSubstitution( LANG_ARABIC, StringDigitSubstituteNational )
print sf.GetDigitSubstitutionLanguage()   ' 1: LANG_ARABIC
```

Microsoft Learn: [StringFormat::GetDigitSubstitutionLanguage](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-getdigitsubstitutionlanguage)

### GetDigitSubstitutionMethod

```freebasic
function GetDigitSubstitutionMethod() as StringDigitSubstitute
```

Returns the method set by [SetDigitSubstitution](#setdigitsubstitution); a new format has
`StringDigitSubstituteUser` (0).

**Example**

```freebasic
dim sf as CGpStringFormat
sf.SetDigitSubstitution( LANG_ARABIC, StringDigitSubstituteNational )
print sf.GetDigitSubstitutionMethod()   ' 2
```

Microsoft Learn: [StringFormat::GetDigitSubstitutionMethod](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-getdigitsubstitutionmethod)

### SetTrimming

```freebasic
function SetTrimming( byval trimming as StringTrimming ) as GpStatus
```

Sets how text that does not fit in the layout rectangle is cut: at a character
(`StringTrimmingCharacter`, the default), at a word (`StringTrimmingWord`), the same with an
ellipsis (`StringTrimmingEllipsisCharacter`, `StringTrimmingEllipsisWord`), with an ellipsis in
the middle that keeps the end of a file path (`StringTrimmingEllipsisPath`), or not at all
(`StringTrimmingNone`). Lines that wrap are only trimmed on the last line that fits; combine with
`StringFormatFlagsNoWrap` to trim a single line.

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim sf as CGpStringFormat = CGpStringFormat( StringFormatFlagsNoWrap )
sf.SetTrimming( StringTrimmingEllipsisPath )   ' C:\Users\...\report.txt
```

Microsoft Learn: [StringFormat::SetTrimming](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-settrimming)

### GetTrimming

```freebasic
function GetTrimming() as StringTrimming
```

Returns the trimming style.

**Example**

```freebasic
dim sf as CGpStringFormat
print sf.GetTrimming()   ' 1: StringTrimmingCharacter
```

Microsoft Learn: [StringFormat::GetTrimming](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-gettrimming)

### SetMeasurableCharacterRanges

```freebasic
function SetMeasurableCharacterRanges( byval rangeCount as INT_, byval ranges as GpCharacterRange ptr ) as GpStatus
```

Sets the ranges of characters, each a `GpCharacterRange` with a 0-based `First` and a `Length`,
whose position [CGpGraphics](CGpGraphics) `MeasureCharacterRanges` reports as one region each.
Use it to find where a word ends up in laid-out text, for hit-testing or highlighting.

| Parameter | Meaning |
| --- | --- |
| `rangeCount` | How many ranges: at most 32; more fails with `ValueOverflow` (11). |
| `ranges` | The first element of an array of `rangeCount` ranges. |

**Returns** `Ok` on success, otherwise the reason.

**Example**

```freebasic
dim ranges(0 to 1) as GpCharacterRange
ranges(0).First = 0 : ranges(0).Length = 5      ' "Hello"
ranges(1).First = 6 : ranges(1).Length = 5      ' "world"
dim sf as CGpStringFormat
sf.SetMeasurableCharacterRanges( 2, @ranges(0) )
```

Microsoft Learn: [StringFormat::SetMeasurableCharacterRanges](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-setmeasurablecharacterranges)

### GetMeasurableCharacterRangeCount

```freebasic
function GetMeasurableCharacterRangeCount() as INT_
```

Returns how many character ranges are set: the number of regions `MeasureCharacterRanges` needs.

**Example**

```freebasic
dim ranges(0 to 1) as GpCharacterRange
ranges(0).First = 0 : ranges(0).Length = 2 : ranges(1).First = 3 : ranges(1).Length = 1
dim sf as CGpStringFormat
sf.SetMeasurableCharacterRanges( 2, @ranges(0) )
print sf.GetMeasurableCharacterRangeCount()   ' 2
```

Microsoft Learn: [StringFormat::GetMeasurableCharacterRangeCount](https://learn.microsoft.com/en-us/windows/win32/api/gdiplusstringformat/nf-gdiplusstringformat-stringformat-getmeasurablecharacterrangecount)

## See also

- [sys/win/gdiplus](SysWin-GdiPlus)
- [CGpGraphics](CGpGraphics) for `DrawString`, `MeasureString` and `MeasureCharacterRanges`
- [GDI+ fonts](SysWin-GdiPlus-Fonts)
