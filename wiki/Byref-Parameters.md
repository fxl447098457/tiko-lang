[Home](Home) › [Procedures](Category-Procedures) › **Byref (Parameters)**

# Byref (Parameters)

Declaration specifier to explicitly pass a parameter by reference

## Syntax

```freebasic
ByRef param As datatype
```

## Description

Passes a variable by reference, that is its address, to a subroutine or function. When a variable is passed by reference, the contents of the variable can be changed by the target subroutine or function.

 In *[-lang qb](Compiler-Option-Lang)* and *[-lang fblite](Compiler-Option-Lang)* dialects, `ByRef` is the default parameter passing convention, unless `Option ByVal` is in effect.

 Opposite of [`ByVal`](Byval).

 **Note:** A constant or a literal expression can also be passed to such a procedure (which gets by reference), but they are obviously not modifiable from the procedure body. In that case, the compiler passes by reference a temporary variable initialized with the constant or the literal expression.

 **Note:** A [`Property`](Property) passed to a `ByRef` parameter is passed as a temporary holding the getter's value. When the parameter is not `Const` and the property's setter may be called at that point, the temporary is written back through the setter after the call returns, so `Inc( obj.Size )` changes `obj.Size`.

 **Note:** Arguments of STRING\*N type are copied to a temporary variable when passed to BYREF ZSTRING (or BYVAL ZSTRING PTR) parameters (since there is no expectation that STRING\*N will have it's own terminating null character) and copied back after the call.

 **Warning:** When passing by reference, it is recommended to pass an argument of the same type (or fully compatible, like a derived type for example) as that of the declared parameter. Although in some cases the compiler accepts to pass a different type, often the result is not the one expected.

## Remarks

### Usage

`[ Declare ] { Sub | Function } proc_name ( ByRef param As datatype )`

### Dialect Differences

- In *[-lang fb](Compiler-Option-Lang)* dialect, [`ByVal`](Byval) is the default parameter passing convention for all built-in types except [`String`](String) and user-defined [`Type`](Type-Udt) which are passed `ByRef` by default. The [`ZString`](Zstring) and [`WString`](Wstring) built-in types are also passed `ByRef` by default, but passing [`ByVal`](Byval) is forbidden. Arrays are always passed `ByRef`: the specifier `ByRef` may be written on an array parameter (`Sub f( ByRef a() As Integer )`) and means the same as leaving it out, while [`ByVal`](Byval) is forbidden.
  In *[-lang qb](Compiler-Option-Lang)* and *[-lang fblite](Compiler-Option-Lang)* dialects, `ByRef` is the default parameter passing convention.

### Differences from QB

- New to FreeBASIC

### See also

- [`Declare`](Declare)
- [`ByVal`](Byval)
- [`Byref (Function Results)`](Byref-Function-Results)
- [`Byref (Variables)`](Byref-Variables)

## Examples

```freebasic
Dim MyVar As Integer

Sub ChangeVar(ByRef AVar As Integer)

    AVar = AVar + 1

End Sub

MyVar = 1

Print "MyVar: "; MyVar 'output = 1

ChangeVar MyVar

Print "MyVar: "; MyVar 'output = 2

Sleep

End
```

---

**Category:** [Procedures](Category-Procedures)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
