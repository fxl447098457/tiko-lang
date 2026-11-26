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
| `TIKO_OS_WINDOWS` | Windows |
| `TIKO_OS_LINUX` | Linux |
| `TIKO_OS_MACOS` | macOS |
| `TIKO_ARCH_X86_64` | x86-64: `windows-x86_64` and `linux-x86_64` |
| `TIKO_ARCH_ARM64` | arm64: `linux-arm64` and `macos-arm64` |
| `__FB_64BIT__` | every 64-bit target, which today is every target |
| `__TIKO_COMPILER__` | always, by tiko |

tiko has no single name for "a Unix-like system": test
`defined( TIKO_OS_LINUX ) orelse defined( TIKO_OS_MACOS )`, as the example
does. The older `__FB_` spellings (`__FB_WIN32__`, `__FB_LINUX__`,
`__FB_DARWIN__`, `__FB_UNIX__`, `__FB_ARM__`) are defined too, for existing
headers; tiko code uses the `TIKO_` names.

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
