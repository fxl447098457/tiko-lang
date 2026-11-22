[Home](Home) › **Compiler Option: -target**

# Compiler Option: -target

Set the target platform for cross compilation

Syntax

`-target < platform >`

Parameters

`platform`

The target platform. tiko recognizes four:

| Target | |
| --- | --- |
| `windows-x86_64` | Windows on x86-64; the default on Windows |
| `linux-x86_64` | Linux on x86-64; the default on x86-64 Linux |
| `linux-arm64` | Linux on arm64 (aarch64); the default on arm64 Linux |
| `macos-arm64` | macOS on Apple Silicon; the default on macOS. A program for it links on a Mac, with Apple's linker and SDK |

Any other name is refused with `TKO0103`.

Examples:

Description

The `-target` compiler option can be used to create an executable for a platform which is different from the host on which the source code is being compiled and linked. Appropriate libraries and cross compilation tools (assembler, linker) must be installed for cross compilation to work (also see FB and cross-compiling).

 If `-target <platform>` is given, the compiler will compile programs more or less as if they were compiled on the given platform. This affects which `__FB_*__` operating-system-specific symbol will be pre-defined, the default calling convention, the object and executable file format (e.g. ELF/COFF), the available runtime libraries and functions, etc.

 With a standalone FB setup such as the FB-dos or FB-win32 releases:

With a normal FB setup such as the FB-linux release:

When using triplets they generally have the form os `<arch>-<vendor>-<os>` but can vary a lot between build systems or over time between different versions of a build system or toolchain. The compiler also accepts the form `<arch>-<os>` and is fairly permissive in what will be accepted and typically will not throw an error if at least part of the gnu triplet is recognized

 For more details, see on page [`-buildprefix`](Compiler-Option-Buildprefix), the paragraph: "Detailed behavior if using `-buildprefix`, `-prefix`, `-target` command line options".

Version


See also

- [-arch](Compiler-Option-Arch)
- [-buildprefix](Compiler-Option-Buildprefix)
- [-prefix](Compiler-Option-Prefix)
- [Using the Command Line](Quick-Start#compile-a-program)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
