[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › **sys/win/richedit**

# sys/win/richedit

Creates rich edit controls and formats their text with messages and the Text Object Model.

A rich edit control is an edit box whose text can carry character and paragraph formatting,
tables, images and embedded objects, and that reads and writes Rich Text Format (RTF). The
module gives three ways to work with one:

- **[CRichEditCtx](CRichEditCtx)**, a class that creates the control in a [CWindow](CWindow) and
  wraps nearly every rich edit message, the document's files and RTF, and the control's
  `ITextDocument2` interface. Most programs need only this.
- **[RichEd](SysWin-RichEdit-Control)**, a namespace of functions that send the same messages
  to any rich edit control, given its handle.
- **The Text Object Model (TOM)**: `CTextRange2`, `CTextSelection2`, `CTextFont2`, `CTextPara2`,
  `CTextRow` and `CTextStory` wrap the TOM interfaces for ranges of text, the selection, fonts,
  paragraphs, table rows and stories.

**Ownership.** A `CRichEditCtx` object owns its control: its destructor destroys it, so the
object must live as long as the control is used. Each TOM class takes an interface pointer in its
constructor and **releases it in its destructor**: hand it a pointer you own, such as the result
of `CRichEditCtx.Range` or `CTextRange2.GetFont`, and do not release that pointer yourself. Pass
`true` as the second argument to have the class add a reference of its own instead.

**Character positions** count characters from 0 at the start of the text. A range runs from its
start to just before its end, so `Range( 0, 5 )` covers the first five characters.

`sys/win/richedit` imports `sys/win`, `sys/win/com`, `sys/win/gdiplus` and `sys/win/gui` itself;
a program that creates its window with `CWindow` imports `sys/win/gui` too.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/richedit"
using win, gui, richedit
```

## Example

A rich edit control that fills the window. The program sets its text, makes the first word bold
through the Text Object Model and zooms the view to 120 % with a `RichEdit` function.

```freebasic
#import "sys/win"
#import "sys/win/gui"
#import "sys/win/richedit"
using win, gui, richedit

const IDC_RICHEDIT = 101

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    dim pWindow as CWindow = "RichEditModule"
    dim hWin as HWND = pWindow.Create( NULL, "sys/win/richedit", @WndProc )
    pWindow.SetClientSize( 480, 260 )
    pWindow.Center()
    dim pRichEdit as CRichEditCtx = CRichEditCtx( @pWindow, IDC_RICHEDIT, "", 0, 0, 480, 260 )
    pWindow.AnchorControl( IDC_RICHEDIT, ANCHOR_HEIGHT_WIDTH )
    pRichEdit.SetText( "Hello, rich text. The first word is bold." )
    ' the Text Object Model: the range and its font are released by their destructors
    dim range as CTextRange2 = CTextRange2( pRichEdit.Range( 0, 5 ) )
    dim font as CTextFont2 = CTextFont2( range.GetFont() )
    font.SetBold( tomTrue )
    ' a RichEdit function on the control's handle
    RichEd.SetZoom( pRichEdit.hRichEdit, 120, 100 )
    pRichEdit.SetModify( 0 )
    SetFocus( pRichEdit.hRichEdit )
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_DESTROY
            PostQuitMessage( 0 )
            return 0
    end select
    return DefWindowProcW( hwnd, uMsg, wParam, lParam )
end function

end main()
```

A larger program, with files of each encoding, images, RTF and printing, is in the toolchain's
`examples/win64/RichEdit Examples/` folder.

## Pages

| Page | Covers |
| --- | --- |
| [CRichEditCtx](CRichEditCtx) | The control class: creating the control, finding the object from a handle, and the settings: options, edit styles, event mask, character and paragraph formats, text limit, modification flag, plain text. |
| [CRichEditCtx: editing](CRichEditCtx-Editing) | `CRichEditCtx` members for editing: the selection, inserting and replacing text, finding, lines and scrolling, undo and redo, zoom, margins, images and tables, streaming, word wrap, formatting text for a device. |
| [CRichEditCtx: document](CRichEditCtx-Document) | `CRichEditCtx` members for the document: the font, RTF, opening, appending and saving files, RTF resources, bold, italic, colour and size of the selection, and the `ITextDocument2` wrappers (stories, the selection, ranges, freezing, notifications). |
| [RichEdit](SysWin-RichEdit-Control) | The `RichEdit` namespace: the rich edit messages as functions that take the control's handle, plus loading RTF from a file or a resource. |
| [CTextRange2](CTextRange2) | A range of text (`ITextRange2`): its text and limits, moving and extending it, finding text, its font and paragraph, copying and pasting. |
| [CTextSelection2](CTextSelection2) | The selection (`ITextSelection2`): everything a range does, plus moves by keyboard units and typing at the selection. |
| [CTextFont2](CTextFont2) | Character formatting (`ITextFont2`): name, size, colours, bold, italic, underline and the other effects. |
| [CTextPara2](CTextPara2) | Paragraph formatting (`ITextPara2`): alignment, indents, spacing, tab stops, lists. |
| [CTextRow](CTextRow) | Table rows (`ITextRow`): inserting rows and setting row and cell properties. |
| [CTextStory](CTextStory) | A story (`ITextStory`), one of the separate texts of a document: its text, type and ranges. |
| [CRichEditOleCallback](CRichEditOleCallback) | An `IRichEditOleCallback` for the control, so that images and objects can be pasted, dropped and inserted. |
| [Text Object Model interfaces](SysWin-RichEdit-TOM) | The TOM interfaces, their IIDs and the `tom*` constants the classes above use. |

## See also

- [Category: sys/win](Category-Sys-Win)
- [CWindow](CWindow) for the window the control lives in
