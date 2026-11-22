[Home](Home) › [All Categories](Categories) › **Foreign Library Linking**

# Foreign Library Linking

> 📘 **Also in this category:** [#foreignlib Tutorial](modern-Foreignlib-tutorial) · [Using C Libraries Tutorial](Using-C-Libraries-Tutorial): SQLite, raylib, GLFW and SDL3, step by step

## Syntax

```freebasic
#foreignlib name (static|dynamic) "spec" [, "spec" ...]
```

## Description

Binds `name` to a set of libraries and adds them to the linking process.

Unlike [`#inclib`](Inclib), a `#foreignlib` spec that is not `"system:..."` is a
library **file**, resolved **relative to the source file containing the
directive** — not relative to the compiler's working directory. The target
variant is selected by filename convention, and whether the library is linked
statically or dynamically must be stated.

The bound name may then be used in place of a string literal in a
[`Lib`](Lib) clause.

## Parameters

| | |
| --- | --- |
| `name` | An identifier, visible to the end of the compilation unit and inherited by including files |
| `static` / `dynamic` | Required. Constrains which file extensions are eligible; a file of the other kind is an error, never a fallback |
| `"spec"` | `"system:foo"` passes `foo` to the linker as `-lfoo`; `"framework:Foo"` links the macOS framework `Foo` (`-framework Foo`) on macos-arm64 and is ignored on every other target; anything else is a library base name resolved relative to this file, or an absolute path |

## Resolution

Target tags and an extension are appended to the base name, most specific
first: `<base>_<os>_<arch><ext>`, `<base>_<os><ext>`, `<base>_<arch><ext>`,
`<base><ext>`.

`<os>` is the target's: `windows`, `linux` or `macos`. `<arch>` is `x86_64`
or `arm64`. A library built for macos-arm64 is therefore `<base>_macos_arm64`, and one for
linux-arm64 `<base>_linux_arm64`.

`<ext>` is `.a`/`.lib` for `static`; `.dll.a`/`.lib`/`.dll`, `.dylib` or `.so`
for `dynamic`, by target.

No `lib` prefix is added or stripped — the base name is used verbatim, and the
resolved file is passed to the linker by exact filename. When no candidate
matches, the error lists every path that was tried.

## Remarks

- **A `.dll` with no import library** (tiko, windows-x86_64). When a `dynamic` spec
  matches only a `.dll`, the link reads the DLL's export table, writes a `.def` naming the DLL as
  its export directory names it (the name it was built as, not the file's), and makes the import
  library with `llvm-dlltool` from clang's LLVM directory; it is deleted with the objects. An
  export in a section with no code is written `DATA`. A file that is not a 64-bit x86-64 DLL is
  `TKO0172`. A `.dll.a` or `.lib` with a matching name is found first and used as it is.
- A `#foreignlib` contributes its libraries to the link whether or not any
  declaration names it, exactly as [`#inclib`](Inclib) does.
- **`static` / `dynamic` is ignored for a `"system:"` spec.** The resolver hands
  the bare name to the linker and never consults `isstatic`, so
  `#foreignlib X dynamic "system:sqlite3"` emits `-lsqlite3` and the linker takes
  whatever it finds first — verified to link a **static** archive, silently,
  while saying `dynamic`. The keyword constrains only a **file** spec, where a
  file of the other kind is an error. See
  [#cinclude](modern-Cinclude#system-does-not-give-you-a-dynamic-link) for the
  detail and for why a real guarantee is not simply a matter of adding a flag.
- Declaring the same name twice with an identical set is allowed; with a
  different set it is an error.
- The resolved library and its absolute directory are recorded in the object
  file, so separately compiled modules carry their own link recipe.

## Working with `#cinclude`

Binding to a C library is **two** jobs. `#foreignlib` does the linkage half — *where is the code?* — and [`#cinclude`](modern-Cinclude) does the header half: *what are these things?* It hands the library's own `.h` to Clang and turns it into tiko declarations for the target being built, so the `Declare` above is not written by hand at all.

Together they let a binding ship **entirely inside your own source tree**:

```freebasic
'' mylib/mylib.ti
#pragma once

#cinclude once "mylib.h"                    '' declarations, from the real header
#foreignlib MYLIB dynamic "vendor/mylib"    '' the library, per target
```

with no `Declare` and no `#ifdef` anywhere in the using code.

> ℹ️ **How each finds its file.** `#foreignlib` resolves its library relative to the **file containing the directive**, which is the whole reason it exists. `#cinclude` looks for a quoted header under the **working directory** first, then **beside the file containing the directive**, then in each `-cinclude` directory. So `mylib.ti` can name `"vendor/mylib.h"` and build from anywhere. A header that includes others with angle brackets still needs its include directory given with `-cinclude`. Because the working directory is searched first, a same-named header there wins. See [Using C Libraries](Using-C-Libraries-Tutorial).

### See also

- [`#cinclude`](modern-Cinclude) — the header half of the same job
- [`#inclib`](Inclib)
- [`#libpath`](Libpath)
- [Compiler Option: -l](Compiler-Option-L)
- [Compiler Option: -p](Compiler-Option-P)

## Examples

```freebasic
'' A binding that ships its own libraries:
''
''     mylib/mylib.ti
''     mylib/lib/mylib_windows_x86_64.dll.a
''     mylib/lib/mylib_linux_x86_64.so

#foreignlib MYLIB dynamic "lib/mylib"

declare function mylib_add cdecl lib MYLIB alias "mylib_add" _
    ( byval a as int32, byval b as int32 ) as int32
```

```freebasic
'' Several libraries under one name, in link order:

#foreignlib RAYLIB static "vendor/raylib", _
            "system:winmm", "system:gdi32", "system:user32"
```

## Pages in this category

[#foreignlib](modern-Foreignlib) · [#foreignlib Tutorial](modern-Foreignlib-tutorial) · [Using C Libraries Tutorial](Using-C-Libraries-Tutorial)

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
