[Home](Home) › **Compiler Option: -exx**

# Compiler Option: -exx

Add error checking with array bounds/dimensions and null-pointer checking, plus stack overflow checking with gas64 backend

Syntax

`-exx`

Description

The `-exx` compiler option adds error checking with array bounds and dimensions, and null-pointer checking (including the procedure pointers), plus stack overflow checking with gas64 backend.

 Use of the `-exx` option automatically implies `-e`, `-ex`, `-earray`, `-earraydims`, `-elocation`, and `-enullptr`, error checking and code generation options.

Version


See also

- [`__FB_ERR__`](Fb-Err)
- [Compiler Option: -e](Compiler-Option-E)
- [Compiler Option: -earray](Compiler-Option-Earray)
- [Compiler Option: -earraydims](Compiler-Option-Earraydims)
- [Compiler Option: -elocation](Compiler-Option-Elocation)
- [Compiler Option: -enullptr](Compiler-Option-Enullptr)
- [Compiler Option: -ex](Compiler-Option-Ex)
- [Compiler Option: -fsanitize](Compiler-Option-Fsanitize)
- [Error Handling](Error-Handling)
- [Using the Command Line](Quick-Start#compile-a-program)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
