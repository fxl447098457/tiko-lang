[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_DOS__**

# __FB_DOS__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_DOS__
```

## Description

Define without a value created at compile time if compiling for the DOS target. Default in the DOS hosted version, or active when the *[-target dos](Compiler-Option-Target)* command line option is used. It can be used to compile parts of the program only if the target is DOS. Note: the DOS hosted version cannot compile to other targets than DOS by now.

## Remarks

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_LINUX__`](Fb-Linux)
- [`__FB_DARWIN__`](Fb-Darwin)
- [`__FB_WIN32__`](Fb-Win32)
- [`__FB_PCOS__`](Fb-Pcos)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_DOS__

  ' ... instructions only for DOS ...

  ' ... INT 0x31

#else

  ' ... instructions not for DOS ...

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
