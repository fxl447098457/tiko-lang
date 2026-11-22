[Home](Home) › **Compiler Option: -Wl**

# Compiler Option: -Wl

> **In tiko:** the value is split at commas, each piece reaches the linker as one argument after everything else on the link line, and repeated `-Wl` options accumulate. It works in `tiko.toml`'s `options`, and in `#cmdline` for linker options that change only the program (`-rpath`, `-z`, `-L`, `-l`, `-s`, `--as-needed`, `/STACK`, `/SUBSYSTEM` and the like; `-plugin`, an `@file`, `/OUT` and other options are `TKO0178` there). tiko links through clang, so each piece is passed as `-Xlinker <piece>`, and the linker is `lld-link` on windows-x86_64 (`-Wl /STACK:8388608`) and the system linker on linux-x86_64 (`-Wl -rpath,/opt/lib`; quote a `$` in a shell), and Apple's linker on macos-arm64. A program that links a shared library from `#foreignlib` already gets `-rpath $ORIGIN` (`@loader_path` on macOS), so it finds the library beside itself; an `-rpath` given here replaces it, and [`-norpath`](Compiler-Option-Norpath) turns it off. See [Using C Libraries](Using-C-Libraries-Tutorial).

Pass options to linker

Syntax

`-Wl < options >`

Parameters

`options`

Additional options to pass to the linker.

Description

The `-Wl` compiler option passes additional options to LD, the linker. Options must be separated by commas only. The -Wl compiler option may be specified multiple times on the command line.

See also

- [Compiler Option: -Wa](Compiler-Option-Wa)
- [Compiler Option: -Wc](Compiler-Option-Wc)
- [Using the Command Line](Quick-Start#compile-a-program)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
