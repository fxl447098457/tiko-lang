[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **FileExists**

# FileExists

Returns non-zero if the file exists, or 0 if it does not.

## Syntax

```freebasic
Declare Function FileExists ( ByVal filename As ZString Ptr ) As Long
```

## Parameters

- `filename`

## Description

`FileExists` tests for the existence of a file.  
 Internally, it may issue an Open() and a Close() function, which may have consequences - eg, any existing [`Lock`](Lock)(s) on the file may be released.  
 Depending on the exact requirements, alternative methods of checking for file existence may be to use the `Dir()` function (being careful of attributes and ensuring the path doesn't contain wildcards), or to try [`Open`](Open)ing the file and checking the return value for success.

## Return Value

Returns non-zero (`-1`) if the file exists, otherwise returns zero (`0`).

## Remarks

### Usage

```freebasic
#include "file.bi"

result = FileExists( filename )
```

*or*

```freebasic
#include "vbcompat.bi"

result = FileExists( filename )
```

### Platform Differences

- Linux requires the `filename` case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive.
  Path separators in Linux and macOS are forward slashes `/`. Windows uses backward slashes `\` but it allows for forward slashes. DOS uses backward `\` slashes.

### Differences from QB

- New to FreeBASIC

### See also

- [`Dir`](Dir)

## Examples

```freebasic
#include "vbcompat.bi"

Dim filename As String

Print "Enter a filename: "

Line Input filename

If FileExists( filename ) Then

  Print "File found: " & filename

Else

  Print "File not found: " & filename

End If
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
