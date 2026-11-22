[Home](Home) › **Compiler Option: -norpath**

# Compiler Option: -norpath

> **In tiko:** no `$ORIGIN` run path on a linux-x86_64 or linux-arm64 link, and no `@loader_path` run path on a macos-arm64 link.

## Syntax

`-norpath`

## Description

A linux-x86_64 or linux-arm64 program that links a shared library from `#foreignlib` -- a `.so` file, as a [vendor package](Vendor-Packages) linked `dynamic` does -- gets a run path of `$ORIGIN`, so the library beside the program is the one it loads. `-norpath` leaves the run path out; the program then finds the library only where the system's loader looks, or through `LD_LIBRARY_PATH`. A program that links no such file has no run path either way, and windows-x86_64 has none to give: Windows looks beside the program first. A macos-arm64 program that links a `.dylib` file the same way gets the run path `@loader_path`, and `-norpath` leaves that out too.

### See also

- [Vendor Packages](Vendor-Packages)
- [Compiler Option: -Wl](Compiler-Option-Wl)
