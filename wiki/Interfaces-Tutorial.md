[Home](Home) › **Interfaces Tutorial**

# Interfaces Tutorial

This tutorial writes the same small program twice: once with **classic inheritance** (an abstract base type that every shape extends), and once with tiko's **interfaces and classes**: `interface`, `class`, `inherits`, `implements` and `trycast`. Then it goes on to what only interfaces can do: properties in a contract, generic interfaces, and constraints on generic code.

**Who this is for:** a tiko programmer who has written a `type` with methods, and maybe used `extends`, `virtual` and `abstract`. No knowledge of interfaces is assumed.

**What you need:** a tiko toolchain. Every program in this tutorial was compiled and run on windows-x86_64, and the output shown is the real output.

The running example is a set of shapes. Part by part, we ask more of it:

1. A single contract that every shape follows.
2. A second contract: saving to text.
3. Two contracts that both want a member called `Name`.
4. Run-time type checks.
5. Contracts built from other contracts.
6. Class hierarchies and interfaces together. This is an optional, advanced pattern; Parts 1–5 need no `virtual` or `abstract`.
7. Small value types.
8. Properties in a contract.
9. Generic interfaces.
10. Constraints: generic code that asks for an interface.

Every listing is a complete program. Copy it into a `.tiko` file and compile it with `tiko file.tiko`.

---

## Part 1 — One contract

### Classic: an abstract base type

```freebasic
type Shape extends object
    declare abstract function Area( ) as double
    declare abstract function Name( ) as string
    declare virtual destructor( )
end type
destructor Shape( )
end destructor

type Circle extends Shape
    declare constructor( byval r as double )
    declare function Area( ) as double override
    declare function Name( ) as string override
    as double r
end type
constructor Circle( byval r as double )
    this.r = r
end constructor
function Circle.Area( ) as double
    return 3.14159 * r * r
end function
function Circle.Name( ) as string
    return "circle"
end function

type Rect extends Shape
    declare constructor( byval w as double, byval h as double )
    declare function Area( ) as double override
    declare function Name( ) as string override
    as double w, h
end type
constructor Rect( byval w as double, byval h as double )
    this.w = w : this.h = h
end constructor
function Rect.Area( ) as double
    return w * h
end function
function Rect.Name( ) as string
    return "rect"
end function

sub Report( byval s as Shape ptr )
    print s->Name( ); ": "; s->Area( )
end sub

dim as Shape ptr shapes( 0 to 1 )
shapes( 0 ) = new Circle( 1 )
shapes( 1 ) = new Rect( 2, 3 )
for each s in shapes
    Report( s )
next
for each s in shapes
    delete s
next
```

```
circle:  3.14159
rect:  6
```

**The contract is a type.** It has to extend `object`, so that it has a vtable. It marks its methods `abstract`, and each shape `extends` it and marks its methods `override`. Code that works with "any shape" takes a `Shape ptr`.

### With interfaces: an interface and two classes

```freebasic
interface IShape
    function Area( ) as double
    function Name( ) as string
end interface

class Circle
    implements IShape

    declare constructor( byval r as double )
    declare function Area( ) as double implements IShape.Area
    declare function Name( ) as string implements IShape.Name
    as double r
end class
constructor Circle( byval r as double )
    this.r = r
end constructor
function Circle.Area( ) as double
    return 3.14159 * r * r
end function
function Circle.Name( ) as string
    return "circle"
end function

class Rect
    implements IShape

    declare constructor( byval w as double, byval h as double )
    declare function Area( ) as double implements IShape.Area
    declare function Name( ) as string implements IShape.Name
    as double w, h
end class
constructor Rect( byval w as double, byval h as double )
    this.w = w : this.h = h
end constructor
function Rect.Area( ) as double
    return w * h
end function
function Rect.Name( ) as string
    return "rect"
end function

sub Report( byval s as IShape )
    print s.Name( ); ": "; s.Area( )
end sub

dim as Circle c = Circle( 1 )
dim as Rect   r = Rect( 2, 3 )
dim as IShape shapes( 0 to 1 )
shapes( 0 ) = c                     '' an object converts to an interface it implements
shapes( 1 ) = @r                    '' ...and so does a pointer to one
for each s in shapes
    Report( s )
next
```

