# Platform detection

A program that runs on Windows, Linux and macOS sometimes has to do things
differently on each: a path separator, the name of an environment variable, a
system call that exists on only one of them. The compiler predefines a symbol
for the platform it is building for, and conditional compilation picks the
code for it.

```tiko
{{#include ../../examples/preprocessor/platform.tiko}}
```

This is the one kind of program whose output *should* differ between
targets.

**Output on windows-x86_64**

```text
{{#include ../../examples/preprocessor/platform.windows-x86_64.out}}
```

**Output on linux-x86_64**

```text
{{#include ../../examples/preprocessor/platform.linux-x86_64.out}}
```

**Output on linux-arm64**

```text
{{#include ../../examples/preprocessor/platform.linux-arm64.out}}
```

**Output on macos-arm64**

```text
{{#include ../../examples/preprocessor/platform.macos-arm64.out}}
```

| Symbol | Defined when building for |
|---|---|
| `__FB_WIN32__` | Windows (the name is historical: it is defined for 64-bit Windows) |
| `__FB_LINUX__` | Linux |
| `__FB_DARWIN__` | macOS |
| `__FB_UNIX__` | Linux, macOS, and other Unix-like systems |
| `__FB_ARM__` | arm64: `linux-arm64` and `macos-arm64` |
| `__FB_64BIT__` | every 64-bit target, which today is every target |
| `__TIKO_COMPILER__` | always, by tiko |

The `#else` branch ends in `#error`, so a build for any other platform stops
with a clear message instead of failing later on a constant that was never
declared. A branch for the platform you are not building on is never
compiled there, so a typo in it goes unnoticed until someone builds for that
platform: build every target you claim to support.

Test platform symbols with `#ifdef` or `defined( )`, never by value: on the
other platform the name does not exist at all.

### Activities

1. Add a `const` for the end-of-line sequence each platform uses in text
   files, and print its length.
2. Build with `-target linux-x86_64` on Windows using `-c`, which compiles
   without linking, and check that the Linux branch compiles.
