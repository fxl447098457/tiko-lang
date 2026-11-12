# Options in the source

A program that needs particular options to build correctly should not depend
on someone remembering to type them. `#cmdline` writes them in the source, so
the file alone says how it is built:

```tiko
{{#include ../../examples/building/buildinfo.tiko}}
```

**Output**

```text
{{#include ../../examples/building/buildinfo.out}}
```

This is the same program as on the [previous page](index.md), with one line
added. When the compiler meets `#cmdline`, it starts the compile again with
those options added, so `tiko buildinfo.tiko` builds a checked, optimised,
thread-safe program. Every example on this site that needs an option carries
it this way.

- **The source wins.** An option in `#cmdline` takes precedence over the same
  option on the command line.
- **Only the first file counts.** `#cmdline` in any other source file named on
  the command line is warning `TKO0334` and is ignored.

The program can name its own output with `-x`, which takes the file name
exactly as written:

```tiko
{{#include ../../examples/building/named.tiko}}
```

**Output** (of `renamed.exe`)

```text
{{#include ../../examples/building/named.out}}
```

`tiko named.tiko` writes `renamed.exe`, and so does
`tiko named.tiko -o other.exe`: `-x` wins over `-o`, and the source wins over
the command line. Like `-o`, `-x` uses the name exactly as written, so give
the extension yourself; a program for Linux or macOS usually has none.

### Activities

1. Add `-g` to `buildinfo.tiko`'s `#cmdline` and predict the new output.
2. Build `buildinfo.tiko` with `-O0` on the command line. Which level does the
   program report?
