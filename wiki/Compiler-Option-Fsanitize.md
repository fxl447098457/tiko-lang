[Home](Home) › **Compiler Option: -fsanitize**

# Compiler Option: -fsanitize

> **In tiko:** build the program with AddressSanitizer, which stops it at the first use-after-free, double free, out-of-bounds access or use of a returned local's address, and names the line.

## Syntax

`-fsanitize=address`

`-fsanitize address`

## Description

Every procedure is compiled with clang's AddressSanitizer, and the program is linked with its runtime. Each memory access is checked against shadow memory, freed blocks are held back from reuse, and every frame's locals get a stack of their own. The first bad access stops the program with a report on standard error:

```freebasic
dim p as long ptr = new long
delete p
print *p                    '' stops here
```

```
==9960==ERROR: AddressSanitizer: heap-use-after-free on address 0x116d453a0070 ...
READ of size 4 at 0x116d453a0070 thread T0
    #0 0x7ff6630b1264 in main demo.tiko:3
```

It catches:

| Bug | Report |
|---|---|
| Reading or writing memory after `delete` or `deallocate` | `heap-use-after-free` |
| Freeing a block twice | `attempting double-free` |
| A `ptr` past either end of an `allocate`d block | `heap-buffer-overflow` |
| Using the address of a procedure's local after it returns | `stack-use-after-return` |
| A local array or `type` indexed past its end through a pointer | `stack-buffer-overflow` |

Build with `-g` as well, or the report names procedures and not lines. `tiko build --profile asan` does both: the built-in `asan` profile is `-g -exx -O1 -fsanitize=address`, written to `out/asan/`.

The program exits 1 after a report on Windows and Linux; macOS aborts it (exit 134). It runs more slowly and uses more memory than a plain build, so this is a debugging build, not a release one.

`__TIKO_ASAN__` is defined, as `1`, when the program is built this way.

**Where the runtime comes from.** AddressSanitizer's runtime is clang's, from the LLVM tiko uses:

- **windows-x86_64:** `clang_rt.asan_dynamic-x86_64.dll` and its import library, from LLVM's `lib\clang\<version>\lib\windows`. The DLL is copied beside the program, unless [`-nocopylibs`](Compiler-Option-Nocopylibs). An LLVM without it is `TKO0111`.
- **linux-x86_64, linux-arm64:** clang links `libclang_rt.asan` itself. On Ubuntu it is in the `libclang-rt-<version>-dev` package. (linux-arm64 has not been measured yet.)
- **macos-arm64:** clang links `libclang_rt.asan_osx_dynamic.dylib` and records where it is.
- **win64** (the MinGW target) has no runtime: `TKO0179`.

Only `address` is accepted; anything else is `TKO0106`.

## Remarks

- **tiko's own runtime is not instrumented.** Every allocation still goes through the checked `malloc` and `free`, so a bug in the program's use of memory is caught, but one inside a runtime routine is not.
- **A procedure that divides by a variable on x86-64** holds an inline instruction, and AddressSanitizer does not give it a separate stack: a returned local of that procedure is not caught.
- A different build of the same program: `-fsanitize=address` is part of the module and unit cache keys, so nothing compiled without it is reused.

### Differences from FreeBASIC

- Not in FreeBASIC. `-exx` checks array bounds and null pointers; it does not see freed memory.

### See also

- [Compiler Option: -nocopylibs](Compiler-Option-Nocopylibs)
- [tiko build](Category-Tiko-Build)
