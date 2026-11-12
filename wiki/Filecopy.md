[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **FileCopy**

# FileCopy

Copies a file, overwriting the destination; returns 0 on success.

## Syntax

```freebasic
Declare Function FileCopy ( ByVal source As ZString Ptr, ByVal destination As ZString Ptr ) As Long
```

## Parameters

- `source`
- `destination`

## Description

Copies the contents of the source file into the destination file, overwriting the destination file if it already exists.  
 It is necessary to [`#include`](procedures-Include) either `"file.bi"` or `"vbcompat.bi"` in order to gain access to this function.

 The error code returned by `FileCopy` can be checked using [`Err`](Err) in the next line. The function version of `FileCopy` returns directly the error code as a 32 bit [`Long`](Long).

## Return Value

Returns `0` on success, or `1` if an error occurred.

## Remarks

### Usage

```freebasic
#include "file.bi"

FileCopy source, destination
```

 *or*

```freebasic
#include "file.bi"

result = FileCopy( source, destination )
```

### Platform Differences

- Linux requires the `filename` case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive.
  Path separators in Linux and macOS are forward slashes `/`. Windows uses backward slashes `\` but it allows forward slashes. DOS uses backward slashes `\`.

### Differences from QB

- New to FreeBASIC. Existed in Visual Basic.

### See also

## Examples

```freebasic
#include "file.bi"

FileCopy "source.txt", "destination.txt"
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
