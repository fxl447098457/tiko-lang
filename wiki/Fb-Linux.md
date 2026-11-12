[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_LINUX__**

# __FB_LINUX__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_LINUX__
```

## Description

Define without a value created at compile time when compiling to the Linux target. Default in the Linux hosted version of the compiler, or active when the *[-target linux](Compiler-Option-Target)* command line option is used. It can be used to compile parts of the program only if the target is Linux.

## Remarks

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_DOS__`](Fb-Dos)
- [`__FB_WIN32__`](Fb-Win32)
- [`__FB_UNIX__`](Fb-Unix)
- [`__FB_DARWIN__`](Fb-Darwin)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_LINUX__

  ' ... instructions only for Linux ...

  ' ... #libpath "/usr/X11/lib"

#else

  ' ... instructions not for Linux ...

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
