# Partial Types

A `type` is normally one block. `partial type` lets you write it in several,
and the compiler combines them into a single type. `partial class` does the
same for a class.

```tiko
{{#include ../../examples/custom-types/partial.tiko}}
```

**Output**

```text
{{#include ../../examples/custom-types/partial.out}}
```

`Point` has the fields from its first block and the method from its second,
and `sizeof( Point )` counts both fields. A part can hold only methods, as
long as the whole type ends up with a field.

`Car`'s first part names no base, and its second part says `inherits Vehicle`.
One part may name the base, and it applies to the whole class. The base's
fields come first in the layout, wherever `inherits` was written.

Every block has to say `partial`. Once a type is partial, an ordinary `type`
of the same name is an error.

`partial` is only a keyword directly before `type` or `class`. Anywhere else
it is an ordinary name you can use for a variable or a procedure.

The usual reason to split a type is that it has two authors, one of them a
tool. [Partial types across files](../modules/partial.md) shows that case.

### Activities

1. Move `declare function Sum( ) as int32` into the first block. What changes
   in the output?
2. Remove `partial` from the second `Point` block and read the error.
3. Add `inherits Vehicle` to the first `Car` block as well. What does the
   compiler say?
