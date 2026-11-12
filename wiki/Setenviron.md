[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **SetEnviron**

# SetEnviron

Sets an environment variable from "NAME=value" text; returns 0 on success.

## Syntax

```freebasic
Declare Function SetEnviron ( ByRef varexpression As String ) As Long
```

## Parameters

- `varexpression`

## Description

Modifies system environment variables. There are several variables available for editing other than the default ones on your system. An example of this would be fbgfx, where you can choose the form of graphics driver the FreeBASIC graphics library will use.

## Return Value

Return zero (0) if successful, non-zero otherwise.

## Remarks

### Usage

`result = SetEnviron( varexpression )`

### Platform Differences

- In Linux and macOS, `varexpression` must be permanent (a literal, a variable declared in the main code or a static variable declared in a procedure), because the system does not memorize the string but only a pointer to its data characters.

### Differences from QB

- In QB, `SetEnviron` was called `Environ`.

### See also

- [`Environ`](Environ)
- [`Shell`](Shell)

## Examples

```freebasic
'e.g. to set the system variable "path" to "c:":

Shell "set path" 'shows the value of path

SetEnviron "path=c:"

Shell "set path" 'shows the new value of path
```

```freebasic
'' WINDOWS ONLY EXAMPLE! - We just set the graphics method to use

  '' GDI rather than DirectX (or Direct2D added on new systems).

  '' You may note a difference in FPS.

SetEnviron("fbgfx=GDI")

  '' Desktop width/height

Dim As Long ScrW, ScrH, BPP

ScreenInfo ScrW, ScrH, BPP

  '' Create a screen at the half width/height of your monitor.

  '' Normally this would be slow, but GDI is fairly fast for this kind

  '' of thing.

ScreenRes ScrW/2, ScrH/2, BPP

  '' Start our timer/

Dim As Double T = Timer

  '' Lock our page

ScreenLock

Do

    '' Print time since last frame

  Locate 1, 1

  Print "FPS: " & 1 / ( Timer - T )

  T = Timer

    '' Flip our screen

  ScreenUnlock

  ScreenLock

    '' Commit a graphical change to our screen.

  Cls

Loop Until Len(Inkey)

  '' unlock our page.

ScreenUnlock
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
