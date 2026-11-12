[Home](Home) › [Operators](Category-Operators) › **Type (Udt)**

# Type (Udt)

Declares a user-defined type.

## Syntax

```freebasic
Type typename
fieldname1 As DataType
fieldname2 As DataType
As DataType fieldname3, fieldname4
...
End Type
Type typename [Alias "alternatename"] [Extends base_typename] [Field = alignment] [Extern "c"]
[Private:|Public:|Protected:]
```

## Description

`Type` is used to declare custom data types containing one or more data fields, including integer types, floating point types, fixed-size or variable-length (dynamic) arrays, fixed-size or variable-length strings, bitfields, or other user-defined types.

 Types support various functionality related to object-oriented programming:

A `Type` can also contain nested Types or Unions, of different kinds:

**-** Nested Anonymous Type/Union allows data members to be grouped as desired.
 **-** Anonymous Type or Anonymous Union can be nested on condition of alternating their nesting.
 **-** Nested Anonymous Type/Union can not have procedure members or static data members (same restriction than for a local scope named Type/Union).

**-** Nested Named Type/Union allows declaration of an inner structure inside a (named) Type/Union namespace and according to the access right of the place
 **-** Mostly everything it can be done in a Named Type/Union can also be done in a Nested Named Type/Union.
 **-** When there are circular dependencies between Types/Unions, Nested Named Type/Union usage can avoid using type aliases and forward referencing.

**-** Nested Type-Def allows declaration of an inner Type (Alias) inside a Type/Union and according to the access right of the place.

The main structure (Type/Union) must be always named, the other (nested) structures can be anonymous or named.

 `Alias "alternatename"` specifies that if `typename` must be encoded (mangled) in to a public symbol (as in an object module or library), then specifically use `alternate` name instead of the usual encoding (mangling) of `typename`.

 *Memory layout*
 Types lay out their fields consecutively in memory, following the native alignment and padding rules (described on the [`Field`](Field) page). Special care must be taken when using Types for file I/O or interacting with other programs or programming languages, in case the alignment and padding rules are different. The optional `Field = number` specifier can be used to change the behavior on the FreeBASIC side.

 *Variable-length data*
 In FreeBASIC, Type data structures must ultimately be fixed-size, such that the compiler knows how much memory to allocate for objects of that Type. Nevertheless, Types may contain variable-length (dynamic) string or array data members. However, the string's/array's data will not be embedded in the Type directly. Instead, the Type will only contain a [`String`](String)/array descriptor structure, which FreeBASIC uses behind the scenes to manage the variable-length string/array data. For sizing the structure of the array descriptor in the Type, a variable-length (dynamic) array data member must be always declared by using [`Any(S)`](Any) in place of the array bounds, in order to fix the amount of dimensions based on the number of Anys specified. A variable-length (dynamic) array data member can also be pre-sized in its declaration by using syntax with [`ReDim`](Redim).  
 Variable-length array fields are considered as pseudo-objects when they are declared in a `Type`, just like variable-length strings (the implicit copy constructor and the implicit let operator themselves support \[re\]sizing and copying such arrays, or their erasing).

 Because of that, saving such a Type into a file will write out the descriptor, not the actual string/array data. In order to embed strings/arrays into Types directly, fixed-length strings/arrays must be used.

 Similarly, when maintaining dynamic data manually through the use of pointers within a Type, it does usually not make sense to save the Type to a file, because the address stored in the pointer field will be written to file, not the actual memory it points to. Addresses are meaningful to a specific process only though, and cannot be shared that way.

 *Special note on fixed-length strings*
 Fixed-length string fields of `String * N` type have no extra null terminator at their end, making them compatible with QB strings inside Types, because they actually use just `N` bytes.

 *Note on bitfields (*fieldname*:*bits*)*
 Bitfields can only be declared inside a type or a union, and allow to specify some very small objects of a given number of bits in length. Each field is accessed and manipulated as if it were an ordinary member of the structure.  
 Only integer data-types (up to 32-bit for 32-bit development or 64-bit for 64-bit development) are valid. The sizes of the declared data-types, large enough to contain the bit patterns, affect how the bitfields are placed in memory.  
 Bitfield members in a type are packed together, unless the next member is a non-bitfield (nested union is considered a non-bitfield).  
 A bitfield does not have any address (one cannot get a pointer to it and its offset inside the structure).

 *Note on `Extern "c"`*
 `Extern "c"` lays the type out as the target's C compiler lays out the same struct or union: by MSVC's rules on `windows-x86_64` and `win64`, by the System V rules on `linux-x86_64` and `macos-arm64`. Write it on a type that C code also reads or writes. It decides two things:

 - **Bitfields.** On Windows a bitfield opens a new unit whenever its declared type's size changes, and each unit is aligned to its type: `a : 3 As Byte` then `b : 5 As Long` is 8 bytes, with `b` in the second four. In a union, a bitfield takes its type's size and adds no alignment. On Linux and macOS a bitfield goes at the next free bit unless it would then cross a boundary of its type, and it may share a byte with an ordinary field: `x : 3 As ULong` then `c As UByte` puts `c` at offset 1, in a type 4 bytes long.
 - **`Field = alignment`** also caps the type's own alignment, as `#pragma pack` does in C: a `Field = 1` type holding a `Byte` and a `Long` is 5 bytes aligned to 1, and another type holds it at offset 1. On Linux and macOS, a bitfield in a `Field` type never moves to its type's next boundary.

 The clause may stand before or after `Field = alignment`, and `"c"` is the only language it takes (`TKO0976`). [`#cinclude`](modern-Cinclude) writes it on every struct and union it imports.

## Remarks

### Platform Differences

