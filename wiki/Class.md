[Home](Home) › [Interfaces](Category-Interfaces) › **Class**

# Class

Declares a type that always extends `object`: it has a vtable, run-time type information, and may implement interfaces.

## Syntax

```freebasic
class name [ ( of T [ , ... ] ) ] [ field = alignment ] [ alias "mangled" ]
    [ inherits base_class ]
    [ implements interface [ , interface ... ] ]
    member declarations, fields, access labels ...
end class
```

## Parameters

- `name`: the class's name.
- `T`: a type parameter, making a generic class.
- `base_class`: the class it derives from: a `class`, or a `type` that extends `object`. Without an `inherits` line the base is `object`.
- `interface`: an interface the class implements. See [`Implements`](Implements).

## Description

A `class` is a [`Type`](Type-Udt) written so that the object model is the default. `class Person … end class` declares the same thing as `type Person extends object … end type`: every object carries a pointer to its vtable, `virtual`, `abstract` and `override` work in it, and [`Operator Is`](Operator-Is-Run-Time-Type-Information) can test it.

The base and the interfaces are lines at the top of the body, not words on the header:

- **`inherits base_class`** names the one base class (see [`Inherits`](Inherits)). A second `inherits` line, or two names on one, is an error (TKO0427), and so is `extends` on a class's header (TKO0432).
- **`implements …`** lines list the interfaces. Any number of interfaces, on one line or several.

`inherits` comes before `implements`, and both come before any member (TKO0435). Everything else in the body is written as in a `type`: fields, `declare` lines for constructors, methods, properties and operators, and `private:` / `protected:` / `public:` labels. Method bodies are written outside, as `sub Person.Greet( )`.

```freebasic
interface IGreeter
    sub Greet( )
end interface

class Person                              '' extends object: it has a vtable
    implements IGreeter
    declare constructor( byref nm as ustring = "nobody" )
    declare virtual sub Greet( ) implements IGreeter.Greet
    as ustring nm
end class
constructor Person( byref nm as ustring = "nobody" )
    this.nm = nm
end constructor
sub Person.Greet( )
    print "hello, I am "; nm
end sub

class Pirate
    inherits Person                       '' the base class, on its own line
    declare constructor( byref nm as ustring )
    declare sub Greet( ) override
end class
constructor Pirate( byref nm as ustring )
    base( nm )
end constructor
sub Pirate.Greet( )
    print "arr, "; nm; " be me name"
end sub

dim as Person ann = Person( "Ann" )
dim as Pirate bob = Pirate( "Bob" )
dim as IGreeter g = ann
g.Greet( )
g = bob                                   '' a Pirate is a Person, so it is an IGreeter
g.Greet( )
dim as Person ptr p = @bob
print "p points at a Pirate: "; cbool( *p is Pirate )
```

```
hello, I am Ann
arr, Bob be me name
p points at a Pirate: true
```

A class and a `type` mix freely: a class may inherit a `type` that extends `object`, and a `type` may extend a class.

## Remarks

- A class cannot be `extern "C"` or `extern "C++"` (TKO0437): its layout has a vtable pointer that C cannot describe.
- `class` makes no member virtual by itself. Write `virtual` where a derived class should be able to replace a method, and repeat it on an `override` that should itself be overridable.
- A plain `type` can implement interfaces too, without a vtable. Choose `class` when objects need inheritance or run-time type tests, and `type` for small values.

### See also

- [`Type`](Type-Udt)
- [`Inherits`](Inherits)
- [`Implements`](Implements)
- [`Interface`](Interface)
- [`Object`](Object)
- [`Partial`](Partial)
- [`Virtual`](Virtual)
- [Interfaces Tutorial](Interfaces-Tutorial)

---

**Category:** [Interfaces](Category-Interfaces)
**Kind:** keyword