```
circle:  3.14159
rect:  6
```

**What changed:**

| Classic | Interfaces | Why |
| --- | --- | --- |
| `type Shape extends object` with `abstract` members | `interface IShape` | A contract is no longer a type you inherit from. It has no fields and no vtable of its own, and is never instantiated. |
| members `declare abstract function …` | members `function …` (`declare` optional) | Every interface member is public and abstract; there is nothing to say. |
| `type Circle extends Shape` | `class Circle` + `implements IShape` line | A `class` always extends `object`. Interfaces are listed on `implements` lines at the top of the body. |
| `… override` | `… implements IShape.Area` | Each method says *which* interface member it fulfils. |
| `Shape ptr`, `s->Name( )` | `IShape`, `s.Name( )` | An interface value is a reference: the object's address plus a dispatch table, 16 bytes. Use `.`, not `->`. |
| `new` / `delete` through the base pointer | objects live anywhere; interface values **don't own them** | You cannot `delete` through an interface (TKO1013). Keep the owning variable or pointer as its concrete type. |

**What did not change:**

- Method bodies are still written out of line (`function Circle.Area( ) as double … end function`), and every method a class declares needs one. Inside `class` and `type` bodies, `declare` is still required.
- Constructors, fields, access labels (`private:`) and the `this` pointer all work as before.

---

## Part 2 — A second contract

The shapes must now also be **saved as text**. So must a `Settings` record, which is not a shape at all.

### Classic: one base per type

The natural attempt does not compile:

```freebasic
type Circle extends Shape, Serializable
```

```
error TKO0427: a type extends one base type
```

A type has exactly one base. The usual workaround is to **chain the contracts**: `Shape` itself extends `Serializable`.

```freebasic
type Serializable extends object
    declare abstract function ToText( ) as string
end type

type Shape extends Serializable          '' every Shape is now forced to be Serializable
    declare abstract function Area( ) as double
    declare abstract function Name( ) as string
end type

type Circle extends Shape
    declare constructor( byval r as double )
    declare function Area( ) as double override
    declare function Name( ) as string override
    declare function ToText( ) as string override
    as double r
end type
constructor Circle( byval r as double )
    this.r = r
end constructor
function Circle.Area( ) as double
    return 3.14159 * r * r
end function
function Circle.Name( ) as string
    return "circle"
end function
function Circle.ToText( ) as string
    return "circle r=" & r
end function

type Settings extends Serializable       '' not a shape, but serializable
    declare function ToText( ) as string override
    as long volume = 7
end type
function Settings.ToText( ) as string
    return "volume=" & volume
end function

sub Save( byval s as Serializable ptr )
    print "saving "; s->ToText( )
end sub

dim as Circle c = Circle( 2 )
dim as Settings st
Save( @c )
Save( @st )
```

```
saving circle r=2
saving volume=7
```

It works, but the design has bent to fit the language:

- **Every shape must now be serializable**, including ones that never need it, because `Shape` itself extends `Serializable`.
- **A third contract** (say `Comparable`) has to be wedged into the same chain. The order of the chain becomes an architectural decision that cannot be undone.
- **A type from a library** that already extends some other base can never join the chain.

The other workaround is an adapter type per contract: a `CircleSaver extends Serializable` that holds a `Circle ptr`. It keeps the hierarchies apart, at the cost of a second object and boilerplate per (type, contract) pair.

### With interfaces: implement both

