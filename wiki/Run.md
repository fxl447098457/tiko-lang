[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **Run**

# Run

Hands control to another program and ends this one; returns -1 if it cannot start.

## Syntax

```freebasic
Declare Function Run ( ByRef program As Const String, ByRef arguments As Const String = "" ) As Long
```

## Parameters

- `program`
- `arguments`

## Description

Transfers control over to an external program. When the program exits, execution will return to the system.

## Return Value

Returns negative one (`-1`) if the program could not be executed.

## Remarks

### Usage

`result = Run( program [, arguments ] )`

### Platform Differences

- Linux requires the *program* case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive. The program being run may be case sensitive for its command line parameters.
  Path separators in Linux and macOS are forward slashes ("`/`"). Windows uses backward slashes ("`\`") although some versions of Windows allow forward slashes. DOS uses backward slashes.

### Differences from QB

- `Run` needs the full executable name, including extension (`.exe`) on platforms that have one (Win32, DOS).
- Returning an error code is new to FreeBASIC.

### See also

- [`Exec`](Exec) transfer temporarily, with arguments
- [`Chain`](Chain) transfer temporarily, without arguments
- [`Command`](Command) pick arguments

## Examples

```freebasic
'' Attempt to transfer control to "program.exe" in the current directory.

Dim result As Integer = Run("program.exe")

'' at this point, "program.exe" has failed to execute, and

'' result will be set to -1.
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
