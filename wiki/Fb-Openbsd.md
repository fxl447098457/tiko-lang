[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_OPENBSD__**

# __FB_OPENBSD__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_OPENBSD__
```

## Description

Define without a value created at compile time in the OpenBSD version of the compiler, or when the *[-target openbsd](Compiler-Option-Target)* command line option is used. It can be used to compile parts of the program only if the target is OpenBSD.

## Remarks

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_LINUX__`](Fb-Linux)
- [`__FB_DARWIN__`](Fb-Darwin)
- [`__FB_WIN32__`](Fb-Win32)
- [`__FB_UNIX__`](Fb-Unix)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_OPENBSD__

  '...instructions only for OpenBSD...

#else

  '...instructions not for OpenBSD...

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
