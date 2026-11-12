# Targets

tiko builds for three targets, `windows-x86_64`, `linux-x86_64` and
`macos-arm64`. Each is the default on its own platform, and `-target` names one
explicitly. All three are 64-bit, two on x86-64 and one on Apple Silicon, and
tiko's types have the same sizes on each:

```tiko
{{#include ../../examples/building/targets.tiko}}
```

**Output**

```text
{{#include ../../examples/building/targets.out}}
```

`integer` is the size of a pointer, 8 bytes on all three. `long` is 4 bytes on
every target, even though the C type of that name is 8 bytes on Linux and macOS: a program
that uses tiko's types gets the same layout everywhere. Where a program must
differ between the platforms, [platform detection](../preprocessor/platform.md)
chooses the code for each.

| Target | Builds | Links against |
|---|---|---|
| `windows-x86_64` | a Windows executable | Microsoft's Universal C Runtime |
| `linux-x86_64` | a Linux executable | the system's C library |
| `macos-arm64` | a macOS executable, for Apple Silicon | the system's C library, linked by Apple's linker with the macOS SDK |

### Cross-compiling

On Windows, `-target linux-x86_64` with `-c` compiles a file for Linux, and
writes a Linux object file. That is a quick way to check that the Linux
branches of a program compile without leaving Windows:

```text
> tiko -c -target linux-x86_64 platform.tiko -o platform.o
> file platform.o
platform.o: ELF 64-bit LSB relocatable, x86-64, version 1 (SYSV), not stripped
```

Linking needs the target system's own C library and start-up files, which a
Windows machine does not have. Without `-c`, the link stops with the linker's
errors about the files it could not find, and `TKO0116: link failed`. Build
the finished program on each platform you ship for, or on a Linux system
reached from Windows.

`-target macos-arm64` with `-c` works the same way and writes a Mach-O object. A
program for it links only on a Mac, where Apple's linker and SDK are.

### Activities

1. Add a `type` with an `int32` field and a `float64` field, predict its
   `sizeof`, and print it.
2. Compile `targets.tiko` with `-c -target linux-x86_64` on Windows (or
   `-target windows-x86_64` on Linux) and look at the object file it writes.