```freebasic
interface IShape
    function Area( ) as double
    function Name( ) as string
end interface

interface ISerializable
    function ToText( ) as string
end interface

class Circle
    implements IShape, ISerializable          '' or two separate 'implements' lines

    declare constructor( byval r as double )
    declare function Area( ) as double implements IShape.Area
    declare function Name( ) as string implements IShape.Name
    declare function ToText( ) as string implements ISerializable.ToText
    as double r
end class
constructor Circle( byval r as double )
    this.r = r
end constructor
function Circle.Area( ) as double
    return 3.14159 * r * r
end function
function Circle.Name( ) as string
    return "circle"
end function
function Circle.ToText( ) as string
    return "circle r=" & r
end function

class Settings
    implements ISerializable                  '' unrelated to shapes, and that is fine

    declare function ToText( ) as string implements ISerializable.ToText
    as long volume = 7
end class
function Settings.ToText( ) as string
    return "volume=" & volume
end function

sub Save( byval s as ISerializable )
    print "saving "; s.ToText( )
end sub

dim as Circle c = Circle( 2 )
dim as Settings st
Save( c )
Save( st )
```

```
saving circle r=2
saving volume=7
```

The two contracts are independent:

- `IShape` knows nothing about `ISerializable`.
- `Circle` takes on both, and `Settings` takes on one.
- `Rect` could take on only `IShape` and never be serializable.
- A third interface is one more `implements` line, with no chain to re-order.

---

## Part 3 — Two contracts that both want `Name`

Suppose a `Circle` is also published to a file, and the export contract has its own `Name` (the file name). That `Name` means something different from the shape's name.

### Classic

There is no way to say it. One type cannot have two `Name( ) as string` methods with the same signature, and it cannot have two bases in the first place. One of the contracts has to rename its member (`FileName`) before the type can follow both. That only works if you own both contracts.

### With interfaces

```freebasic
interface IShape
    function Area( ) as double
    function Name( ) as string
end interface

interface IExportable
    function Name( ) as string                '' the file name
    sub Publish( )
    sub Flush( )
end interface

interface ISerializable
    function ToText( ) as string
    sub Flush( )
end interface

class Circle
    implements IShape, IExportable, ISerializable

    declare constructor( byval r as double )
    declare function ShapeName( ) as string implements IShape.Name
    declare function FileName( ) as string implements IExportable.Name
    declare function Area( ) as double implements IShape.Area
    declare function ToText( ) as string implements ISerializable.ToText
    declare sub Flush( ) implements ISerializable.Flush, IExportable.Flush
    as double r
private:
    declare sub WriteFile( ) implements IExportable.Publish   '' reachable only through IExportable
end class
constructor Circle( byval r as double )
    this.r = r
end constructor
function Circle.ShapeName( ) as string
    return "circle"
end function
function Circle.FileName( ) as string
    return "circle.txt"
end function
function Circle.Area( ) as double
    return 3.14159 * r * r
end function
function Circle.ToText( ) as string
    return "circle r=" & r
end function
sub Circle.Flush( )
    print "  (flushed)"
end sub
sub Circle.WriteFile( )
    print "writing "; FileName( )
end sub

dim as Circle c = Circle( 1 )
dim as IShape s = c
dim as IExportable e = c
dim as ISerializable z = c
print s.Name( ); " / "; e.Name( )
e.Publish( )
e.Flush( )
z.Flush( )
```

```
circle / circle.txt
writing circle.txt
  (flushed)
  (flushed)
```

Three rules make this work:

- **The method's name doesn't have to match the member's.** `ShapeName` implements `IShape.Name`.
- **Same-named members of different interfaces are different members.** Each gets its own method.
- **A private method may implement a member.** `WriteFile` is reachable through an `IExportable` and nowhere else. Called directly, it is an access error:

  ```
  error TKO0625: 'writefile' is not accessible here
  ```

The reverse also works: **one method can fulfil several members at once.** `Flush` implements both `ISerializable.Flush` and `IExportable.Flush`.

---

## Part 4 — Run-time checks and casts

### Classic: `is` and an unchecked `cast`

