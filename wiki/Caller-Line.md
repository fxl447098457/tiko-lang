[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__CALLER_LINE__ and __CALLER_FILE__**

# __CALLER_LINE__ and __CALLER_FILE__

The line and file of the statement that calls a procedure, written as a parameter's default.

## Syntax

```freebasic
byval paramLine as long = __CALLER_LINE__
byval paramFile as zstring ptr = __CALLER_FILE__
```

## Description

A parameter default is evaluated again at every call, at the call. `__CALLER_LINE__` and `__CALLER_FILE__` are the line number (`long`) and the source file's path as it was given to the compiler (`zstring ptr`) of the statement being compiled, so a default made of them is the **caller's** line and file. A procedure that reports a misuse, such as std/outcome's `Value( )` on an empty `Optional`, can then name the line where the mistake was made rather than a line inside itself.

An argument written at the call replaces the default as usual.

Anywhere else they are the line and file of the statement they appear in, like `__LINE__` and `__FILE__`. Unlike those two, they are not preprocessor macros: they are names the compiler fills in where it compiles the expression, so `#print` and `#if` do not see them.

A caller's location passes one level only. A procedure that wants its own caller's line to reach a procedure it calls passes it on explicitly.

They are tiko's own. `__TIKO_CALLER_LOCATION__` is defined (as `1`) by a compiler that has them, so a library can test for them with `#ifdef`.

## Examples

```freebasic
sub Check( byval ok as boolean, byval ln as long = __CALLER_LINE__, byval fl as zstring ptr = __CALLER_FILE__ )
	if ok = false then print "check failed at "; *fl; " line"; ln
end sub

Check( 1 = 1 )
Check( 1 = 2 )          '' check failed at demo.tiko line 6
```

## Remarks

### Differences from FreeBASIC

- Not in FreeBASIC. `__LINE__` inside a default is the declaration's line, since the preprocessor replaces it there.

### See also

- [`__LINE__`](Line)
- [`__FILE__`](File)
- [`__FUNCTION__`](Function)
- [Value](Modern-Optional-Value)
