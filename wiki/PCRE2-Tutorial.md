[Home](Home) › [Using C Libraries](Using-C-Libraries-Tutorial) › **PCRE2**

# PCRE2 Tutorial

> 📘 **Start with:** [Vendor Packages](Vendor-Packages), what a vendor package is and how `link static` and `link dynamic` work.
>
> 📖 **In the book:** [Chapter 28, Regular expressions](https://tiko-lang.net/book/ch28-logging-tui-sqlite.html#regular-expressions). Measured with PCRE2 10.49 and tiko, on Windows, Linux and macOS.

[PCRE2](https://www.pcre.org) is the Perl-compatible regular-expression library: the engine behind PHP's `preg_` functions, with named groups, lookaround, back references, Unicode properties, search and replace, and a just-in-time compiler.

tiko ships PCRE2 10.49 as a [vendor package](Vendor-Packages): its 8-bit library, built with Unicode support and the JIT. One line gives a program PCRE2's whole C API and links the library:

```freebasic
#import "vendor/pcre2"
```

There is nothing to download, no header to translate, no `#foreignlib` and nothing on the command line, on Windows, Linux and macOS. The names are the ones PCRE2's documentation uses -- `pcre2_compile`, `pcre2_match`, `pcre2_match_data` -- each a `#define` of the 8-bit name the library exports (`pcre2_compile_8`). More programs, from named groups to Unicode text, are in the toolchain's `examples/pcre2`.

---

## 1. Finding matches

The program finds each payment in a line of text, with its name, amount and date, and shows the one mistake to avoid with the offsets PCRE2 returns:

```freebasic
'' Regular expressions from PCRE2, one of the vendor packages.
#import "vendor/pcre2"

'' The compiled pattern, or a stop that says what is wrong with it.
function Compile( byref pattern as const string, _
        byval options as uint32 ) as pcre2_code ptr
    dim errorCode as int32
    dim errorOffset as PCRE2_SIZE
    var re = pcre2_compile( strptr( pattern ), len( pattern ), _
        options, @errorCode, @errorOffset, nullptr )
    if re = nullptr then
        dim message as zstring * 120
        pcre2_get_error_message( errorCode, _
            cast( PCRE2_UCHAR ptr, @message ), sizeof( message ) )
        print "pattern error at byte " & errorOffset & ": "; message
        end 1
    end if
    return re
end function

'' Group n of the last match, cut from the bytes it was found in.
function Group( byref subject as const string, _
        byval ov as PCRE2_SIZE ptr, byval n as int32 ) as string
    return mid( subject, ov[2 * n] + 1, ov[2 * n + 1] - ov[2 * n] )
end function

dim text as ustring = "Zoë paid 12.50 on 2026-11-03; " & _
                      "Łukasz paid 7.25 on 2026-11-19."
dim subject as string = text      '' the same text, as UTF-8 bytes

var re = Compile( "(\p{Lu}\w*) paid (\d+\.\d\d) on (\d{4}-\d\d-\d\d)", _
                  PCRE2_UTF or PCRE2_UCP )
var md = pcre2_match_data_create_from_pattern( re, nullptr )

dim start as PCRE2_SIZE = 0
dim more as uint32 = 0
do while pcre2_match( re, strptr( subject ), len( subject ), _
        start, more, md, nullptr ) > 0
    dim ov as PCRE2_SIZE ptr = pcre2_get_ovector_pointer( md )
    dim who as ustring = Group( subject, ov, 1 )
    print Group( subject, ov, 3 ); "  "; who; " "; _
          Group( subject, ov, 2 )
    print "  at byte " & ov[0] & ", but mid( text ) there gives """; _
          mid( text, ov[0] + 1, len( who ) ); """"
    if pcre2_next_match( md, @start, @more ) = 0 then exit do
loop

'' Without PCRE2_UCP, \w means ASCII letters only: Zoë no longer fits.
var ascii = Compile( "(\p{Lu}\w*) paid", PCRE2_UTF )
if pcre2_match( ascii, strptr( subject ), len( subject ), 0, 0, _
        md, nullptr ) > 0 then
    print "without PCRE2_UCP, the first is "; _
          Group( subject, pcre2_get_ovector_pointer( md ), 1 )
end if

print "bad: ";
pcre2_match_data_free( md )
pcre2_code_free( ascii )
pcre2_code_free( re )
Compile( "(\d+", 0 )
```

```text
2026-11-03  Zoë 12.50
  at byte 0, but mid( text ) there gives "Zoë"
2026-11-19  Łukasz 7.25
  at byte 31, but mid( text ) there gives "ukasz "
without PCRE2_UCP, the first is Łukasz
bad: pattern error at byte 4: missing closing parenthesis
```

The program stops with exit code 1 on purpose, at its last line: `(\d+` is not a pattern.

- **Compile once, match many times.** `pcre2_compile` turns the pattern into a `pcre2_code ptr`. On failure it returns `nullptr` with an error code and the byte offset where it gave up; `pcre2_get_error_message` turns the code into text.
- **Text goes in as UTF-8 bytes.** A pattern or subject is a `PCRE2_SPTR` (`const uint8 ptr`) and a length: keep the text in a `string` and pass `strptr( s )` and `len( s )`. A `ustring` is UTF-16; assigning it to a `string` converts it to UTF-8. A string literal does not convert to a `PCRE2_SPTR` (`TKO0698`).
- **`PCRE2_UTF`** reads pattern and subject as UTF-8. **`PCRE2_UCP`** gives `\w`, `\d` and `\b` their Unicode meaning: without it `\w` is ASCII, and `Zoë` no longer fits `\p{Lu}\w* paid`.
- **The ovector.** `pcre2_match` returns one more than the highest group that matched, `PCRE2_ERROR_NOMATCH` (-1) for no match, or another negative error code. The match data's ovector holds a start and an end offset per group: group *n* is `ov[2 * n]` to `ov[2 * n + 1]`, and a group that did not take part is `PCRE2_UNSET`.
- **Every match:** after each match, `pcre2_next_match` gives the offset and options for the next attempt -- including after a match of nothing -- and returns 0 when there is nothing more to try.
- **Offsets count bytes.** Cut the `string` with them, then convert. On the `ustring`, the same numbers cut the wrong characters once anything before them is not ASCII: the listing's `ukasz `.
- What PCRE2 allocates, PCRE2 frees: `pcre2_code_free`, `pcre2_match_data_free`.

## 2. Replacing

```freebasic
'' Search and replace with pcre2_substitute.
#import "vendor/pcre2"

function Compile( byref pattern as const string ) as pcre2_code ptr
    dim errorCode as int32
    dim errorOffset as PCRE2_SIZE
    return pcre2_compile( strptr( pattern ), len( pattern ), _
        PCRE2_UTF, @errorCode, @errorOffset, nullptr )
end function

'' subject with every match of re replaced. PCRE2 writes the result
'' into a buffer of ours; when it does not fit, PCRE2 says how big it
'' must be, and the second attempt does.
function Replace( byval re as pcre2_code ptr, _
        byref subject as const string, _
        byref replacement as const string, _
        byval options as uint32 = 0 ) as string
    dim result as string = space( len( subject ) )
    options or= PCRE2_SUBSTITUTE_GLOBAL or _
                PCRE2_SUBSTITUTE_OVERFLOW_LENGTH
    for attempt as int32 = 1 to 2
        dim size as PCRE2_SIZE = len( result )
        var rc = pcre2_substitute( re, _
            strptr( subject ), len( subject ), 0, options, nullptr, _
            nullptr, strptr( replacement ), len( replacement ), _
            cast( PCRE2_UCHAR ptr, strptr( result ) ), @size )
        if rc >= 0 then return left( result, size )
        if rc <> PCRE2_ERROR_NOMEMORY then
            dim message as zstring * 120
            pcre2_get_error_message( rc, _
                cast( PCRE2_UCHAR ptr, @message ), sizeof( message ) )
            return "(" & message & ")"
        end if
        result = space( size )          '' size is now what it needs
    next
    return "(no room)"
end function

dim dates as string = "Due 19/11/2026, paid 3/12/2026."
var dmy = Compile( "\b(\d{1,2})/(\d{1,2})/(\d{4})\b" )
print Replace( dmy, dates, "$3-$2-$1" )

dim mail as string = "Mail grace@example.org or ada@example.org."
var address = Compile( "(\w+)@(\w+)\.org" )
print Replace( address, mail, "${1}@…" )
print Replace( address, mail, "\U$1\E at $2 dot org", _
               PCRE2_SUBSTITUTE_EXTENDED )
print Replace( address, mail, "$4" )

pcre2_code_free( address )
pcre2_code_free( dmy )
```

```text
Due 2026-11-19, paid 2026-12-3.
Mail grace@… or ada@….
Mail GRACE at example dot org or ADA at example dot org.
(unknown substring)
```

- `pcre2_substitute` copies the subject with its matches replaced: `$1`, `${1}`, and with `PCRE2_SUBSTITUTE_EXTENDED` also `\U`...`\E` and `${n:+set:unset}`. `PCRE2_SUBSTITUTE_GLOBAL` replaces every match, not just the first.
- **The result goes into your buffer.** The last argument is its size in, and the result's length out. A buffer too small is `PCRE2_ERROR_NOMEMORY`; with `PCRE2_SUBSTITUTE_OVERFLOW_LENGTH`, the size comes back as what is needed, so a second call fits. That size includes the terminating zero PCRE2 always writes: a result as long as its subject does not fit a buffer of the subject's length.
- An error in the replacement is a negative code like any other: `$4` names a group the pattern lacks.

## 3. Patterns from outside the program

PCRE2 backtracks. A pattern such as `(a+)+$` tries every way of splitting a run of `a`s before it fails, twice as many for each `a` more. When a user, a file or the network chooses the pattern, put limits on it:

```freebasic
'' A pattern that comes from outside the program, matched under limits.
#import "vendor/pcre2"

function Message( byval code as int32 ) as string
    dim text as zstring * 120
    pcre2_get_error_message( code, cast( PCRE2_UCHAR ptr, @text ), _
                             sizeof( text ) )
    return text
end function

'' The compile context refuses a pattern longer than 200 bytes.
var cc = pcre2_compile_context_create( nullptr )
pcre2_set_max_pattern_length( cc, 200 )

dim pattern as string = "(a+)+$"           '' as if a user typed it
dim errorCode as int32
dim errorOffset as PCRE2_SIZE
var re = pcre2_compile( strptr( pattern ), len( pattern ), 0, _
                        @errorCode, @errorOffset, cc )

'' 26 a's and a b: every way of splitting the a's fails at the b.
dim subject as string = string( 26, "a" ) & "b"
var md = pcre2_match_data_create_from_pattern( re, nullptr )

'' The match context stops a match after 100,000 steps.
var mc = pcre2_match_context_create( nullptr )
pcre2_set_match_limit( mc, 100000 )
var rc = pcre2_match( re, strptr( subject ), len( subject ), 0, 0, _
                      md, mc )
print "interpreted: "; rc; " "; Message( rc )

pcre2_jit_compile( re, PCRE2_JIT_COMPLETE )
rc = pcre2_match( re, strptr( subject ), len( subject ), 0, 0, md, mc )
print "JIT:         "; rc; " "; Message( rc )

dim tooLong as string = string( 300, "x" )
var refused = pcre2_compile( strptr( tooLong ), len( tooLong ), 0, _
                             @errorCode, @errorOffset, cc )
if refused = nullptr then
    print "300 bytes:   refused, "; Message( errorCode )
end if

pcre2_match_context_free( mc )
pcre2_match_data_free( md )
pcre2_code_free( re )
pcre2_compile_context_free( cc )
```

```text
interpreted: -47 match limit exceeded
JIT:         -47 match limit exceeded
300 bytes:   refused, pattern string is longer than the limit set by the application
```

- A **match context** (`pcre2_match`'s last argument) caps one match: `pcre2_set_match_limit` (steps, counted again from zero at each start position), `pcre2_set_depth_limit` (nesting), `pcre2_set_heap_limit` (memory, in KiB). The defaults are 10,000,000 steps and 20,000,000 KiB -- about 20 GB, so set your own heap limit. A match that reaches a limit returns `PCRE2_ERROR_MATCHLIMIT` (-47), `PCRE2_ERROR_DEPTHLIMIT` (-53) or `PCRE2_ERROR_HEAPLIMIT` (-63).
- A **compile context** (`pcre2_compile`'s last argument) caps the pattern: `pcre2_set_max_pattern_length`, `pcre2_set_parens_nest_limit`.
- **`pcre2_jit_compile`** compiles the pattern to machine code; `pcre2_match` then runs it. JIT code obeys the match limit, as the listing shows, but not the depth and heap limits: it has its own stack.
- **`pcre2_dfa_match` is not a way out.** It does not backtrack, but on `(a+)+$` its time still grows steeply with the subject -- measured: 100 characters 6 ms, 300 characters 0.3 s, 1,000 characters 31 s -- and a match limit of 100,000 did not stop it. It also finds no groups.

## 4. More programs

The toolchain's `examples/pcre2`, each built with `tiko <name>.tiko`:

| Folder | Shows |
| --- | --- |
| `01-match` | a bad pattern reported, the first match and its groups, every match (empty ones included), the JIT |
| `02-named` | named groups: by name, by number, into your own buffer, as a list; `pcre2_pattern_info` |
| `03-replace` | `$1`, `${name}`, `\U`, `${n:+yes:no}`, a result that outgrows its buffer, a bad replacement |
| `04-unicode` | `PCRE2_UTF` and `PCRE2_UCP`, byte offsets back to characters, caseless beyond ASCII, invalid UTF-8 and `PCRE2_MATCH_INVALID_UTF` |
| `05-untrusted` | every limit, the JIT under a limit, and the DFA matcher measured |

## 5. In a project

A [`tiko build`](Category-Tiko-Build) project needs nothing in its `tiko.toml` for PCRE2: the import says it all. `tiko build`'s `copy_to` copies the shared library along with the program.

## 6. Shipping the program

- **Linked dynamically** (the default): ship the library the build put beside the program -- `pcre2.dll`, `pcre2_linux_x86_64.so` or `pcre2_macos_arm64.dylib`.
- **Linked statically** (`#import "vendor/pcre2" link static`): the program alone.

PCRE2 is under the BSD licence: a program you distribute with PCRE2 in it, linked either way, reproduces PCRE2's copyright notice and licence in its documentation or other materials. The text is `pkg/vendor/pcre2/LICENSE` in the toolchain.

## 7. Troubleshooting

| Problem | Fix |
|---|---|
| `TKO0698: this argument does not convert to the parameter's type` on a pattern or subject | it is a string literal or a `string` itself; pass `strptr( s )` of a `string` |
| `warning TKO0833: passing different pointer types: a 'uint16 ptr' for a 'const uint8 ptr'` | that is `strptr` of a `ustring`, which hands PCRE2 UTF-16. Assign the `ustring` to a `string` first |
| a match's text is shifted by a character or two | an ovector offset (bytes) was used on a `ustring` (characters). Cut the `string` |
| `-1` from `pcre2_match` where a match was expected on text with accents | compile with `PCRE2_UTF` and, for `\w`, `\d` and `\b`, `PCRE2_UCP` |
| `-3` to `-23` from `pcre2_match` (UTF-8 errors) | the subject is not valid UTF-8, often Latin-1 bytes. Convert it, or compile with `PCRE2_MATCH_INVALID_UTF` |
| `-47`, `-53` or `-63` from `pcre2_match` | a match, depth or heap limit was reached: the pattern backtracks too much on this subject |
| `-43` from `pcre2_dfa_match` | its workspace is too small; give it more ints |
| `-48` from `pcre2_substitute` | the output buffer is too small; set `PCRE2_SUBSTITUTE_OVERFLOW_LENGTH` and retry with the size it returns |
| the program exits at once with `-1073741515` (Windows) | `pcre2.dll` is not beside the program |

---

**Next:** [SQLite](SQLite-Tutorial) · [raylib](Raylib-Tutorial) · [SDL3](SDL3-Tutorial) · [Vendor Packages](Vendor-Packages)

[Home](Home)
