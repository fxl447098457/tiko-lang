[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **Exec**

# Exec

Runs a program by its path with arguments, waits, and returns its exit code or -1.

## Syntax

```freebasic
Declare Function Exec ( ByRef program As Const String, ByRef arguments As Const String ) As Long
```

## Parameters

- `program`
- `arguments`

## Description

Transfers control over to an external program. When the program exits, execution resumes immediately after the call to `Exec`.

## Return Value

The exit status of the program, or negative one (-1) if the program could not be executed.

## Remarks

### Usage

`result = Exec( program, arguments )`

### Platform Differences

- On Windows *program* is not searched for on the `PATH`: `Exec( "cmd.exe", "/c dir" )` returns -1. Give the full path -- for the command interpreter, `Environ( "COMSPEC" )`. On Linux and macOS a bare name is searched for on the `PATH`.
- Linux requires the *program* case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive. The program being executed may be case sensitive for its command line parameters.
  Path separators in Linux and macOS are forward slashes / . Windows uses backward slashes \\ but it allows for forward slashes . DOS uses backward \\ slashes.  
  Exit code is limited to 8 bits in DOS.

### Dialect Differences

- Not available in the *[-lang qb](Compiler-Option-Lang)* dialect unless referenced with the alias `__Exec`.

### Differences from QB

- New to FreeBASIC

### See also

- [`Chain`](Chain) transfer temporarily, without arguments
- [`Run`](Run) one-way transfer
- [`Command`](Command) pick arguments

## Examples

```freebasic
'A Windows based example but the same idea applies to Linux

Const exename = "NoSuchProgram.exe"

Const cmdline = "arg1 arg2 arg3"

Dim result As Long

result = Exec( exename, cmdline )

If result = -1 Then

    Print "Error running "; exename

Else

    Print "Exit code:"; result

End If
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