```freebasic
type Serializable extends object
    declare abstract function ToText( ) as string
end type

type Shape extends Serializable          '' every Shape is now forced to be Serializable
    declare abstract function Area( ) as double
    declare abstract function Name( ) as string
end type

type Circle extends Shape
    declare constructor( byval r as double )
    declare function Area( ) as double override
    declare function Name( ) as string override
    declare function ToText( ) as string override
    as double r
end type
constructor Circle( byval r as double )
    this.r = r
end constructor
function Circle.Area( ) as double
    return 3.14159 * r * r
end function
function Circle.Name( ) as string
    return "circle"
end function
function Circle.ToText( ) as string
    return "circle r=" & r
end function

type Settings extends Serializable       '' not a shape, but serializable
    declare function ToText( ) as string override
    as long volume = 7
end type
function Settings.ToText( ) as string
    return "volume=" & volume
end function

sub Save( byval s as Serializable ptr )
    print "saving "; s->ToText( )
end sub

dim as Circle c = Circle( 2 )
dim as Settings st
dim as Serializable ptr p = @c
if *p is Circle then
    dim as Circle ptr cp = cast( Circle ptr, p )
    print "it is a circle of radius"; cp->r
end if
p = @st
print "settings is a Shape? "; ( *p is Shape )
```

```
it is a circle of radius 2
settings is a Shape?  0
```

- `is` works only between types that extend `object`. The tested type must be derived from the static type.
- `cast` is not checked at all. Casting to the wrong type is undefined behaviour.

### With interfaces: `is`, `cast` and `trycast`

The types are Part 2's.

```freebasic
interface IShape
    function Area( ) as double
    function Name( ) as string
end interface

interface ISerializable
    function ToText( ) as string
end interface

class Circle
    implements IShape, ISerializable          '' or two separate 'implements' lines

    declare constructor( byval r as double )
    declare function Area( ) as double implements IShape.Area
    declare function Name( ) as string implements IShape.Name
    declare function ToText( ) as string implements ISerializable.ToText
    as double r
end class
constructor Circle( byval r as double )
    this.r = r
end constructor
function Circle.Area( ) as double
    return 3.14159 * r * r
end function
function Circle.Name( ) as string
    return "circle"
end function
function Circle.ToText( ) as string
    return "circle r=" & r
end function

class Settings
    implements ISerializable                  '' unrelated to shapes, and that is fine

    declare function ToText( ) as string implements ISerializable.ToText
    as long volume = 7
end class
function Settings.ToText( ) as string
    return "volume=" & volume
end function

sub Save( byval s as ISerializable )
    print "saving "; s.ToText( )
end sub

dim as Circle c = Circle( 2 )
dim as Settings st
dim as ISerializable s = c

if s is Circle then                                 '' is the object a Circle?
    dim as Circle ptr cp = cast( Circle ptr, s )    '' unchecked, like a classic cast
    print "it is a circle of radius"; cp->r
end if

dim as IShape sh = trycast( IShape, s )             '' a CROSS cast: same object, another interface
if sh <> nullptr then print "and its area is"; sh.Area( )

s = st
print "settings is a shape? "; ( s is IShape )
dim as Circle ptr none = trycast( Circle ptr, s )   '' nullptr: Settings is not a Circle
print none = nullptr
```

```
it is a circle of radius 2
and its area is 12.56636
settings is a shape?  0
-1
```

The new parts:

- **`trycast( T, x )`** converts or answers "no": a null interface value, or `nullptr` for a pointer. The type comes first, as in `cast`.
- **Cross casts** ask whether the object behind one interface also implements another (`ISerializable` → `IShape`). There is no classic equivalent.
- **`is` accepts interfaces on either side**, as in `s is IShape`.
- **`cast( Circle ptr, s )` is unchecked**, like a classic cast, and a wrong one is undefined behaviour. Test with `is` first, as above, or use `trycast`.

---

## Part 5 — Contracts built from contracts

### Classic

A contract that extends another is just a longer chain. `type Named extends object` with `Name`, then `type Shape extends Named` with `Area`. It works, but it is still one chain: `Shape` cannot extend `Named` *and* `Comparable`.

### With interfaces: `inherits` lines, and as many as needed

