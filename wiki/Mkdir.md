[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **MkDir**

# MkDir

Creates one folder, whose parent must already exist; returns 0 on success.

## Syntax

```freebasic
Declare Function MkDir ( ByRef folder As Const String ) As Long
```

## Parameters

- `folder`

## Description

Creates a folder/directoy on the local file system.

 If `folder` is not a simple folder/directory name, but a path to a sub-folder/sub-directory, the parent folder(s)/directory(s) specified in the path must already exist.  
 (only one folder/directory can be created for each request)

## Return Value

Returns zero (0) on success, and negative one (-1) on failure.

## Remarks

### Usage

`result = MkDir( folder )`

### Platform Differences

- Linux requires the *filename* case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive.
  Path separators in Linux and macOS are forward slashes / . Windows uses backward slashes \\ but it allows for forward slashes . DOS uses backward \\ slashes.

### Differences from QB

- None

### See also

- [`Shell`](Shell)
- [`CurDir`](Curdir)
- [`ChDir`](Chdir)
- [`RmDir`](Rmdir)

## Examples

```freebasic
Dim pathname As String = "foo\bar\baz"

Dim result As Long = MkDir( pathname )

If 0 <> result Then Print "error: unable to create folder " & pathname & " in the current path."
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
