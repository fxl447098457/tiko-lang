[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **FileLen**

# FileLen

Returns the size of a named file in bytes.

## Syntax

```freebasic
Declare Function FileLen ( filename As String ) As LongInt
```

## Parameters

- `filename`

## Description

Returns the size in bytes of the file specified by *filename*.

## Remarks

### Usage

```freebasic
#include "file.bi"

result = FileLen(filename)
```

*or*

```freebasic
#include "vbcompat.bi"

result = FileLen(filename)
```

### Platform Differences

- Linux requires the *filename* case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive.
  Path separators in Linux and macOS are forward slashes / . Windows uses backward slashes \\ but it allows for forward slashes . DOS uses backward \\ slashes.

### Differences from QB

- New to FreeBASIC. Existed in Visual Basic.

### See also

- [`LOF`](Lof)

## Examples

```freebasic
#include "file.bi"

Dim length As LongInt

length = FileLen("file.txt")
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
