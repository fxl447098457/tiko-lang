[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **ChDir**

# ChDir

Changes the current folder; returns 0 on success or -1 on failure.

## Syntax

```freebasic
Declare Function ChDir ( ByRef path As Const String ) As Long
```

## Parameters

- `path`

## Description

Changes the current drive and directory to that specified.

## Return Value

Returns zero (0) on success and negative one (-1) on failure.

## Remarks

### Usage

`result = ChDir( path )`

### Platform Differences

- Linux requires the *filename* case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive.
  Path separators in Linux and macOS are forward slashes / . Windows uses backward slashes \\ but it allows for forward slashes . DOS uses backward \\ slashes.

### Differences from QB

- In QB, the drive could not be specified.

### See also

- [`CurDir`](Curdir)
- [`MkDir`](Mkdir)
- [`RmDir`](Rmdir)

## Examples

```freebasic
Dim pathname As String = $"x:\folder"

Dim result As Long = ChDir(pathname)

If result <> 0 Then Print "error changing current directory to " & pathname & "."
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
