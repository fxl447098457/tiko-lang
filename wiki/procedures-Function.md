[Home](Home) › [Procedures](Category-Procedures) › **Function**

# Function

Defines a procedure returning a value

## Syntax

```freebasic
[Public|Private] Function identifier [cdecl|pascal|stdcall] [Overload] [Alias external_identifier] [([parameter_list])] [ ByRef ] As return_type [Static] [Export]
statements
...
{ {Return [return_value]}|{Function = return_value}|{identifier = return_value} }
...
End Function
```

## Parameters

- `identifier`
- `external_identifier`
- `parameter_list`
- `parameter[, parameter[, ...]] parameter`
- `identifier`
- `type`
- `default_value`
- `default_value`
- `return_type`
- `statements`
- `return_value`

## Description

A function defines a block of code which can be executed with a single statement (a function call), and provide a value back to the caller when finished (a return value). There are several reasons to use functions:

- Reduces redundancy in your program
- Enables reuse of code in many programs
- Improves readability of the program
- Improves maintainability of the program
- Makes it easy to extend your program

*Access Rights* : The [`Public`](Public) and [`Private`](Private) keywords specify public or private intra module-level access rights, respectively. If neither is given, the function defaults to public access ([`Public`](Public)).

 *Calling Convention* : Calling convention, or the order in which arguments are pushed and popped from the stack during function calls, is specified with the [`cdecl`](Cdecl), [`pascal`](Pascal) and [`stdcall`](Stdcall) keywords. If none is given, the function uses the standard convention by default ([`stdcall`](Stdcall)).

 *Passing Arguments* : Functions may receive one or more variables, or arguments, when called. These arguments are listed as `parameters` in the `parameter_list`. The [`ByRef`](Byref-Parameters) and [`ByVal`](Byval) keywords specify whether the argument will be passed by reference or by value, respectively. The argument's type is given by "`As type`" following the `parameter`. If a parameter in the declaration is given a default value, the parameter is optional. Array parameters are specified by following an identifier with an empty parenthesis. Note that array parameters are always [`ByRef`](Byref-Parameters): writing [`ByRef`](Byref-Parameters) on one is allowed but changes nothing, and [`ByVal`](Byval) is not allowed. When calling a function with an array argument the parenthesis must be supplied there too; see the examples.

 *Overloaded Functions* : An overloaded function may share the same name (`identifier`) as another with a different signature. The [`Overload`](Overload) keyword specifies that a function may be overloaded. A function must be defined - or declared - using the [`Overload`](Overload) keyword prior to any functions that overload them.

 *Returning values* : `return_type` specifies the `data type` returned by a function upon exit. If no data type is specified, then the function will return the default data type, which will be Integer unless set to another data type using `DefSng`, `DefDbl`, `DefStr`, etc. Functions can return values using three methods: the [`Return`](Return-From-Procedure) keyword followed by a value exits the function immediately, and returns that value to the caller. Functions can also return values by assigning the Function keyword or the function's `identifier` to the desired return value (but Function keyword or function's `identifier` does not allow to evaluate the current assigned value). The latter two methods do not cause the function to exit, however. [`Return`](Return-From-Procedure) keyword mixed with Function= keyword or function's `identifier`= or [`Exit Function`](Exit) keyword in a same function is unsupported when returning objects with constructors. Since functions return values, function calls evaluate to expressions. Thus, function calls can be made wherever an expression is expected, like in [Assignments](Operator-Assign) or [`If`](If-Then) statements. Functions can also return references by specifying `Byref As return_type`.
 **Warning:** Whatever the output branch used, the return value must be always defined, otherwise an unexpected behavior may occur.

 *Local Variable Preservation* : The [`Static`](procedures-Static) keyword specifies that a function's locally declared variables are preserved between function calls. Upon entering a function defined with [`Static`](procedures-Static), local variables have the same value as when the function was last called.

 *Global Variable Access*: To access duplicated symbols defined as global outside the function body, add one or preferably two dot(s) as prefix: `.SomeSymbol` or preferably `..SomeSymbol` (or only `..SomeSymbol` if inside a [With..End With](With) block).

 When calling a function, parentheses surrounding the argument list (if any) are required only for function calls in expressions. If there is no argument to pass, the parentheses become optional, but it is a common convention to place empty parentheses '()' after the function name, to signify a function call.

 **Warning for 64-bit compiler only:** See the Identifier Rules page for the choice of user procedure identifier names (and specially the 'Platform Differences' paragraph).

