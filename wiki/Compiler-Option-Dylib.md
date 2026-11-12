[Home](Home) › **Compiler Option: -dylib**

# Compiler Option: -dylib

Create a DLL and import library

Syntax

`-dylib`

Description

The `-dylib` compiler option creates a dynamic link library. This creates a DLL under Windows (including the import library), creates a .so under Linux, a .dylib under macOS, and a DXE under DOS.

 **Note:** Same as `-dll`.

 The intrinsic macro [`__FB_OUT_DLL__`](Fb-Out-Dll) is set to non-zero (-1) if the `-dll` option was specified, and set to zero (0) otherwise.

Platform Differences

- See [Compiler Option: -dll](Compiler-Option-Dll)

See also

- [`__FB_OUT_DLL__`](Fb-Out-Dll)
- [Using the Command Line](Quick-Start#compile-a-program)
- [Compiler Option: -dll](Compiler-Option-Dll)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