- The default `Field` alignment parameter is 4 bytes for DOS and Linux targets.
  The default `Field` alignment parameter is 8 bytes for Windows targets (this difference with regard to 4 bytes applies only to Longint and Double members).

### Dialect Differences

- Object-related features such as functions declared inside `Type` blocks are supported only with the *[-lang fb](Compiler-Option-Lang)* dialect
  In the *[-lang fb](Compiler-Option-Lang)* and *[-lang fblite](Compiler-Option-Lang)* dialects, the default `Field` alignment parameter depends on the target platform.  
  With the *[-lang qb](Compiler-Option-Lang)* dialect the fields are aligned to byte boundaries by default, unless otherwise specified.  
  To force byte alignment use `FIELD=1`.

### Differences from QB


### See also

- [`Type (Alias)`](Type-Alias)
- [`Type (Temporary)`](Type-Temporary)
- [`Partial`](Partial)
- [`Union`](Union)
- [`Enum`](Enum)
- [`TypeOf`](Typeof)
- [`OffsetOf`](Offsetof)
- [`Alias (Name)`](Alias-Name)
- [`Field`](Field)
- [`Extends`](Extends)
- [`Extends Zstring`](Extends-Zstring)
- [`Extends Wstring`](Extends-Wstring)
- [`With`](With)
- [`Standard Data Type Limits`](Standard-Data-Type-Limits)

## Examples

This is an example of a QB-style type, not including procedure definitions

```freebasic
Type clr

    red As UByte

    green As UByte

    blue As UByte

End Type

Dim c As clr

c.red = 255

c.green = 128

c.blue = 64

/'

Alternatively (See 'Type (Temporary)' page) we could use

Dim c As clr

c = Type <clr> (255, 128, 64)

or

c = Type(255, 128, 64)  '' implicit typename

'/
```

And this is an example of a type working as an object:

```freebasic
'' Example showing fixed length string fields in UDTs

'' Suppose we have read a GIF header from a file

''                        signature         width        height

Dim As ZString*(10+1) z => "GIF89a" + MKShort(10) + MKShort(11)

Print "Using fixed-length string"

Type hdr1 Field = 1

   #if __FB_VERSION__ < "1.20.0"

      As String*(6-1) sig /' We have to dimension the string with 1 char

         '  less to avoid misalignments '/

   #else

      As String*(6) sig

   #endif

   As UShort wid, hei

End Type

Dim As hdr1 Ptr h1 = CPtr(hdr1 Ptr, @z)

Print h1->sig, h1->wid, h1->hei '' Prints GIF89 (misses a char!)  10  11

'' We can do comparisons only with the 5 visible chars and creating a temporary string with LEFT

If Left(h1->sig, 5) = "GIF89" Then Print "ok" Else Print "error"

'' Using a ubyte array, we need an auxiliary function to convert it to a string

Function ub2str( ub() As UByte ) As String

    Dim As String res = Space(UBound(ub) - LBound(ub) + 1)

    For i As Integer = LBound(ub) To UBound(ub)

        res[i - LBound(ub)] = ub(i)

    Next

    Function = res

End Function

Print

Print "Using an array of ubytes"

Type hdr2 Field = 1

   sig(0 To 6-1) As UByte '' Dimension 6

   As UShort wid, hei

End Type

Dim As hdr2 Ptr h2 = CPtr(hdr2 Ptr, @z)

'' Viewing and comparing is correct but a conversion to string is required

Print ub2str(h2->sig()), h2->wid, h2->hei '' Prints GIF89a  10  11 (ok)

If ub2str(h2->sig()) = "GIF89a" Then Print "ok" Else Print "error" '' Prints ok
```

This is an example of conversion from an Ubyte to a digit string in base 8 (octal string), by using bitfields in a local UDT (conversion equivalent to 'Oct(x, 3)'):

```freebasic
Function UbyteToOctalString (ByVal b As UByte) As String

    Union UbyteOctal

        number As UByte

        Type

            d0 : 3 As UByte

            d1 : 3 As UByte

            d2 : 2 As UByte

        End Type

    End Union

    Dim uo As UbyteOctal

    uo.number = b

    Return uo.d2 & uo.d1 & uo.d0

End Function

For I As Integer = 0 To 255

    Print Using "###: "; I;

''    Print Oct(I, 3),

    Print UbyteToOctalString(I),  '' this line is thus equivalent to the previous one

Next I

Print

Sleep
```

This is an example with Nested Named Type:

```freebasic
Type Parent

    Private:

        Dim As String nameParent

        Declare Constructor()

        Declare Constructor(ByRef As Parent)

        Type Child

            Dim As String nameChild

            Dim As Parent Ptr ptrParent

            Declare Sub kinship()

        End Type

        Dim As Child listChild(Any)

    Public:

        Declare Constructor(ByRef _nameParent As String)

        Declare Sub addChild(ByRef _nameChild As String)

        Declare Sub kinship()

End Type

Constructor Parent(ByRef _nameParent As String)

    This.nameParent = _nameParent

End Constructor

Sub Parent.addChild(ByRef _nameChild As String)

    ReDim Preserve This.listChild(UBound(This.listChild) + 1)

    This.listChild(UBound(This.listChild)).nameChild = _nameChild

    This.listChild(UBound(This.listChild)).ptrParent = @This

End Sub

Sub Parent.Child.kinship()

    Print "'" & This.nameChild & "'" & " is child of " & "'" & This.ptrParent->nameParent & "'"

End Sub

Sub Parent.kinship()

    For Each ByRef c As Child In This.listChild

        c.kinship()

    Next

End Sub

Dim As Parent p = Parent("Kennedy")

p.addChild("John Jr.")

p.addChild("Caroline")

p.addChild("Patrick")

p.kinship()

Sleep
```

---

**Category:** [Operators](Category-Operators)  
**Kind:** sub

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
