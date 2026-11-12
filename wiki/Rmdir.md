[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **RmDir**

# RmDir

Removes an empty folder; returns 0 on success or -1 on failure.

## Syntax

```freebasic
Declare Function RmDir ( ByRef folder As Const String ) As Long
```

## Parameters

- `folder`

## Description

Removes a folder from the file system. The function will fail if the folder is not empty.

## Return Value

Returns zero (0) on success, and negative one (-1) on failure.

## Remarks

### Usage

`result = RmDir( folder )`

### Platform Differences

- Linux requires the *folder* case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive.
  Path separators in Linux and macOS are forward slashes / . Windows uses backward slashes \\ but it allows for forward slashes . DOS uses backward \\ slashes.

### Differences from QB

- None

### See also

- [`Shell`](Shell)
- [`CurDir`](Curdir)
- [`ChDir`](Chdir)
- [`MkDir`](Mkdir)
- [`Kill`](Kill)

## Examples

```freebasic
Dim pathname As String = "foo\bar\baz"

Dim result As Integer = RmDir( pathname )

If 0 <> result Then Print "error: unable to remove folder " & pathname & " in the current path."
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
