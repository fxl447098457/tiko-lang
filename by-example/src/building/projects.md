# Projects

Command lines grow with a program: every file, every option and the output's
name typed again for each build. A **project** writes them down once, in a
`tiko.toml`, and `tiko build` reads it.

```toml
{{#include ../../examples/building/greeter/tiko.toml}}
```

```tiko
{{#include ../../examples/building/greeter/main.tiko}}
```

```tiko
{{#include ../../examples/building/greeter/text/text.tiko}}
```

`tiko run -- tiko`, in the project's directory:

**Output**

```text
{{#include ../../examples/building/greeter/main.out}}
```

- **`[target.greeter]`** declares a **target**: something the project builds,
  here an executable called `greeter`, whose main file is `main.tiko`.
- **`tiko build`**, run in the directory that holds `tiko.toml`, builds every
  target it declares. It takes no file names and no `-o`: the program is
  written to `out/debug/greeter.exe` on Windows and `out/debug/greeter` on
  Linux and macOS. `tiko build greeter` builds the one target by name.
- **`[target.greeter.defines]`** passes `TIMES` as though `-d TIMES=2` had been
  typed, which is why the greeting appears twice.
- **`tiko run`** builds the project's executable and runs it. Everything after
  `--` goes to the program, so `tiko run -- tiko` greets `tiko`; without it,
  the program greets `world`.

`tiko build` remembers what it compiled. A second build with nothing changed
compiles nothing and does not even link; `tiko build -v` says so:

```text
module greeter.text: hit
unit main.tiko: hit
link: out/debug/greeter.exe is up to date
```

| Command | Does |
|---|---|
| `tiko build [target]` | builds the targets, into `out/<profile>/` |
| `tiko run [target] [-- args]` | builds one executable target and runs it |
| `tiko check` | reports every error and warning a build would, and writes nothing |
| `tiko clean` | removes what `tiko build` wrote |

A target takes more keys: `sources` for further files, `kind = "lib"` for a
static library, `options` for compiler options, `libs` and `libpaths` for
libraries to link. Every path in `tiko.toml` is relative to the `tiko.toml`
itself, so the project builds the same from any directory. A project that
depends on packages of modules lists them under `[dependencies]`, as the
[Packages](../modules/packages.md) page shows.

### Activities

1. Change `TIMES` to `3` in `tiko.toml` and run the project again.
2. Run `tiko check` after introducing a typo in `main.tiko`, and confirm that
   no program was written.
