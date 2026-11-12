[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_CYGWIN__**

# __FB_CYGWIN__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_CYGWIN__
```

## Description

Define without a value created at compile time in the Cygwin version of the compiler, or when the *[-target cygwin](Compiler-Option-Target)* command line option is used. It can be used to compile parts of the program only if the target is Cygwin.

## Remarks

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_LINUX__`](Fb-Linux)
- [`__FB_DARWIN__`](Fb-Darwin)
- [`__Fb_Win32_`](Fb-Win32)
- [`__FB_UNIX__`](Fb-Unix)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_CYGWIN__

  '...instructions only for Cygwin...

#else

  '...instructions not for Cygwin...

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
