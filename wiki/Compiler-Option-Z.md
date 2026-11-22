[Home](Home) › **Compiler Option: -z**

# Compiler Option: -z

Sets miscellaneous or experimental compiler options.

Syntax

`-z < value >`

Parameters

`value`

Miscellaneous compiler option.

Description

The `-z` compiler option sets miscellaneous, obscure, temporary, or experimental options used by the developers. There is no guarantee that these options will be supported in future versions of the compiler.

 **-z gosub-setjmp**

Specifies that the `setjmp`/`longjmp` implementation of [`GoSub`](Gosub) should be used even when the GAS backend is used. By default, [`GoSub`](Gosub) will be supported in *[-gen gas](Compiler-Option-Gen)* using `CALL`/`RET` assembly instructions and in *[-gen gcc](Compiler-Option-Gen)* using `setjmp`/`longjmp` C runtime functions.

**-z valist-as-ptr**

Specifies that the implementation of [`Cva_List`](Cva-List) variable argument lists and macros for variadic procedures should use a normal pointer type if the target supports it. By default, [`Cva_List`](Cva-List) data types are mapped to gcc's `__builtin_va_list` data type when using *[-gen gcc](Compiler-Option-Gen)*.

**-z no-thiscall**

Instructs the compiler to ignore [`__Thiscall`](Thiscall) directives in source files.

**-z no-fastcall**

Instructs the compiler to ignore [`__Fastcall`](Fastcall) directives in source files.

**-z fbrt**

Instructs the compiler to link with the `libfbrt[mt].a` library instead of the `libfb[mt].a` library rather than having to copy or move files around or have multiple development directories.

**-z nocmdline**

Instructs the compiler to ignore all `Cmdline` directives in source file and take control from the real compiler command line only.

> **In tiko.** Each ignored `#cmdline` is warning `TKO0373`, as fbc's is its warning 46. It is the way to compile a source you do not trust: even without it a `#cmdline` cannot set the options listed under [#Cmdline](Preprocessor). tiko accepts every other `-z` value and ignores it.

**-z retinflts**

Instructs the compiler to enable returning some structures (types) in floating point registers.

**-z nobuiltins**

Instructs the compiler to disable all builtin declarations and definitions except those that are strictly necessary to initialize the compiler to a working state when it can begin to parse user code. The user code must then supply all of the required declarations and definitions needed by the compiler internals to allow compilation of user code to succeed. Note well that using this option requires knowledge of the internal workings of the compiler. For experimentation and development this allows declaring and defining nearly all compiler builtins in fb user code. The actual user code declarations required will depend on the contents of the user code to be compiled. The compiler is expected to throw an error if the required supporting declarations or definitions have not been made before they are required by the compiler itself while parsing the user source code (the compiler may also crash instead).

**-z optabstract**

Instructs the compiler not to emit unused pure abstract types.

Version


See also

- [Using the Command Line](Quick-Start#compile-a-program)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