```freebasic
interface INamed
    function Name( ) as string
end interface

interface IComparable
    function CompareTo( byval other as IComparable ) as long
end interface

interface IShape
    inherits INamed
    inherits IComparable          '' or: inherits INamed, IComparable
    function Area( ) as double
end interface

class Circle
    implements IShape             '' implementing IShape means implementing all three

    declare constructor( byval r as double )
    declare function Name( ) as string implements INamed.Name
    declare function CompareTo( byval other as IComparable ) as long implements IComparable.CompareTo
    declare function Area( ) as double implements IShape.Area
    as double r
end class
constructor Circle( byval r as double )
    this.r = r
end constructor
function Circle.Name( ) as string
    return "circle"
end function
function Circle.Area( ) as double
    return 3.14159 * r * r
end function
function Circle.CompareTo( byval other as IComparable ) as long
    dim as Circle ptr o = trycast( Circle ptr, other )
    if o = nullptr then return 0
    return sgn( r - o->r )
end function

dim as Circle a = Circle( 1 ), b = Circle( 2 )
dim as IShape s = a
dim as INamed n = s               '' widening: free
dim as IComparable k = s          '' widening: one load
print n.Name( ); " has area"; s.Area( )
print "compared with b:"; k.CompareTo( b )
```

```
circle has area 3.14159
compared with b:-1
```

- **An `IShape` *is* an `INamed` and an `IComparable`.** Converting to either is implicit and costs nothing or one memory load.
- **`trycast` inside `CompareTo`** recovers the concrete type of the other object, and answers 0 for an object that is not a circle.
- **Leaving out a mapping is an error.** If `Circle` forgot `CompareTo`, the compiler names the missing member:

  ```
  error TKO1000: 'circle' does not implement 'icomparable.compareto'; add 'implements icomparable.compareto' to one of its methods
note: 'compareto' is required by interface 'icomparable', declared here
  ```

---

## Part 6 — Class hierarchies and interfaces together (optional, advanced)

> **You don't need this part to use interfaces.** The default style is the one in Parts 1–5: each class implements the interfaces it needs, with no base class and no `virtual`, `abstract` or `override` anywhere. Polymorphism comes from the interface. Shared code goes in a free function over the interface, or in a helper object kept as a field.
>
> Use the pattern below only when you really want **class inheritance with overriding**: a base class that supplies code its subclasses may replace (`virtual`), or must supply (`abstract`). Whether a method is overridable is decided when the base class is compiled, so the base has to say so. That is why these words still exist.

Interfaces don't replace class inheritance; they sit beside it. A base class can implement an interface with an `abstract` or `virtual` method, and derived classes override it as they always have. Calls through the interface still reach the override.

```freebasic
interface ISpeaker
    sub Speak( )
end interface

class Animal
    implements ISpeaker
    declare abstract sub Speak( ) implements ISpeaker.Speak
end class

class Dog
    inherits Animal               '' the base class, on its own line
    declare virtual sub Speak( ) override   '' virtual again, so Puppy can override it
end class
sub Dog.Speak( )
    print "Woof"
end sub

type Puppy extends Dog            '' classic 'type ... extends' still works, and mixes with 'class'
    declare sub Speak( ) override
end type
sub Puppy.Speak( )
    print "Yip"
end sub

dim as Dog d
dim as Puppy p
dim as ISpeaker sp = d
sp.Speak( )                       '' Woof
sp = p
sp.Speak( )                       '' Yip: the interface call follows the override
```

```
Woof
Yip
```

**An override is only overridable again if it says `virtual` too.** `Dog.Speak` writes `virtual … override` because `Puppy` overrides it in turn. Without the `virtual`, `Puppy`'s `override` is an error (TKO0621: it overrides no virtual method).

The aggregate forms, side by side:

| | Base | Interfaces | Has a vtable |
| --- | --- | --- | --- |
| `type T … end type` | `extends B` on the header | `implements` lines in the body | only if it extends `object` |
| `class C … end class` | `inherits B` line in the body; `object` if none | `implements` lines in the body | always |
| `interface I … end interface` | `inherits J, K` lines in the body | — | — |

