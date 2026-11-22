[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **Intrinsic Defines**

# Intrinsic Defines

Preprocessor symbols defined by the compiler.

Description

Intrinsic defines are set by the compiler and may be used as any other defined symbol. Intrinsic defines often convey information about the state of the compiler, either in general or at a specific point in the compilation process. Most intrinsic defines are associated with a value.

**Platform Information**

Defines that provide information on the system.

**Version Information**

Defines that provide information on the compiler version being used.

**Command-line switches**

Defines that provide information with the command-line switches used with the compiler.

**Environment Information**

Defines that provide information about the operating system environment.

**Context-specific Information**

Defines that provide context information about the compilation process.

**Basic-macros**

Built-in basic-macros.

**Constants**

Built-in constants.

***Platform Information***

**[\_\_FB_WIN32\_\_](Fb-Win32)**

Defined if compiling for Windows.

**[\_\_FB_LINUX\_\_](Fb-Linux)**

Defined if compiling for Linux.

**[\_\_FB_DOS\_\_](Fb-Dos)**

Defined if compiling for DOS.

**[\_\_FB_CYGWIN\_\_](Fb-Cygwin)**

Defined if compiling for Cygwin.

**[\_\_FB_FREEBSD\_\_](Fb-Freebsd)**

Defined if compiling for FreeBSD.

**[\_\_FB_NETBSD\_\_](Fb-Netbsd)**

Defined if compiling for NetBSD.

**[\_\_FB_OPENBSD\_\_](Fb-Openbsd)**

Defined if compiling for OpenBSD.

**[\_\_FB_DARWIN\_\_](Fb-Darwin)**

Defined if compiling for Darwin.

**[\_\_FB_XBOX\_\_](Fb-Xbox)**

Defined if compiling for Xbox.

**[\_\_FB_BIGENDIAN\_\_](Fb-Bigendian)**

Defined if compiling on a system using big-endian byte-order.

**[\_\_FB_PCOS\_\_](Fb-Pcos)**

Defined if compiling for a common PC OS (e.g. DOS, Windows, OS/2).

**[\_\_FB_UNIX\_\_](Fb-Unix)**

Defined if compiling for a Unix-like OS.

**[\_\_FB_64BIT\_\_](Fb-64bit)**

Defined if compiling for a 64bit target.

**[\_\_FB_ARM\_\_](Fb-Arm)**

Defined if compiling for the ARM architecture.

**[\_\_FB_PPC\_\_](Fb-Ppc)**

Defined if compiling for the PowerPC architecture.

**[\_\_FB_X86\_\_](Fb-X86)**

Defined if compiling for the X86 / X86_64 architecture.

**[\_\_FB_JS\_\_](Fb-Js)**

Defined if compiling for emscripten target.

**[\_\_FB_ANDROID\_\_](Fb-Android)**

Defined if compiling for android target.

***Version Information***

**[\_\_FB_VERSION\_\_](Fb-Version)**

Defined as a string literal of the compiler version.

**[\_\_FB_VER_MAJOR\_\_](Fb-Ver-Major)**

Defined as an integral literal of the compiler major version number.

**[\_\_FB_VER_MINOR\_\_](Fb-Ver-Minor)**

Defined as an integral literal of the compiler minor version number.

**[\_\_FB_VER_PATCH\_\_](Fb-Ver-Patch)**

Defined as an integral literal of the compiler patch number.

**[\_\_FB_MIN_VERSION\_\_](Fb-Min-Version)**

Macro to check for a minimum compiler version.

**[\_\_FB_BUILD_DATE\_\_](Fb-Build-Date)**

Defined as a string literal of the compiler build date in "mm-dd-yyyy" format.

**[\_\_FB_BUILD_DATE_ISO\_\_](Fb-Build-Date-Iso)**

Defined as a string literal of the compiler build date in "yyyy-mm-dd" format.

**[\_\_FB_SIGNATURE\_\_](Fb-Signature)**

Defined as a string literal of the compiler signature.

**[\_\_FB_BUILD_SHA1\_\_](Fb-Build-Sha1)**

Defined as a string literal of the compiler's source revision sha-1.

**[\_\_FB_BUILD_FORK_ID\_\_](Fb-Build-Fork-Id)**

Defined as a string literal of the custom defined project fork identifier name.

***Command-line switches***

**[\_\_FB_ASM\_\_](Fb-Asm)**

Defined to either `"intel"` or `"att"` depending on [-asm](Compiler-Option-Asm).

**[\_\_FB_BACKEND\_\_](Fb-Backend)**

Defined to either `"gas"` or `"gcc"` depending on [-gen](Compiler-Option-Gen).

**[\_\_FB_GCC\_\_](Fb-Gcc)**

True (`-1`) if -gen gcc is used, false (`0`) otherwise.

**[\_\_FB_OPTIMIZE\_\_](Fb-Optimize)**

Defined to the optimization level depending on [-O](Compiler-Option-O-2).

**[\_\_FB_GUI\_\_](Fb-Gui)**

True (`-1`) if the `"-s gui"` switch was used, false (`0`) otherwise.

**[\_\_FB_MAIN\_\_](Fb-Main)**

Defined if compiling a module with an entry point.

**\_\_FB_DEBUG\_\_**

True (`-1`) if the `"-g"` switch was used, false (`0`) otherwise.

**[\_\_FB_ERR\_\_](Fb-Err)**

Zero (`0`) if neither the `"-e"`, `"-ex"` or `"-exx"` switches were used.

**[\_\_FB_FPMODE\_\_](Fb-Fpmode)**

Defined as `"fast"` if compiling for fast SSE math, `"precise"` otherwise.

**[\_\_FB_FPU\_\_](Fb-Fpu)**

Defined as `"sse"` if compiling for SSE floating point unit, or `"x87"` for normal x87 floating-point unit.

**[\_\_FB_LANG\_\_](Fb-Lang)**

Defined to a string literal of the `"-lang"` dialect used.

**[\_\_FB_MT\_\_](Fb-Mt)**

True (`-1`) if the `"-mt"` switch was used, false (`0`) otherwise.

**[\_\_FB_OUT_DLL\_\_](Fb-Out-Dll)**

True (`-1`) in a module being compiled and linked into a shared library, false (`0`) otherwise.

**[\_\_FB_OUT_EXE\_\_](Fb-Out-Exe)**

True (`-1`) in a module being compiled and linked into an executable, false (`0`) otherwise.

**[\_\_FB_OUT_LIB\_\_](Fb-Out-Lib)**

True (`-1`) in a module being compiled and linked into a static library, zero (`0`) otherwise.

**[\_\_FB_OUT_OBJ\_\_](Fb-Out-Obj)**

True (`-1`) in a module being compiled only, zero (`0`) otherwise.

**[\_\_FB_PROFILE\_\_](Fb-Profile)**

Set to an integer to indicate the profiling method.

**[\_\_FB_SSE\_\_](Fb-Sse)**

Defined if compiling for SSE floating point unit.

**[\_\_FB_VECTORIZE\_\_](Fb-Vectorize)**

Defined as the level of automatic vectorization (`0` to `2`)

***Environment Information***

**[\_\_FB_ARGC\_\_](Fb-Argc)**

Defined as an integer literal of the number of command-line arguments passed to the program.

**[\_\_FB_ARGV\_\_](Fb-Argv)**

Defined as a `ZString Ptr Ptr` to the command line arguments passed to the program.

**[\_\_DATE\_\_](Date-Iso)**

Defined as a string literal of the compilation date in "mm-dd-yyyy" format.

**[\_\_DATE_ISO\_\_](procedures-Date)**

Defined as a string literal of the compilation date in "yyyy-mm-dd" format.

**[\_\_TIME\_\_](procedures-Time)**

Defined as a string literal of the compilation time.

**[\_\_PATH\_\_](Path)**

Defined as a string literal of the absolute path of the module.

***Context-specific Information***

**[\_\_FILE\_\_](File) and [\_\_FILE_NQ\_\_](File-Nq)**

Defined as the name of the module.

**[\_\_FUNCTION\_\_](Function) and [\_\_FUNCTION_NQ\_\_](Function-Nq)**

Defined as the name of the procedure where it's used.

**[\_\_LINE\_\_](Line)**

Defined as an integer literal of the line of the module where it's used.

**[\_\_CALLER_LINE\_\_ and \_\_CALLER_FILE\_\_](Caller-Line)**

tiko's own. As a parameter's default, the line and file of the statement that calls the procedure.

**[\_\_FB_OPTION_BYVAL\_\_](Fb-Option-Byval)**

True (`-1`) if parameters are declared by value by default, zero (`0`) otherwise.

**[\_\_FB_OPTION_DYNAMIC\_\_](Fb-Option-Dynamic)**

True (`-1`) if all arrays are variable-length, zero (`0`) otherwise.

**[\_\_FB_OPTION_ESCAPE\_\_](Fb-Option-Escape)**

True (`-1`) if string literals are processed for escape sequences, zero (`0`) otherwise.

**[\_\_FB_OPTION_GOSUB\_\_](Fb-Option-Gosub)**

True (`-1`) if gosub support is enabled, zero (`0`) otherwise.

**[\_\_FB_OPTION_EXPLICIT\_\_](Fb-Option-Explicit)**

True (`-1`) if variables and objects need to be explicitly declared, zero (`0`) otherwise.

**[\_\_FB_OPTION_PRIVATE\_\_](Fb-Option-Private)**

True (`-1`) if all procedures are private by default, zero (`0`) otherwise.

**[\_\_FB_OPTION_PROFILE\_\_](Fb-Option-Profile)**

True (`-1`) if profiling code is generated, zero (`0`) otherwise.

***Basic-macros***

**[\_\_FB_ARG_COUNT\_\_](Fb-Arg-Count)**

Counts the number of arguments in an argument list.

**[\_\_FB_ARG_EXTRACT\_\_](Fb-Arg-Extract)**

Returns nth argument from an argument list.

**[\_\_FB_ARG_LEFTOF\_\_](Fb-Arg-Leftof)**

Returns left token based on separator.

**[\_\_Fb_Arg_Listexpand\_\_](Fb-Arg-Listexpand)**

Expands a macro one or more time on an argument list

**[\_\_FB_ARG_RIGHTOF\_\_](Fb-Arg-Rightof)**

Returns right token based on separator.

**[\_\_FB_EVAL\_\_](Fb-Eval)**

Evaluates an argument (expression) at compile time.

**[\_\_FB_IIF\_\_](Fb-Iif)**

Returns an expression depending on the result of a comparison expression evaluated at compile time.

**[\_\_FB_JOIN\_\_](Fb-Join)**

Joins two token arguments together as one.

**[\_\_Fb_Query_Symbol\_\_](Fb-Query-Symbol)**

Queries the compiler's symbol internals.

**[\_\_FB_QUOTE\_\_](Fb-Quote)**

Converts the argument to a string.

**[\_\_FB_UNIQUEID\_\_](Fb-Uniqueid)**

Gets the identifier at the top of a stack.

**[\_\_FB_UNIQUEID_POP\_\_](Fb-Uniqueid-Pop)**

Pops an identifier off of a stack.

**[\_\_FB_UNIQUEID_PUSH\_\_](Fb-Uniqueid-Push)**

Pushes a new unique identifier on to a stack.

**[\_\_FB_UNQUOTE\_\_](Fb-Unquote)**

Takes a literal string and converts it back to tokens.

***Constants***

**[False](False) and [True](True)**

Intrinsic constants for the Boolean data type.

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
