[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/gui](SysWin-Gui) › **Animate**

# Animate

Opens, plays, stops and closes silent AVI clips in an animation control.

An animation control plays a short silent video clip, the kind shown while a file is copied or
a search runs. The clip must be an AVI file, uncompressed or RLE-compressed, with no sound; it
comes from a file or from an `AVI` resource of a module. Create the control with
`CWindow.AddControl( "Animate", ... )`, which gives it the `ACS_TRANSPARENT` style, or with
[PropSheet.Create](SysWin-Gui-PropSheet#create). Every function here takes the control's handle
first and is written with the namespace: `Animate.Play( hAnimate, 0, -1, -1 )`.

The control plays on a thread of its own, so the program carries on while it runs. Frames are
numbered from 0, and only the first 65536 can be addressed. Without the `ACS_CENTER` style the
control resizes itself to the clip when it opens one; with it, the clip is centred in the
control. `ACS_AUTOPLAY` starts each clip as soon as it is opened.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui
```

## Example

A window that plays `clock.avi`, from the program's folder, over and over, with a button that
stops and restarts it.

```freebasic
#import "sys/win"
#import "sys/win/gui"
using win, gui

const IDC_ANIM = 101
const IDC_TOGGLE = 102

declare function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT

function main() as long
    SetProcessDpiAwareness( PROCESS_SYSTEM_DPI_AWARE )
    EnableVisualStyles()
    dim pWindow as CWindow = "AnimateDemo"
    dim hWin as HWND = pWindow.Create( NULL, "Animation", @WndProc )
    pWindow.SetClientSize( 300, 200 )
    pWindow.Center()
    dim hAnim as HWND = pWindow.AddControl( "Animate", hWin, IDC_ANIM, "", 20, 20, 260, 120, _
                                            WS_VISIBLE or ACS_CENTER or ACS_TRANSPARENT )
    pWindow.AddControl( "Button", hWin, IDC_TOGGLE, "&Stop", 110, 155, 80, 28 )
    if Animate.OpenClip( hAnim, "clock.avi" ) then
        Animate.Play( hAnim, 0, -1, -1 )
    else
        SetWindowText( hWin, "clock.avi could not be opened" )
    end if
    return pWindow.DoEvents( SW_NORMAL )
end function

function WndProc( byval hwnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM ) as LRESULT
    select case uMsg
        case WM_COMMAND
            if CBCTL( wParam, lParam ) = IDC_TOGGLE andalso CBCTLMSG( wParam, lParam ) = BN_CLICKED then
                dim hAnim as HWND = GetDlgItem( hwnd, IDC_ANIM )
                if Animate.IsPlaying( hAnim ) then
                    Animate.Stop( hAnim )
                    SetWindowText( cast( HWND, lParam ), "&Play" )
                else
                    Animate.Play( hAnim, 0, -1, -1 )
                    SetWindowText( cast( HWND, lParam ), "&Stop" )
                end if
            end if
            return 0
        case WM_DESTROY
            Animate.CloseClip( GetDlgItem( hwnd, IDC_ANIM ) )
            PostQuitMessage( 0 )
            return 0
    end select
    return DefWindowProcW( hwnd, uMsg, wParam, lParam )
end function

end main()
```

## Functions

| Function | Does |
| --- | --- |
| [OpenClip](#openclip) | Opens a clip from a file or from the program's resources. |
| [OpenEx](#openex) | Opens a clip from the resources of a given module. |
| [Play](#play) | Plays a run of frames, a number of times or for ever. |
| [Stop](#stop) | Stops playing. |
| [IsPlaying](#isplaying) | Says whether a clip is playing. |
| [SeekFrame](#seekframe) | Shows one frame. |
| [CloseClip](#closeclip) | Closes the clip. |

## Reference

### OpenClip

```freebasic
function OpenClip( byval hAnimate as HWND, byval pwzName as wstring ptr ) as boolean
```

Opens a clip and shows its first frame (or starts it, with `ACS_AUTOPLAY`). `pwzName` is the
path of an AVI file, or the name of an `AVI` resource of the module that created the control;
for a numbered resource pass `cast( wstring ptr, id )`. A clip already open is closed first.

**Returns** `true` on success; `false` when the file or resource is missing or is not a clip the
control can play.

**Example**

```freebasic
if Animate.OpenClip( hCtrl, "search.avi" ) = false then print "cannot open search.avi"
```

Microsoft Learn: [ACM_OPEN](https://learn.microsoft.com/en-us/windows/win32/controls/acm-open)

### OpenEx

```freebasic
function OpenEx( byval hAnimate as HWND, byval hInstance as HINSTANCE, byval pwzName as wstring ptr ) as boolean
```

Opens a clip from the resources of the module `hInstance`, for example a DLL loaded with
`LoadLibraryW`. `pwzName` is the resource's name, or `cast( wstring ptr, id )`.

**Returns** `true` on success.

**Example**

```freebasic
dim hRes as HMODULE = LoadLibraryW( "myclips.dll" )
if hRes then Animate.OpenEx( hCtrl, hRes, cast( wstring ptr, 101 ) )
```

Microsoft Learn: [ACM_OPEN](https://learn.microsoft.com/en-us/windows/win32/controls/acm-open)

### Play

```freebasic
function Play( byval hAnimate as HWND, byval from as UINT, byval _to as UINT, byval rep as UINT ) as boolean
```

Plays frames `from` to `_to` of the open clip, `rep` times, in the background.

| Parameter | Meaning |
| --- | --- |
| `from` | The first frame, from 0. |
| `_to` | The last frame; -1 is the end of the clip. |
| `rep` | How many times to play it; -1 is for ever, until [Stop](#stop). |

**Returns** `true` on success; `false` when no clip is open.

**Example**

```freebasic
Animate.Play( hCtrl, 0, -1, 1 )   ' once through
```

Microsoft Learn: [ACM_PLAY](https://learn.microsoft.com/en-us/windows/win32/controls/acm-play)

### Stop

```freebasic
function Stop( byval hAnimate as HWND ) as boolean
```

Stops the clip; the frame on show stays.

**Returns** `true` on success.

**Example**

```freebasic
Animate.Stop( hCtrl )
```

Microsoft Learn: [ACM_STOP](https://learn.microsoft.com/en-us/windows/win32/controls/acm-stop)

### IsPlaying

```freebasic
function IsPlaying( byval hAnimate as HWND ) as boolean
```

It needs version 6 of the common controls: call `EnableVisualStyles()` at start-up or give the
program a manifest. Without it the control does not know the request and the answer is always
`false`.

**Returns** `true` while a clip is playing, `false` when it is stopped or none is open.

**Example**

```freebasic
if Animate.IsPlaying( hCtrl ) then Animate.Stop( hCtrl )
```

Microsoft Learn: [ACM_ISPLAYING](https://learn.microsoft.com/en-us/windows/win32/controls/acm-isplaying)

### SeekFrame

```freebasic
function SeekFrame( byval hAnimate as HWND, byval frame as UINT ) as boolean
```

Shows frame `frame` of the open clip and stays there: [Play](#play) from `frame` to `frame`,
once.

**Returns** `true` on success; `false` when no clip is open.

**Example**

```freebasic
Animate.SeekFrame( hCtrl, 0 )   ' back to the first picture
```

Microsoft Learn: [Animate_Seek](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-animate_seek)

### CloseClip

```freebasic
function CloseClip( byval hAnimate as HWND ) as boolean
```

Closes the open clip and clears the control.

**Example**

```freebasic
Animate.CloseClip( hCtrl )
```

Microsoft Learn: [Animate_Close](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-animate_close)

## See also

- [sys/win/gui](SysWin-Gui)
- [PropSheet](SysWin-Gui-PropSheet) for `PropSheet.Create`, which creates an animation control
- [CWindow](CWindow) for `AddControl( "Animate", ... )`
- [Resources](SysWin-Resources)
- [ProgBar](SysWin-Gui-ProgBar)