**Base lines go first.** In a class body, `inherits` must come before `implements`, and both must come before any member.

---

## Part 7 — Small value types

### Classic

To follow an abstract contract, a type must extend `object`, so every value carries a vtable pointer:

```freebasic
type Showable extends object
    declare abstract function Show( ) as string
end type
type Point extends Showable
    as long x, y
    declare function Show( ) as string override
end type
function Point.Show( ) as string
    return "(" & x & ", " & y & ")"
end function
print "a Point is"; sizeof( Point ); " bytes"
```

```
a Point is 16 bytes
```

### With interfaces

A plain `type`, with no `extends object` and no vtable, can implement an interface. The dispatch table travels in the interface value, not in the object.

```freebasic
interface IShow
    function Show( ) as string
end interface

type Point
    implements IShow
    as long x, y
    declare function Show( ) as string implements IShow.Show
end type
function Point.Show( ) as string
    return "(" & x & ", " & y & ")"
end function

dim as Point pt = ( 3, 4 )
dim as IShow v = pt
print v.Show( )
print "a Point is"; sizeof( Point ); " bytes, an IShow"; sizeof( IShow )
```

```
(3, 4)
a Point is 8 bytes, an IShow 16
```

An array of a million `Point`s is 8 MB, not 16 MB. The 16 bytes of the interface value are paid only where one is held.

---

## Part 8 — Properties in a contract

An interface can list properties as well as methods. Each accessor is a member of its own: a getter, a setter, or both. A class maps each one with `implements`, as it maps a method.

```freebasic
interface IResizable
    property Width( ) as double                   '' get
    property Width( byval v as double )           '' set
    property Area( ) as double                    '' read-only: no setter in the contract
end interface

class Square
    implements IResizable
    declare property Side( ) as double implements IResizable.Width
    declare property Side( byval v as double ) implements IResizable.Width
    declare property Area( ) as double implements IResizable.Area
    as double s = 1
end class
property Square.Side( ) as double
    return s
end property
property Square.Side( byval v as double )
    s = v
end property
property Square.Area( ) as double
    return s * s
end property

dim as Square sq
dim as IResizable r = sq
r.Width = 3                       '' calls Square.Side( 3 ) through the interface
r.Width += 1                      '' get, add, set
print "width"; r.Width; ", area"; r.Area
print sq.Side                     '' the object itself changed
```

```
width 4, area 16
 4
```

- **`Width` is two members**, the getter and the setter, and `Square` maps both to its own `Side`. The names differ, as in Part 3.
- **`Area` is read-only in the contract**, so `r.Area = 5` through the interface is an error (TKO0680), even if the class had a setter.
- **Compound assignment works through the interface.** `r.Width += 1` calls the getter, adds, and calls the setter.
- An **indexed property**, `property Item( byval i as long ) as double`, is listed and mapped the same way.

---

## Part 9 — Generic interfaces

An interface can take type parameters, like a generic type. Each instance is an interface of its own: `IComparer( of string )` and `IComparer( of double )` are two unrelated contracts, and a class implements the ones it needs.

```freebasic
interface IComparer( of T )
    function Compare( byval a as T, byval b as T ) as long
end interface

class ByLength
    implements IComparer( of string )
    declare function Compare( byval a as string, byval b as string ) as long _
        implements IComparer( of string ).Compare
end class
function ByLength.Compare( byval a as string, byval b as string ) as long
    return len( a ) - len( b )
end function

class Descending
    implements IComparer( of double )
    declare function Compare( byval a as double, byval b as double ) as long _
        implements IComparer( of double ).Compare
end class
function Descending.Compare( byval a as double, byval b as double ) as long
    return sgn( b - a )
end function

'' One sort, any element type, any order.
sub SortWith( of T )( a( ) as T, byval cmp as IComparer( of T ) )
    for i as integer = lbound( a ) + 1 to ubound( a )
        dim as T v = a( i )
        dim as integer j = i - 1
        do while j >= lbound( a )
            if cmp.Compare( a( j ), v ) <= 0 then exit do
            a( j + 1 ) = a( j )
            j -= 1
        loop
        a( j + 1 ) = v
    next
end sub

dim as string words( 0 to 3 ) = { "banana", "fig", "kiwi", "apple" }
dim as ByLength bl
SortWith( words( ), bl )
for each w in words : print " "; w; : next : print

dim as double sizes( 0 to 3 ) = { 2.5, 9, 0.5, 4 }
dim as Descending dsc
SortWith( sizes( ), dsc )
for each sz in sizes : print sz; : next : print
```

