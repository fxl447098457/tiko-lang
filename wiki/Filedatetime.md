[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **FileDateTime**

# FileDateTime

Returns when a file was last modified, as a date serial.

## Syntax

```freebasic
Declare Function FileDateTime ( ByVal filename As ZString Ptr ) As Double
```

## Parameters

- `filename`

## Description

Returns the file's last modified date and time as Date Serial.

## Return Value

Returns a Date Serial.

## Remarks

### Usage

```freebasic
#include "file.bi"

result = FileDateTime( filename )
```

 *or*

```freebasic
#include "vbcompat.bi"

result = FileDateTime( filename )
```

### Platform Differences

- Linux requires the `filename` case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive.
  Path separators in Linux and macOS are forward slashes `/` . Windows uses backward slashes `\` but it allows forward slashes. DOS uses backward slashes `\`.

### Differences from QB

- New to FreeBASIC

## Examples

```freebasic
#include "vbcompat.bi"

Dim filename As String, d As Double

Print "Enter a filename: "

Line Input filename

If FileExists( filename ) Then

  Print "File last modified: ";

  d = FileDateTime( filename )

  Print Format( d, "yyyy-mm-dd hh:mm AM/PM" )

Else

  Print "File not found"

End If
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
