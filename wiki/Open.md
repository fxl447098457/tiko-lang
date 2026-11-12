[Home](Home) › [File I/O Functions](Category-File-I-O-Functions) › **Open**

# Open

Opens a file on a file number for reading or writing text, bytes or records.

## Syntax

```freebasic
Open filename For Input [encoding_type] [lock_type] As [#]filenumber
Open filename For Output [encoding_type] [lock_type] As [#]filenumber
Open filename For Append [encoding_type] [lock_type] As [#]filenumber
Open filename For Binary [access_type] [lock_type] As [#]filenumber
Open filename For Random [access_type] [lock_type] As [#]filenumber [Len = record_length]
```

## Parameters

- `filename`
- `encoding_type`
- `access_type`
- `lock_type`
- `filenumber`
- `record_length`

## Description

Opens a disk file for reading and/or writing. The file number `file_num` is bound to the file on disk, for use in subsequent file operations, such as [`Input #`](Input) and [`Lock`](Lock). The next available file number can be retrieved with [`FreeFile`](Freefile).

 The [`Input`](Input-File-Mode), [`Output`](Output) and [`Append`](Append) file modes open disk files for sequential text I/O, useful for reading or writing plain text files:

The [`Input`](Input-File-Mode), [`Output`](Output) and [`Append`](Append) file modes also allow selection of a character encoding to be used when reading from or writing text to the disk file. ASCII or a Unicode encoding may be specified (see the description of the `encoding_type` parameter above).

 The [`Binary`](Binary) and [`Random`](Random) file modes open disk files for random-access reading or writing of arbitrary sized binary data:

By default, the [`Binary`](Binary) and [`Random`](Random) file modes allow both reading and writing operations on the opened disk file, but this can be changed by specifying an access type (see the description for the `access_type` parameter above). When opening an existing file in [`Binary`](Binary) or [`Random`](Random) file mode, and with the only `Write` access type specified, all data in the file are previously deleted at opening, before any other operation.

 For any file mode, access to the opened disk file can be restricted or granted to other threads or programs by specifying a lock type (see the description for the `lock_type` parameter above). If no lock type is specified, other threads of the current program can freely open the disk file (`Shared`), while other programs cannot (`Lock Read Write`). [`Lock`](Lock) and [`Unlock`](Unlock) can be used to temporarily restrict access to parts of a file.

 The error code returned by `Open` can be checked using [`Err`](Err) in the next line. The function version of `Open` returns directly the error code as a 32 bit [`Long`](Long).

## Return Value

In the first usage, `Open()` returns a 32 bit [`Long`](Long) value: zero (`0`) on success and a non-zero error code otherwise.

## Remarks

### Usage

`result = Open( filename[,] For {Input|Output|Append}[,] As filenumber )`*or*`result = Open( filename[,] For Binary[,] Access {Read|Write}[,] As filenumber )`*or*`result = Open( filename[,] For Random[,] Access {Read|Write}[,] As filenumber [[,] Len = record_length] )`*or*`Open filename For {Input|Output|Append} As filenumber`*or*`Open filename For Binary Access {Read|Write} As filenumber`*or*`Open filename For Random Access {Read|Write} As filenumber [Len = record_length]`

### Platform Differences

- Linux requires the `filename` case matches the real name of the file. Windows, DOS and a default macOS volume are case insensitive.
  Path separators in Linux and macOS are forward slashes `/`. Windows uses backward slashes `\` but it allows for forward slashes `/`. DOS uses backward slashes `\`.  
  On Windows, a file number used in a dynamic link library is not the same as an identical file number used in the main program. File numbers can not be passed or returned and then used between a DLL and an executable.  
  If you try to open a directory on Linux, the `Open` command will succeed.

### Differences from QB

- Using MS-DOS device names to open streams or hardware devices (`"LPT:"`, `"SCR:"`, etc.) is supported only in the *[-lang qb](Compiler-Option-Lang)* dialect; for other modes FreeBASIC's new composite keywords must be used: see [`Open Com`](Open-Com), [`Open Cons`](Open-Cons), [`Open Err`](Open-Err), [`Open Pipe`](Open-Pipe), [`Open Lpt`](Open-Lpt), [`Open Scrn`](Open-Scrn).
  `Open` can be called as a function that returns an error code.

### Dialect Differences

- The *[-lang qb](Compiler-Option-Lang)* dialect supports the old GW-BASIC-style syntax `OPEN mode_string, #filenumber, filename [length]` with mode_string being `"I"` for input, `"O"` for output, `"A"` for append, `"R"` for random, `"B"` for binary.

### See also

- [`Err`](Err) (and a list of error codes)
  [`Close`](Close)  
  [`FreeFile`](Freefile)  
  [`Open Cons`](Open-Cons), [`Open Err`](Open-Err), [`Open Pipe`](Open-Pipe), [`Open Lpt`](Open-Lpt), [`Open Com`](Open-Com), [`Open Scrn`](Open-Scrn)

## Examples

```freebasic
' Create a string and fill it.

Dim buffer As String, f As Integer

buffer = "Hello World within a file."

' Find the first free file number.

f = FreeFile

' Open the file "file.ext" for binary usage, using the file number "f".

Open "file.ext" For Binary As #f

If Err>0 Then Print "Error opening the file":End

' Place our string inside the file, using number "f".

Put #f, , buffer

' Close all open files.

Close

' End the program. (Check the file "file.ext" upon running to see the output.)

End
```

```freebasic
'OPEN A COM PORT

Open Com "COM1:9600,N,8,1" As #1

If Err>0 Then Print "The port could not be opened."

'COM1, 9600 BAUD, NO PARITY BIT, EIGHT DATA BITS, ONE STOP BIT
```

```freebasic
'function version of OPEN

If Open("file.ext" For Binary Access Read As #1) = 0 Then

    Print "Successfully opened file"

    '' ...

    Close #1

Else

    Print "Error opening file"

End If
```

---

**Category:** [File I/O Functions](Category-File-I-O-Functions)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
