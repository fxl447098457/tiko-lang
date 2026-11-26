[Home](Home) › [Procedures](Category-Procedures) › **Sub**

# Sub

Defines a procedure

## Syntax

```freebasic
[Public|Private] Sub identifier [cdecl|pascal|stdcall] [Overload] [Alias external_identifier] [( [parameter_list] )] [Static] [Export]
statements
...
[Return]
...
End Sub
[Public] Sub identifier [cdecl|pascal|stdcall] [Overload] [Alias external_identifier] [()] [Constructor|Destructor] [Static]
statements
```

## Parameters

- `identifier`
- `external_identifier`
- `parameter_list`
- `parameter`
- `identifier`
- `type`
- `default_value`
- `default_value`
- `statements`

## Description

A subroutine is a block of code which may be called at any time from a program. This code may need to be executed multiple times, and subroutines provide an invaluable means to simplify code by replacing these blocks of code with a single subroutine call. A subroutine also serves to allow a user to extend the FreeBASIC language to provide custom commands. Many of the functions built into FreeBASIC are merely subroutines part of a "runtime library" linked to by default.

 The `Sub` keyword marks the beginning of a subroutine, and its end is marked by `End Sub`. The "name" parameter is the name by which this subroutine is called. For instance, if the declaration is "`Sub...End Sub`", the user can execute the code in between "`Sub foo`" and "`End Sub`" by using "`foo`" as a statement. This code is executed separate from the code which calls the subroutine, so any variable names, unless they are shared, are not available to the subroutine. Values can, however, be passed using parameters.

 Parameters are the arguments passed to any statement. For instance, if a user executes a statement as "`Print 4`", the value "4" is passed to the function "[`Print`](Print)". Parameters that need to be passed to a subroutine are supplied by one or more parameter arguments in the "`Sub`" keyword. Creating a subroutine with "`Sub mysub(foo, bar)...End Sub`", allows the code in between "`Sub`" and "`End Sub`" to refer to the first passed argument as "foo" and the second passed argument as "bar". If a parameter is given a default value, that parameter is optional.  
 Array parameters are specified by following an identifier with an empty parenthesis. Note that array parameters are always [`ByRef`](Byref-Parameters): writing [`ByRef`](Byref-Parameters) on one is allowed but changes nothing, and [`ByVal`](Byval) is not allowed. When calling a subroutine with an array argument the parenthesis must be supplied there too.

 In the default dialect *[-lang fb](Compiler-Option-Lang)*, parameters must also have a supplied type, in the form "`parameter as type`". Type suffixes are not allowed.

 In the *[-lang qb](Compiler-Option-Lang)* and *[-lang fblite](Compiler-Option-Lang)* dialects only, it will be given a default type if the type is not explicitly given either by name or by type suffix. The default type is [`Single`](Single) in the *[-lang qb](Compiler-Option-Lang)* dialect and [`Integer`](Integer) in the *[-lang fblite](Compiler-Option-Lang)* dialect.

 A subroutine can also specify how parameters are passed, either as "[`ByRef`](Byref-Parameters)" or "[`ByVal`](Byval)", as shown in the syntax definition. If a parameter is "[`ByRef`](Byref-Parameters)", the parameter name literally becomes a reference to the original variable passed to the subroutine. Any changes made to that variable will be reflected outside of the subroutine. If a parameter is passed "[`ByVal`](Byval)", however, the value of any passed variable is copied into a new variable, and any changes made to it will not affect the original.

 The [`Static`](procedures-Static) specifier indicates that the values of all local variables defined in the sub should be preserved between calls. To specify individual local variables as static see the [`Static`](procedures-Static) keyword.  
 To access duplicated symbols defined as global outside the subroutine body, add one or preferably two dot(s) as prefix: `.SomeSymbol` or preferably `..SomeSymbol` (or only `..SomeSymbol` if inside a [With..End With](With) block).

 Sub is the same as [`Function`](procedures-Function), except it does not allow a value to be returned.

 When calling a subroutine, parentheses after the subroutine name (surrounding the argument list if any) are optional.

 The second syntax defines either a constructor or destructor using the [`Constructor`](Constructor-Module) and [`Destructor`](Destructor-Module) keywords, respectively. Constructor subroutines are executed before the first line of code in the module, while destructors execute on module exit. Note the public access specifier and empty parameter list for both constructors and destructors.

 **Warning for 64-bit compiler only:** See the Identifier Rules page for the choice of user procedure identifier names (and specially the 'Platform Differences' paragraph).

## Remarks

### Dialect Differences

- The *[-lang qb](Compiler-Option-Lang)* and *[-lang fblite](Compiler-Option-Lang)* dialects keep the QB convention: parameters are [`ByRef`](Byref-Parameters) by default.
  In the *[-lang fb](Compiler-Option-Lang)* dialect, numeric parameters are passed [`ByVal`](Byval) by default. [`String`](String)s and UDTs are passed [`ByRef`](Byref-Parameters) by default.

### Differences from QB

- Public and Private access specifiers are new to FreeBASIC.
- Constructor subroutines are new to FreeBASIC.

### See also

- [`Declare`](Declare)
- [`Function`](procedures-Function)
- [`Exit`](Exit)
- [`Public`](Public)
- [`Private`](Private)
- [`Static`](procedures-Static)

## Examples

```freebasic
'' Example of writing colored text using a sub:

Sub PrintColoredText( ByVal colour As Integer, ByRef text As String )

   Color colour

   Print text

End Sub

   PrintColoredText( 1, "blue" )        '' a few colors

   PrintColoredText( 2, "green" )

   PrintColoredText( 4, "red" )

   Print

   Dim i As Integer

   For i = 0 To 15                        '' all 16 colors

      PrintColoredText( i, ("color " & i) )

   Next i
```

```freebasic
' The following demonstrates optional parameters.

Sub TestSub(P As String = "Default")

    Print P

End Sub

TestSub "Testing:"

TestSub
```

---

**Category:** [Procedures](Category-Procedures)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
