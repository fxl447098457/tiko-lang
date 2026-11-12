[Home](Home) › [Partial Types](Category-Partial-Types) › **Partial**

# Partial

Writes one `type` or `class` in several blocks of one compilation unit.

## Syntax

```freebasic
[ public | private ] partial type name [ extends base ] [ field = n ]
    member declarations
end type

[ public | private ] partial class name
    [ inherits base ]
    [ implements interface [ , interface ... ] ]
    member declarations
end class
```

## Description

Each block is a *part*. The compiler combines the parts into one type before anything else reads them, so the rest of the program sees an ordinary type.

The parts must be in one source file with its includes, or in the files of one [module](Packages-and-Modules-Tutorial), at module or namespace level and in the same namespace. Every block of the type says `partial`, and all of them are `type` or all of them are `class`.

Fields are laid out part by part. A module's files are read in sorted order of their names, so the file whose name sorts first supplies the first fields. A base type's fields always come first, whichever part names the base.

`extends`, `inherits`, `field`, `extern` layout and `implements` may each appear on one part, and apply to the whole type. `public` on any part makes the type public; `public` on one part and `private` on another is an error.

A part can hold methods alone, as long as the whole type has a field. A generic type cannot be partial.

`partial` is a keyword only directly before `type` or `class`. It remains an ordinary name everywhere else.

## Examples

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

A class whose base is named by its second part:

```freebasic
class Vehicle
    Wheels as long = 4
end class

partial class Car
    Doors as long = 2
end class

partial class Car
    inherits Vehicle
    declare function Total( ) as long
end class

function Car.Total( ) as long
    return Wheels + Doors
end function

dim as Car c
print c.Total( )    ' 6
```

### See also

- [Partial Types](Category-Partial-Types)
- [`Type`](Type-Udt)
- [`Class`](Class)
- [Packages and Modules](Packages-and-Modules-Tutorial)
