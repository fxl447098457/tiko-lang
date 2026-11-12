# tiko by Example

tiko is a compiled, statically typed language for building fast, self-contained
programs on Windows, Linux and macOS. This site teaches it the way you learn most
things in practice: by reading short, complete programs and watching what they
do.

Every page is built around one example. The example is a whole program, not a
fragment, and the text under it is the output that program printed. Nothing
here was typed in by hand: each example on the site is compiled and run on
**windows-x86_64**, **linux-x86_64** and **macos-arm64** before a page is published, and the
output you see is the output the program produced.

## How to run an example

Save the program as `example.tiko` and compile it:

```bash
tiko example.tiko
```

The program takes the source file's name: `example` on Linux and macOS, `example.exe` on
Windows. Run it as `./example` or `example.exe`. Where an example
needs a compiler flag, the flag is written inside the program itself, as a
`#cmdline` line near the top, so the file alone reproduces the result.

## How this site is organised

The sections start with the smallest things you need to write a program —
printing, values, variables and control flow — and move through procedures,
types and objects to the standard library, concurrency and calling C. Each
section opens with a short overview page, and each page ends with a few
**activities**: small changes to try, so the example becomes yours.

If you want the longer explanation of why tiko works the way it does, read
[*The tiko Programming Language*](https://tiko-lang.net/book/), the book this
site accompanies.

## Where to look things up

An example shows one way to use a feature. The full definition of every
keyword, option and library function is in the **tiko wiki**,
[github.com/PaulSquires/tiko-lang/wiki](https://github.com/PaulSquires/tiko-lang/wiki),
the language's reference documentation:

- [**Feature Index**](https://github.com/PaulSquires/tiko-lang/wiki/Feature-Index)
  — every language feature and library, one line each, with a link to its
  reference page.
- [**Function Finder**](https://github.com/PaulSquires/tiko-lang/wiki/Function-Finder)
  — every function, grouped by what you want to do, with one line on what each
  one does.
- [**Keyword Index**](https://github.com/PaulSquires/tiko-lang/wiki/Keyword-Index)
  — every keyword, statement and operator, A to Z.
- [**Quick Start**](https://github.com/PaulSquires/tiko-lang/wiki/Quick-Start)
  — building a toolchain and compiling your first program.

When an example uses a function you have not met, the Function Finder is the
fastest way to its page.
