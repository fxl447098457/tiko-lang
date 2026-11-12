[Home](Home) › [All Categories](Categories) › **Partial Types**

# Partial Types

```freebasic
partial type Point
    x as long
    y as long
end type

partial type Point
    declare function Sum( ) as long
end type

function Point.Sum( ) as long
    return x + y
end function

dim as Point p = type( 3, 4 )
print p.Sum( )      ' 7
```

`partial type` writes one type in several blocks, and `partial class` does the same for a [class](Category-Interfaces). The compiler pools the blocks into a single type before anything else looks at it, so every other part of the language sees one ordinary type.

For the syntax on one page, see [`Partial`](Partial).

## Why It Exists

Some types have two authors. A form designer writes a form's controls and event declarations, and a person writes the form's own data and helper methods. With one block, the tool has to edit text the person owns. With two blocks, each keeps to its own, and the tool can rewrite its half at any time.

## In a Module

The usual home for the parts is two files of one [module](Packages-and-Modules-Tutorial). A module's files are compiled together, so its parts combine with no `#include` and no `declare` lines:

```freebasic
' frmMain/frmMain.design.tiko -- written by a tool
#module "frmMain"

public partial type Form
    btnOK as long
    declare sub btnOK_Click( )
end type
```

```freebasic
' frmMain/frmMain.tiko -- written by you
#module "frmMain"

partial type Form
    Count as long
end type

sub Form.btnOK_Click( )
    Count += 1
end sub
```

A program importing this module sees the whole type. `sizeof( frmMain.Form )` counts the fields of both parts.

## Rules

**Every block says `partial`, and the same kind.** A `partial type` and an ordinary `type` of the same name are an error, as are a `partial type` and a `partial class`.

**All parts are in one compilation unit**: one source file with its includes, or one module. They must be at module or namespace level, and in the same namespace.

**Members combine in order.** Fields are laid out part by part, in the order the compiler reads them. In a module that is the sorted order of its file names, which puts `frmMain.design.tiko` before `frmMain.tiko`. Declaring the same member in two parts is the usual "already declared" error.

**One part may give each header clause.** `extends`, `field`, `extern` layout and `implements` may each appear on one part, whichever part that is, and apply to the whole type. So may a class's `inherits` line; parts that write none take the base from the part that does. A base type's fields still come first.

**Visibility.** `public` on any part makes the type public, and the other parts need not repeat it. `public` on one part and `private` on another is an error.

**A part can be methods alone.** Only the whole type needs a field.

**Not generic.** A generic type cannot be `partial`.

**`partial` is only a keyword directly before `type` or `class`.** It remains an ordinary name everywhere else: `dim as long partial` and a procedure named `partial` are both fine.

## Errors

| Code | Means |
|---|---|
| `TKO1063` | One declaration says `partial` and another of the same name doesn't. |
| `TKO1064` | The type has type parameters. |
| `TKO1065` | `partial` is on an alias such as `partial type T as long`, which has no body. |
| `TKO1066` | Two parts give the same header clause. |
| `TKO1067` | One part is `public` and another `private`. |
| `TKO1068` | One part is a `partial type` and another a `partial class`. |
