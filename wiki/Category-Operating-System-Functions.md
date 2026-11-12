[Home](Home) › [All Categories](Categories) › **Operating System Functions**

# Operating System Functions

The built-in statements and functions below work in every program. The [`std/os`](Category-OS) module adds `Args( )` that keeps empty arguments, `GetEnv` that tells an unset variable from an empty one, host facts such as `CpuCount( )`, and Ctrl-C handling; [`std/process`](Category-Process) runs other programs with their arguments passed exactly, no shell in between, and pipes to their input and output.

<!-- finder:start -->

Grouped by task. [Operating system](Functions-System) lists them beside the rest of the area.

## Read the command line

| Function | What it does | From |
|---|---|---|
| [Command](Command) | Returns command-line argument n, the program's name for 0, or all of them if omitted. | built-in |
| [Args](Category-OS#arguments) | Returns every command-line argument as Unicode text, the program first, empty ones kept. | `std/os` |

## Run another program

| Function | What it does | From |
|---|---|---|
| [Shell](Shell) | Runs a command through the system shell, waits, and returns its exit code or -1. | built-in |
| [Exec](Exec) | Runs a program by its path with arguments, waits, and returns its exit code or -1. | built-in |
| [Chain](Chain) | Runs a program without arguments, waits, and returns its exit code or -1. | built-in |
| [Run](Run) | Hands control to another program and ends this one; returns -1 if it cannot start. | built-in |
| [Command](Category-Process#commands) (std/process) | Holds a program and its arguments, passed exactly as given with no shell in between. | `std/process` |
| [Run](Category-Process#running-to-completion) (std/process) | Runs a Command with this program's console, waits, and returns its exit status. | `std/process` |
| [Capture](Category-Process#running-to-completion) | Runs a Command, waits, and returns its exit status and all it wrote to stdout and stderr. | `std/process` |
| [Shell](Category-Process#running-to-completion) (std/process) | Runs a command line through cmd.exe or /bin/sh, waits, and returns its exit status. | `std/process` |

## Set up a program's arguments, folder and pipes

| Function | What it does | From |
|---|---|---|
| [Command.Arg](Category-Process#commands) | Adds one argument and returns the Command, so calls chain. | `std/process` |
| [Command.Args](Category-Process#commands) | Adds every string in an Array as an argument. | `std/process` |
| [Command.Cwd](Category-Process#commands) | Sets the folder the program starts in. | `std/process` |
| [Command.Env](Category-Process#commands) | Sets one environment variable for the program only. | `std/process` |
| [Command.EnvRemove](Category-Process#commands) | Removes one environment variable for the program only. | `std/process` |
| [Command.EnvClear](Category-Process#commands) | Starts the program with an empty environment, which Env calls then add to. | `std/process` |
| [Command.StdinFrom / StdoutTo / StderrTo](Category-Process#commands) | Connects the program's stdin, stdout or stderr to this console, to nothing, or to a pipe. | `std/process` |
| [Command.StderrToStdout](Category-Process#commands) | Sends the program's stderr wherever its stdout goes. | `std/process` |
| [Command.NewProcessGroup](Category-Process#commands) | Starts the program in its own process group, so Windows can send it Ctrl-Break. | `std/process` |
| [Command.HideWindow](Category-Process#commands) | Starts a console program on Windows without opening a console window. | `std/process` |
| [Command.ToString](Category-Process#commands) | Returns the command line quoted as the system will see it, for logs. | `std/process` |
| [Stdio](Category-Process#commands) | Names where a stream goes: STDIO_INHERIT, STDIO_NULL or STDIO_PIPE. | `std/process` |

## Talk to a program while it runs

| Function | What it does | From |
|---|---|---|
| [Child](Category-Process#a-running-child) | Holds one running program; destroying it leaves the program running. | `std/process` |
| [Child.Spawn](Category-Process#a-running-child) | Starts the program a Command describes, or returns why it could not. | `std/process` |
| [Child.Id](Category-Process#a-running-child) | Returns the running program's process id. | `std/process` |
| [Child.Stdin / Stdout / Stderr](Category-Process#a-running-child) | Returns the pipe to the program's stdin, stdout or stderr when the Command asked for one. | `std/process` |
| [Child.Wait](Category-Process#a-running-child) | Closes the program's stdin, waits for it to end, and returns its exit status. | `std/process` |
| [Child.WaitTimeout](Category-Process#a-running-child) | Waits up to a number of milliseconds; returns the exit status, or none if still running. | `std/process` |
| [Child.TryWait](Category-Process#a-running-child) | Returns the exit status if the program has ended, or none if it is still running. | `std/process` |
| [Child.Kill](Category-Process#a-running-child) | Ends the program at once. | `std/process` |
| [Child.Terminate](Category-Process#a-running-child) | Asks the program to stop; on Windows it ends it at once, as Kill does. | `std/process` |
| [PipeStream](Category-Process#a-running-child) | Holds one end of a pipe to a program, read and written like any other stream. | `std/process` |

## Read a program's exit code and output

| Function | What it does | From |
|---|---|---|
| [ExitStatus](Category-Process#running-to-completion) | Holds how a program ended: its exit code and, on Linux and macOS, the ending signal. | `std/process` |
| [ExitStatus.Code](Category-Process#running-to-completion) | Returns the program's exit code, or -1 on Linux and macOS when a signal ended it. | `std/process` |
| [ExitStatus.Success](Category-Process#running-to-completion) | Returns true if the exit code is 0. | `std/process` |
| [ExitStatus.Signal](Category-Process#running-to-completion) | Returns the signal that ended the program on Linux and macOS, or 0. | `std/process` |
| [ProcessOutput](Category-Process#running-to-completion) | Holds a finished program's exit status and the bytes it wrote to stdout and stderr. | `std/process` |
| [ProcessOutput.StdoutText / StderrText](Category-Process#running-to-completion) | Returns what the program wrote as UTF-8 text, with U+FFFD for any bad bytes. | `std/process` |

## Read and set environment variables

| Function | What it does | From |
|---|---|---|
| [Environ](Environ) | Returns the value of an environment variable, or an empty string if it is not set. | built-in |
| [SetEnviron](Setenviron) | Sets an environment variable from "NAME=value" text; returns 0 on success. | built-in |
| [GetEnv](Category-OS#environment) | Returns an environment variable's value, or an empty Optional when it is not set. | `std/os` |
| [SetEnv](Category-OS#environment) | Sets an environment variable for this program and the programs it starts. | `std/os` |
| [UnsetEnv](Category-OS#environment) | Removes an environment variable; removing one that is not set succeeds. | `std/os` |
| [Environment](Category-OS#environment) | Returns every environment variable as a map of names to values, sorted by name. | `std/os` |
| [ExpandEnv](Category-OS#environment) | Replaces $NAME and ${NAME} in text, and %NAME% on Windows, with the variables' values. | `std/os` |

## Catch Ctrl-C and stop cleanly

| Function | What it does | From |
|---|---|---|
| [CatchInterrupt](Category-OS#ctrl-c-and-termination) | Turns Ctrl-C, Ctrl-Break and requests to stop into a flag, instead of ending the program. | `std/os` |
| [Interrupted](Category-OS#ctrl-c-and-termination) | Returns true once an interrupt has arrived; never waits. | `std/os` |
| [WaitInterrupt](Category-OS#ctrl-c-and-termination) | Waits for an interrupt and returns true, or false if the time runs out first. | `std/os` |
| [LastInterrupt](Category-OS#ctrl-c-and-termination) | Returns which kind of interrupt arrived, such as INT_CTRL_C, or INT_NONE. | `std/os` |
| [InterruptCount](Category-OS#ctrl-c-and-termination) | Returns how many interrupts have arrived since the last reset. | `std/os` |
| [ResetInterrupt](Category-OS#ctrl-c-and-termination) | Clears the interrupt flag and the count. | `std/os` |
| [ReleaseInterrupt](Category-OS#ctrl-c-and-termination) | Gives Ctrl-C and the other signals back to their default handling. | `std/os` |
| [InterruptKind](Category-OS#ctrl-c-and-termination) | Names the kinds of interrupt: Ctrl-C, Ctrl-Break, terminate and hang-up. | `std/os` |
| [InterruptContext](Category-OS#with-goroutines) | Returns a Context cancelled by the first interrupt, so goroutines stop on Ctrl-C. | `std/tasks` |

## Find out about the computer and this program

| Function | What it does | From |
|---|---|---|
| [OS_NAME](Category-OS#host-facts) | Holds "windows", "linux" or "macos", the system the program was built for. | `std/os` |
| [ARCH_NAME](Category-OS#host-facts) | Holds "x86_64", the processor the program was built for. | `std/os` |
| [OsVersion](Category-OS#host-facts) | Returns the Windows version number, or the kernel release on Linux and macOS. | `std/os` |
| [Hostname](Category-OS#host-facts) | Returns the computer's network name, or an error. | `std/os` |
| [UserName](Category-OS#host-facts) | Returns the name of the user running the program, or an error. | `std/os` |
| [ProcessId](Category-OS#host-facts) | Returns this program's process id. | `std/os` |
| [CurrentId](Category-Process#running-to-completion) | Returns this program's process id, the same number as ProcessId. | `std/process` |
| [CpuCount](Category-OS#host-facts) | Returns how many processors this program may run on, which can be fewer than exist. | `std/os` |
| [PageSize](Category-OS#host-facts) | Returns the memory page size in bytes. | `std/os` |
| [TotalMemory](Category-OS#host-facts) | Returns the computer's physical memory in bytes, or 0 if it cannot be found. | `std/os` |
| [IsTerminal](Category-OS#host-facts) | Returns true if stdin, stdout or stderr is an interactive terminal. | `std/os` |

## Find the program's folder and the current folder

| Function | What it does | From |
|---|---|---|
| [ExePath](Exepath) | Returns the folder that holds the running program. | built-in |
| [CurDir](Curdir) | Returns the current folder. | built-in |
| [ChDir](Chdir) | Changes the current folder; returns 0 on success or -1 on failure. | built-in |

## Make, remove and list folders

| Function | What it does | From |
|---|---|---|
| [MkDir](Mkdir) | Creates one folder, whose parent must already exist; returns 0 on success. | built-in |
| [RmDir](Rmdir) | Removes an empty folder; returns 0 on success or -1 on failure. | built-in |
| [Dir](Dir) | Returns the first name matching a pattern, then the next one on each later call. | built-in |

## Copy, rename and delete files

| Function | What it does | From |
|---|---|---|
| [FileCopy](Filecopy) | Copies a file, overwriting the destination; returns 0 on success. | `file.bi` |
| [Name](Name) | Renames or moves a file or folder; returns 0 on success. | built-in |
| [Kill](Kill) | Deletes a file; returns 0 on success or an error code. | built-in |

## Check whether a file exists, its size and date

| Function | What it does | From |
|---|---|---|
| [FileExists](Fileexists) | Returns non-zero if the file exists, or 0 if it does not. | `file.bi` |
| [FileLen](Filelen) | Returns the size of a named file in bytes. | `file.bi` |
| [FileDateTime](Filedatetime) | Returns when a file was last modified, as a date serial. | `file.bi` |

## Work with an open file number

| Function | What it does | From |
|---|---|---|
| [FileAttr](Fileattr) | Returns an open file number's mode, system handle or encoding. | `file.bi` |
| [FileFlush](Fileflush) | Writes buffered output for one or all open files to the system, or on to disk. | `file.bi` |
| [FileSetEof](Fileseteof) | Cuts or extends an open file so that it ends at the current position. | `file.bi` |

## End the program

| Function | What it does | From |
|---|---|---|
| [System](System) | Closes all open files and ends the program, with an optional exit code. | built-in |
| [ExitWith](Category-OS#exit) | Ends the program with an exit code, running module destructors and flushing files. | `std/os` |
| [Abort](Category-OS#exit) | Ends the program at once, with no cleanup at all. | `std/os` |

## Check free memory and redirection

| Function | What it does | From |
|---|---|---|
| [Fre](Fre) | Returns the amount of free physical memory, in bytes. | built-in |
| [IsRedirected](Isredirected) | Returns non-zero if standard output, or input if asked, is redirected to a file. | `fbio.bi` |

## Find out why a call failed

| Function | What it does | From |
|---|---|---|
| [OsError](Category-OS#errors) | Holds why a std/os call failed: a code, the system's error number and a message. | `std/os` |
| [OsErrorMessage](Category-OS#errors) | Returns the message text for a std/os error code, such as "invalid argument". | `std/os` |
| [ProcError](Category-Process#errors) | Holds why a program could not be started or waited for: a code, a number, a message. | `std/process` |
| [ProcErrorMessage](Category-Process#errors) | Returns the message text for a std/process error code, such as "program not found". | `std/process` |

## Also in this category

- [Operating System Functions](Operating-System-Functions)

<!-- finder:end -->

---

[Home](Home) · [Keyword Index](Keyword-Index)
