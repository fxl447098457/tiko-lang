# Partial types across files

A module can be several files, and a [partial type](../custom-types/partial.md)
can have a part in each. This is how generated code and hand-written code share
one type: the tool owns one file and you own the other, so regenerating never
touches your work.

```text
partial.tiko
panel/
    panel.gen.tiko
    panel.tiko
```

The file a tool writes:

```tiko
{{#include ../../examples/modules/panel/panel.gen.tiko}}
```

The file you write:

```tiko
{{#include ../../examples/modules/panel/panel.tiko}}
```

A program using the module sees one type:

```tiko
{{#include ../../examples/modules/partial.tiko}}
```

**Output**

```text
{{#include ../../examples/modules/partial.out}}
```

The generated part declares `Refresh_Click`, and your file gives it a body.
That body uses `Title` from the tool's part and `Count` from yours, with no
qualification, because they are members of the same type.

Only the generated part says `public`. That is enough: `public` on any part
makes the whole type public, and only `public` on one part with `private` on
another is an error.

A module's files are read in sorted order of their names, so `panel.gen.tiko`
comes before `panel.tiko` and its fields come first in the layout.

### Activities

1. Add a method to the part in `panel.tiko` that uses `Title`, and call it from
   `partial.tiko`.
2. Declare `Count` in `panel.gen.tiko` too. Which file does the error name?
3. Print `sizeof( panel.Board )`, then move `Count` into the generated part.
   Does the size change?
