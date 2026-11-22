# Strings

Text in tiko is a `ustring`. It grows as you add to it, it holds any
Unicode text, and it is stored the same way on every target, so a program
that handles text on one machine handles it identically on another.

```tiko
{{#include ../../examples/strings/strings.tiko}}
```

**Output**

```text
{{#include ../../examples/strings/strings.out}}
```

`len` gives the length, and it costs the same however long the string is:
the length is stored, not counted.

`&` joins two values into a new string, converting a number to text when
one side is a number, so `"I have " & apples & " apples"` needs no
conversion call. `&=` appends to a string that already exists.

Strings compare character by character, so `"apple" < "banana"`, and the
comparison is case-sensitive: `"Tiko"` and `"tiko"` are different strings.
A `ustring` you have not assigned is empty, not missing; it equals `""`.

Assignment copies. Changing `twin` afterwards leaves `greeting` alone, so you
can pass and store strings without worrying about who else holds them.

The pages in this section:

- [Built-in functions](intrinsics.md): `left`, `mid`, `instr`, `trim` and the
  rest that come with the language.
- [The strings module](library.md) and [Split and Join](split.md): what
  `std/strings` adds.
- [Slices](slices.md) and [Slices and lifetime](slicelife.md): naming part
  of a string without copying it.
- [Block strings](block.md) and [Escape sequences](escapes.md): writing text
  in the source.
- [Unicode](unicode.md): what `len` counts.
- [Building strings](building.md): assembling text from many pieces.
- [Base64, hex and URLs](encodings.md): bytes as text, and text inside URLs.
- [Writing CSV](csv.md): quoting fields so a CSV reader gets them back.

Laying out values with `strings.Format` is covered in
[Formatted print](../hello/format.md), and making your own types printable in
[Display](../hello/display.md).

Finding text by its shape rather than its exact characters, such as any date
or any amount, takes a regular expression: see
[Regular expressions](../libraries/pcre2.md), which uses `vendor/pcre2`.

### Activities

1. Print your name and its length on one line.
2. Compare `"Zebra"` and `"apple"` with `<`. Then compare them again after
   passing both through `lcase( )`, from the next page.
