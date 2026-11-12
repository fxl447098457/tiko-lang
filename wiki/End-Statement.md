[Home](Home) › [Miscellaneous Keywords](Category-Miscellaneous-Keywords) › **End (Statement)**

# End (Statement)

Control flow statement to end the program.

## Syntax

```freebasic
Declare Sub End ( ByVal retval As Long = 0 )
```

## Parameters

- `retval`

## Description

Used to exit the program, and return to the operating system. An optional integer return value can be specified to indicate an error code to the system. If no return value is given, a value of `0` is automatically returned at the end of the program.

 Usage of this statement does not cleanly close scope. Local variables will not have their destructors called automatically, because FreeBASIC does not do stack unwinding. Only the destructors of global variables will be called in this case.

 For this reason, it is discouraged to use `End` simply to mark the end of a program; the program will come to an end automatically, and in a cleaner fashion, when the last line of module-level code has executed.

## Remarks

### Usage

`End [ retval ]`

### Platform Differences

- In Linux and macOS, the `retval` parameter is a [`Byte`](Byte).

### Differences from QB

- The END statement supports specifying a custom return value to be returned to the operating system.

### See also

- [`End (Block)`](End-Block)
- [`Return (From Procedure)`](Return-From-Procedure)
- [`Return (From Gosub)`](Return-From-Gosub)
- [`System`](System)

## Examples

```freebasic
'' This program requests a string from the user, and returns an error

'' code to the OS if the string was empty

Function main() As Integer

    '' assign input to text string

    Dim As String text

    Line Input "Enter some text ( try ""abc"" ): " , text

    '' If string is empty, print an error message and

    '' return error code 1 (failure)

    If( text = "" ) Then

        Print "ERROR: string was empty"

        Return 1

    End If

    '' string is not empty, so print the string and

    '' return error code 0 (success)

    Print "You entered: " & text

    Return 0

End Function

'' call main() and return the error code to the OS

End main()
```

---

**Category:** [Miscellaneous Keywords](Category-Miscellaneous-Keywords)  
**Kind:** statement

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
