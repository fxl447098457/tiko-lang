# Static libraries

A **static library** packs compiled code into one file that other programs
link. The linker copies in the parts a program uses, so the program runs with
nothing beside it.

```tiko
{{#include ../../examples/building/static/mathlib.tiko}}
```

```tiko
{{#include ../../examples/building/static/uselib.tiko}}
```

Built with:

```bash
tiko -lib mathlib.tiko
tiko uselib.tiko
```

**Output**

```text
{{#include ../../examples/building/static/uselib.out}}
```

- **`tiko -lib mathlib.tiko`** compiles the file and writes `libmathlib.a`,
  on every target.
- **`#inclib "mathlib"`** tells the linker to use it. The name has no `lib`
  prefix and no extension. `-l mathlib` on the command line does the same.
- **The linker searched the current directory.** `-p dir` on the command line,
  or `#libpath "dir"` in the source, adds other places to look.

The program declares the two functions itself. A library meant for others
ships a header with those declarations, which every user includes. The
parentheses in `Lcm` matter: `\` binds more loosely than `*`, so
`a \ Gcd( a, b ) * b` would divide by the product.

### Activities

1. Move the two `declare` lines into `mathlib.ti` and `#include` it.
2. Add a `Factorial` function to the library and use it from the program.
