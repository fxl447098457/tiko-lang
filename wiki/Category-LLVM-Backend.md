[Home](Home) › [All Categories](Categories) › **LLVM Backend**

# LLVM Backend

tiko compiles each module to **textual LLVM IR** and runs `clang -c` on it to make an object. clang then drives the link. There is no other code generator and no fallback. So there is no `-gen` option, and `tiko -gen llvm hello.tiko` is refused:

```
tiko-lang: error TKO0100: unknown option '-gen'
```

## What it is

The IR comes from tiko's own pipeline:

1. the frontend builds a typed AST;
2. lowering turns it into **MIR**, a typed IR over basic blocks with its own verifier;
3. an **ABI pass** rewrites procedure signatures and calls for the target's C calling convention, one classifier each for Win64, SysV AMD64 and Apple's AAPCS64;
4. the emitter writes the LLVM IR.

`--emit-ir` writes that IR and stops: to standard output, or with `-o x.ll` to that file. `--emit-asm` runs `clang -S` on it and stops, writing `x.s`, or `<source>.s` with no `-o`. With several modules and one `-o`, each is `<name>.<n>.ll` (or `.s`). `-v` echoes every clang invocation, and `--keep-temps` keeps the `.ll` files.

Each target has its own triple:

| Target | clang triple |
| --- | --- |
| `windows-x86_64` (default on Windows) | `x86_64-pc-windows-msvc` |
| `linux-x86_64` (default on Linux) | `x86_64-pc-linux-gnu` |
| `macos-arm64` (default on macOS) | `arm64-apple-macosx13.0` |

## What you need: clang

**clang 18 or newer, installed by you.** Nothing is bundled.

tiko runs whatever `TIKO_CLANG` names. Without it, tiko runs `C:\Program Files\LLVM\bin\clang.exe` on Windows, `/usr/bin/clang` on Linux and Homebrew's `/opt/homebrew/opt/llvm/bin/clang` on macOS, and searches `PATH` only when that file is absent. It takes `llvm-ar` and `llvm-rc` from the same directory. The link uses lld; on Linux it falls back to the system `ld` when there is no `ld.lld` beside clang or in `/usr/bin`. On macOS the link uses Apple's linker and the macOS SDK from Xcode's Command Line Tools, and it searches Homebrew's `/opt/homebrew/lib` after your own library paths.

If clang is not there, tiko says so and stops:

```
tiko-lang: error TKO0111: no usable toolchain: clang not found at 'C:/nope/clang.exe' -- set TIKO_CLANG to the clang to use
```

## Inline ASM

Inline `ASM` is **refused**:

```
error TKO0407: inline assembly is not supported; compile that module with fbc
```

An `ASM` block is raw assembler text with direct symbol references. LLVM wants constraint strings and operands, and anything short of refusing it produces plausible-but-wrong code.

## Optimisation and debug information

- **`-O0` to `-O3`** (written joined: `-O2`) are passed through to clang. The corpus programs give the same output at all four levels.
- **`-g`** emits DWARF line tables. gdb breaks, steps and unwinds on both Windows targets and on Linux. Variables are not described yet.

## How it is verified

- **Self-hosting.** tiko compiles itself to a byte-identical fixpoint on windows-x86_64 and linux-x86_64, at `-O0` and `-O2`, and on macos-arm64 at `-O0` (`build/bootstrap.sh`).
- **Codegen coverage.** `build/icescan.sh` compiles all 2,709 corpus files to objects and reports anything the emitter or clang refuses: 21 failures in 12 files at the last run.

---

[Home](Home) · [Keyword Index](Keyword-Index)