```
 fig kiwi apple banana
 9 4 2.5 0.5
```

- **A method names the member of an instance**: `implements IComparer( of string ).Compare`.
- **`SortWith` infers `T` from both arguments.** The array says `string`; `bl` is a `ByLength`, which is no `IComparer` itself but implements `IComparer( of string )`, so it agrees. A class that implemented two instances of `IComparer` would leave the choice open, and the call would need `SortWith( of string )( … )`.
- **One sort, any element type, any order.** `SortWith` is compiled once per element type; the comparison is a call through the interface.

A **generic class** can implement interfaces too. Every instance gets its own mapping, so `Box( of long )` and `Box( of string )` are both an `IShow`:

```freebasic
interface IShow
    function Show( ) as string
end interface

class Box( of T )
    implements IShow
    declare function Show( ) as string implements IShow.Show
    as T v
end class
function Box( of T ).Show( ) as string
    return "Box(" & v & ")"
end function

dim as Box( of long ) n
n.v = 7
dim as Box( of string ) w
w.v = "hi"
dim as IShow items( 0 to 1 )
items( 0 ) = n
items( 1 ) = w
for each it in items : print it.Show( ) : next
```

```
Box(7)
Box(hi)
```

A generic interface named without its type arguments, or with the wrong number of them, is an error (TKO0815, TKO0816), as for a generic type.

---

## Part 10 — Constraints: generic code that asks for an interface

A generic procedure or type can require its type argument to implement an interface: `of T as IComparable( of T )`. Several are written in braces: `of K as { IComparable( of K ), IShow }`.

```freebasic
interface IComparable( of T )
    function CompareTo( byref other as T ) as long
end interface

class Money
    implements IComparable( of Money )
    declare constructor( byval cents as long )
    declare function CompareTo( byref other as Money ) as long _
        implements IComparable( of Money ).CompareTo
    as long cents
end class
constructor Money( byval cents as long )
    this.cents = cents
end constructor
function Money.CompareTo( byref other as Money ) as long
    return sgn( cents - other.cents )
end function

'' T must implement IComparable( of T ); the body calls CompareTo on T directly.
function Largest( of T as IComparable( of T ) )( a( ) as T ) as T
    dim as integer best = lbound( a )
    for i as integer = lbound( a ) + 1 to ubound( a )
        if a( i ).CompareTo( a( best ) ) > 0 then best = i
    next
    return a( best )
end function

dim as Money prices( 0 to 2 ) = { Money( 250 ), Money( 1999 ), Money( 75 ) }
print "largest:"; Largest( prices( ) ).cents
```

```
largest: 1999
```

- **The body calls `CompareTo` on a `T` directly.** `Largest` is compiled once for `Money`, and `a( i ).CompareTo( … )` is an ordinary call to `Money.CompareTo`: no interface value, no indirect call.
- **The constraint is checked once, where `Largest` is used.** A type argument that does not implement the interface is refused there, with one message, instead of with an error from somewhere inside the body:

  ```freebasic
  dim as long counts( 0 to 2 ) = { 3, 1, 2 }
  print Largest( counts( ) )
  ```

  ```
  error TKO1022: type argument 'long' does not implement 'icomparable( of long )', which 'largest( of t )' requires
  ```

