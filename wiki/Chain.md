[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **Chain**

# Chain

Runs a program without arguments, waits, and returns its exit code or -1.

## Syntax

```freebasic
Declare Function Chain ( ByRef program As Const String ) As Long
```

## Parameters

- `program`

## Description

Transfers control over to an external program. When the program exits, execution resumes immediately after the call to `Chain`.

## Return Value

Returns the external program's exit code if executed successfully, or negative one (-1) otherwise.

## Remarks

### Usage

`result = Chain( program )`

### Platform Differences

- Linux requires the `program` name case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive. The program chained may be case sensitive for its command line parameters.
  Path separators in Linux and macOS are forward slashes / . Windows uses backward slashes \\ but it allows for forward slashes . DOS uses backward \\ slashes.  
  Exit code is limited to 8 bits in DOS.

### Differences from QB

- [`Common`](Common) does not allow to keep the values of certain variables when chaining programs with `Chain`.

### See also

- [`Exec`](Exec) transfer temporarily, with arguments
- [`Run`](Run) one-way transfer
- [`Command`](Command) pick arguments

## Examples

```freebasic
#ifdef __FB_LINUX__

    Dim As String program = "./program"

#else

    Dim As String program = "program.exe"

#endif

Print "Running " & program & "..."

If (Chain(program) <> 0) Then

    Print program & " not found!"

End If
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
