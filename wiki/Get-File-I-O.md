[Home](Home) › [File I/O Functions](Category-File-I-O-Functions) › **Get (File I/O)**

# Get (File I/O)

Reads a variable, string or array from a file as bytes, at a position or the current one.

## Syntax

```freebasic
Get #filenum As Long, [position As LongInt], ByRef data As Any [, [amount As UInteger] [, ByRef bytesread As UInteger] ]
Get #filenum As Long, [position As LongInt], data As String [, , ByRef bytesread As UInteger ]
Get #filenum As Long, [position As LongInt], data() As Any [, , ByRef bytesread As UInteger ]
```

## Parameters

- `filenum`
- `position`
- `position`
- `data`
- `data`
- `amount`
- `amount`
- `amount`
- `amount`
- `data`
- `amount`
- `bytesread`

## Description

Reads binary data from a file to a buffer variable

 `Get` can be used as a function, and will return `0` on success or an error code on failure.

 For files opened in [`Random`](Random) mode, the size in bytes of the data to read must match the specified record size.

 *Note:

- If a real \[w/z\]string variable is passed to `Get`, the `amount` parameter should be forbidden as it is when passing a string. Do not use. Otherwise, it is ignored (except for the '0' value).
 - If a dereferenced \[w/z\]string pointer is passed to `Get`, the `amount` parameter is not taken into account as it is when passing a dereferenced numeric pointer. Do not use. But instead of respecting the `amount` parameter, the pointed buffer must begin with at least as many non-zero elements as the number of elements to read.
 - For finer granularity, any \[w/z\]string variable can be safely passed to `Get` as a numeric buffer by providing the first numeric element (an indexed \[w/z\]string variable, or a dereferenced \[w/z\]string pointer then indexed) and the number of numeric elements to be processed.*

 **Note:**

**-** Using **`Get #`** is naturally dedicated to Binary/Random Access file mode.
 **-** It is also allowed in Input Access file mode, but this was never well tested and results may vary.

## Return Value

`Get()` returns a 32 bit [`Long`](Long): a zero (`0`) on success; non-zero on error.  
 Note: if [`EOF`](Eof) (end of file) is reached while reading, `Get` will return success. The amount of bytes actually read can be checked by passing a `bytesread` variable.

## Remarks

### Usage

```freebasic
Get #filenum, position, data [, [amount] [, bytesread ] ]

varres = Get (#filenum, position, data [, [amount] [, bytesread ] ] )
```

### Differences from QB

- `Get` in FB can read full arrays as in VB or, alternatively, read a multiple of the data size into the memory.
  `Get` can be used as a function in FB, to find the success/error code returned without having to use error handling procedures.  
  FB allows the `bytesread` parameter, to check how many bytes have been successfully read in.

### See also

- [`Get (Graphics)`](Get-Graphics) different usage of same keyword
- [`Put (File I/O)`](Put-File-I-O)
- [`Open`](Open)
- [`Close`](Close)
- [`Binary`](Binary)
- [`Random`](Random)
- [`FreeFile`](Freefile)

## Examples

```freebasic
Dim Shared f As Integer

Sub get_long()

    Dim buffer As Long ' Long variable

    ' Read a Long (4 bytes) from the file into buffer, using file number "f".

    Get #f, , buffer

    ' print out result

    Print buffer

    Print

End Sub

Sub get_array()

    Dim an_array(0 To 10-1) As Long ' array of Longs

    ' Read 10 Longs (10 * 4 = 40 bytes) from the file into an_array, using file number "f".

    Get #f, , an_array()

    ' print out result

    For Each value As Long In an_array

        Print value

    Next

    Print

End Sub

Sub get_mem

    Dim pmem As Long Ptr

    ' allocate memory for 5 Longs

    pmem = Allocate(5 * SizeOf(Long))

    ' Read 5 Longs (5 * 4 = 20 bytes) from the file into allocated memory

    Get #f, , *pmem, 5 ' Note pmem must be dereferenced (*pmem, or pmem[0])

    ' print out result using [] Pointer Indexing

    For i As Integer = 0 To 5-1

        Print pmem[i]

    Next

    Print

    ' free pointer memory to prevent memory leak

    Deallocate pmem

End Sub

' Find the first free file file number.

f = FreeFile

' Open the file "file.ext" for binary usage, using the file number "f".

Open "file.ext" For Binary As #f

  get_long()

  get_array()

  get_mem()

' Close the file.

Close #f
```

```freebasic
' Load a small text file to a string

Function LoadFile(ByRef filename As String) As String

    Dim h As Integer

    Dim txt As String

    h = FreeFile

    If Open( filename For Binary Access Read As #h ) <> 0 Then Return ""

    If LOF(h) > 0 Then

        txt = String(LOF(h), 0)

        If Get( #h, ,txt ) <> 0 Then txt = ""

    End If

    Close #h

    Return txt

End Function

Dim ExampleStr As String

ExampleStr = LoadFile("smallfile.txt")

Print ExampleStr
```

```freebasic
' 'THIS' can be used as argument for writing/filling all non-static data of an UDT instance to/from a file

Type UDT

    Dim As String * 32 s

    Dim As Double d

    Declare Sub Save(ByRef filename As String)

    Declare Sub Load(ByRef filename As String)

End Type

Sub UDT.Save(ByRef filename As String)

    Dim As Integer f

    f = FreeFile()

    Open filename For Binary As #f

    Put #f, , This  '' writes all non-static data of the UDT instance to the file

    Close #f

End Sub

Sub UDT.Load(ByRef filename As String)

    Dim As Integer f

    f = FreeFile()

    Open filename For Binary As #f

    Get #f, , This  '' fills all non-static data of the UDT instance from the file

    Close #f

End Sub

Dim As UDT u1

u1.s = "PI number"

u1.d = 3.14159

u1.Save("file.ext")

Dim As UDT u2

u2.Load("file.ext")

Print u2.s

Print u2.d
```

---

**Category:** [File I/O Functions](Category-File-I-O-Functions)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
