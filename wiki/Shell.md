[Home](Home) › [Operating System Functions](Category-Operating-System-Functions) › **Shell**

# Shell

Runs a command through the system shell, waits, and returns its exit code or -1.

## Syntax

```freebasic
Declare Function Shell ( ByRef command As Const String ) As Long
```

## Parameters

- `command`

## Description

Program execution will be suspended until the command interpreter exits.

## Return Value

If the command could not be executed, `-1` is returned. Otherwise, the command is executed and its exit code is returned.

## Remarks

### Usage

`result = Shell( command )`

### Platform Differences

- Linux requires the *command* case matches the real name of the command. Windows, DOS and a default macOS volume are case insensitive. The program being shelled may be case sensitive for its command line parameters.
  Path separators in Linux and macOS are forward slashes / . Windows uses backward slashes \\ but it allows for forward slashes. DOS uses backward \\ slashes.  
  If an empty *command* string is passed, DOS will open an interactive command prompt. On Windows, an error may be returned.

### Differences from QB

- QB allowed SHELL on its own without a "command" argument which caused a default command shell to be started. Execution in the main program would suspend until exit from the command shell. The behaviour in FB is platform-dependent.

### See also

- [`Exec`](Exec)
- [`Run`](Run)

## Examples

```freebasic
'e.g. for windows:

Shell "dir c:*.*"

'e.g. for linux:

Shell "ls"
```

---

**Category:** [Operating System Functions](Category-Operating-System-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