- **A constraint may name its own parameter** (`IComparable( of T )`), and may name an interface the type implements through a base class, or one it inherits.
- **A constraint must be an interface.** `of T as SomeType`, where `SomeType` is a `type`, is TKO1002.

Constraints check the contract; they don't change how the body calls. Inside `Largest`, `a( i ).CompareTo( … )` is resolved on the concrete type by name, so the implementing method must be called `CompareTo` itself. A method mapped under another name (`declare function Cmp( … ) implements IComparable( of Money ).CompareTo`) satisfies the constraint but is not reachable as `.CompareTo` in the body.

---

## Cheat sheet

| Task | Classic | Interfaces |
| --- | --- | --- |
| Declare a contract | `type IFoo extends object` + `declare abstract …` | `interface IFoo` … `end interface` |
| Contract member | `declare abstract sub Go( )` | `sub Go( )` (or `declare sub Go( )`) |
| Contract property | `declare abstract property P( ) as long` | `property P( ) as long` (getter), `property P( byval v as long )` (setter) |
| Contract extends contract | `type IBar extends IFoo` (one only) | `inherits IFoo` line (any number) |
| A class | `type C extends object` | `class C` … `end class` |
| Derive from a class | `type D extends C` | `class D` + `inherits C` line (or keep `type D extends C`) |
| Follow a contract | `extends IFoo` (uses up the only base) | `implements IFoo` line (any number) |
| Provide a member | `declare sub Go( ) override` | `declare sub Go( ) implements IFoo.Go` |
| Different method name | not possible | `declare sub Run( ) implements IFoo.Go` |
| One method, two members | not possible | `declare sub Go( ) implements IFoo.Go, IBar.Go` |
| Private implementation | not possible | `private:` + `implements …` |
| An "any IFoo" parameter | `byval p as IFoo ptr`, `p->Go( )` | `byval p as IFoo`, `p.Go( )` |
| Is it a `C`? | `*p is C` | `p is C` |
| Does it also do `IBar`? | not possible | `p is IBar`, `trycast( IBar, p )` |
| Downcast | `cast( C ptr, p )` (unchecked) | `cast( C ptr, p )` (unchecked) or `trycast( C ptr, p )` |
| Destroy | `delete p` through a virtual destructor | delete through the concrete type; interfaces don't own |
| A generic contract | — | `interface IComparer( of T )` |
| Map a generic member | — | `implements IComparer( of string ).Compare` |
| Require a contract of `T` | — | `function F( of T as IFoo )( … )`, `of T as { IFoo, IBar }` |

---

## Things to know

- **Classic code keeps working, unchanged.** None of this changes how existing `type`, `extends`, `virtual`, `abstract` or `override` code compiles or lays out. `interface`, `inherits` and `trycast` can still be used as ordinary names elsewhere in a program.
- **COM stays classic.** COM interfaces (`IUnknown`, `IShellItem`, …) are binary layouts that `extends object` + `abstract` reproduces exactly. tiko interfaces are a different, more compact representation, and are not COM-compatible.
- **Interface values are references.** Copying one copies the reference, not the object, so the object must outlive every interface value that refers to it. Converting a temporary is refused for that reason (TKO1012).
- **Mappings are explicit.** A public method called `Area` does not quietly implement `IShape.Area`; it needs the `implements IShape.Area` clause. That is what makes Part 3 possible.
- **Every declared method needs a body.** A class that declares `Area` and never defines `Circle.Area` compiles, then fails at link time with an undefined symbol for `CIRCLE::AREA()`, referenced from the class's dispatch table.
- **Some names are reserved words.** `Export` is one: an interface member called `Export` is TKO0600. Pick another name (`Publish` in Part 3).

See also: [Interface](Interface), [Class](Class), [Implements](Implements), [Inherits](Inherits), [TryCast](TryCast), [Category: Interfaces](Category-Interfaces), and [Generics](Category-Generics) for constraints.

---

[Home](Home) · [Keyword Index](Keyword-Index)