## Remarks

### Dialect Differences

- In the *[-lang fb](Compiler-Option-Lang)* dialect, `ByVal` is the default parameter passing convention for all built-in types except [`String`](String); String and user-defined [`Type`](Type-Udt)s are passed [`ByRef`](Byref-Parameters) by default.
  In the *[-lang qb](Compiler-Option-Lang)* and *[-lang fblite](Compiler-Option-Lang)* dialects, `ByRef` is the default parameter passing convention.  
  In the *[-lang qb](Compiler-Option-Lang)* dialect, the name of the function must be used in an assignment to specify the return value. Using `Function = ...`" to specify the return value may not be used.  
  In the *[-lang qb](Compiler-Option-Lang)* and *[-lang fblite](Compiler-Option-Lang)* dialects, [`Return`](Return-From-Procedure) may only be used to return a value when `Option Gosub` is off. In *[-lang qb](Compiler-Option-Lang)*, this must be done explicitly using the `Option Nogosub` statement.

### Differences from QB

- Parameters can be optional in FreeBASIC.
  In QBASIC, the return type could only specified with a suffix, not with `AS TYPE`, and only allowed functions to return a built-in type.  
  Return value can now be specified by a [`Return`](Return-From-Procedure) statement.  
  Function [`Overload`](Overload)ing is supported in FreeBASIC.  
  The return value of functions can be ignored in the calling code.

### See also

- [`Sub`](Sub)
- [`Exit`](Exit)
- [`Return (From Procedure)`](Return-From-Procedure)
- [`Declare`](Declare)
- [`Public`](Public)
- [`Private`](Private)

## Examples

```freebasic
'' This program demonstrates the declaration of a function

'' and returning a value using Return command

Declare Function ReturnTen () As Integer

Print ReturnTen () '' ReturnTen returns an integer by default.

Function ReturnTen() As Integer

    Return 10

End Function
```

```freebasic
'' This program demonstrates the declaration of a function

'' and returning a value using assignment to function name

Declare Function ReturnTen () As Integer

Print ReturnTen () '' ReturnTen returns an integer by default.

Function ReturnTen() As Integer

    ReturnTen = 10

End Function
```

```freebasic
'' This program demonstrates function overloading.

'' The overloaded functions must be FIRST.

Declare Function ReturnTen Overload (a As Single) As Integer

Declare Function ReturnTen Overload (a As String) As Integer

Declare Function ReturnTen (a As Integer) As Integer

Print ReturnTen (10.000!) '' ReturnTen will take a single and return an integer

Print ReturnTen (10)      '' ReturnTen will take an integer and return an integer

Print ReturnTen ("10")    '' ReturnTen will take a string and return an integer

Function ReturnTen Overload (a As Single) As Integer

    Return Int(a)

End Function

Function ReturnTen Overload (a As String) As Integer

    Return Val(a)

End Function

Function ReturnTen (a As Integer) As Integer

    Return a

End Function
```

```freebasic
'' The following example demonstrates optional parameters.

Function TestFunc(P As String = "Default") As String

    Return P

End Function

Print TestFunc("Testing:")

Print TestFunc
```

```freebasic
'' This example shows how to declare and call

'' functions taking array arguments.

Function x(b() As Double) As Integer

  x = UBound(b)-LBound(b)+1

End Function

Dim a(1 To 10) As Double

Print x(a())

Dim c(10 To 20) As Double

Print x(c())
```

---

**Category:** [Procedures](Category-Procedures)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
