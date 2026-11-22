[Home](Home) › [Smart Pointers](Category-Smart-Pointers) › [SharedPtr and WeakPtr](Category-Smart-Pointers) › **SpCast**

# SpCast

Returns a SharedPtr to a base type that shares ownership with the derived one.

## Syntax

```freebasic
SpCast( of D, B )
```

## Examples

```freebasic
#import "std/memory"
using memory

class Shape
    as int32 id
    declare virtual destructor( )
end class
virtual destructor Shape( ) : end destructor

type Circle extends Shape
end type

dim d as SharedPtr( of Circle ) = MakeShared( of Circle )( )
d.Ref( ).id = 7

'' Both type arguments must be written out: inference reads parameter
'' positions only, and the target type appears in none of them
dim b as SharedPtr( of Shape ) = SpCast( of Circle, Shape )( d )

print b.Ref( ).id            '' 7
print b.UseCount( )          '' 2 -- one object, two handles, shared count

'' THE BASE MUST HAVE A VIRTUAL DESTRUCTOR: the returned handle destroys
'' through `delete cptr( Shape ptr, obj )`, and nothing here can check it.
'' (The type is not called Base because BASE is a tiko keyword.)
```

---

**Library:** [SharedPtr and WeakPtr](Category-Smart-Pointers)  
**Category:** [Smart Pointers](Category-Smart-Pointers)  
**Documented under:** Members
