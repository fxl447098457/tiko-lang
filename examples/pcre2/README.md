# PCRE2 examples

Regular expressions through PCRE2's C interface, from `vendor/pcre2`, which comes with the
toolchain. Each example is one `.tiko` program, built on its own with `tiko <name>.tiko`.

| Folder | Shows |
| --- | --- |
| `01-match` | compile a pattern and report a bad one, the first match and its groups, every match with `pcre2_next_match` (empty matches included), the JIT -- after PCRE2's `pcre2demo.c` |
| `02-named` | named groups: by name, by number, into your own buffer, as a list PCRE2 allocates; what `pcre2_pattern_info` says about a pattern |
| `03-replace` | `pcre2_substitute`: every match or the first, `$1` and `${name}`, the extended syntax's `\U` and `${n:+yes:no}`, a result that outgrows its buffer, an error in the replacement |
| `04-unicode` | text that is not ASCII: UTF-8 in, `PCRE2_UTF` and `PCRE2_UCP`, byte offsets turned back into characters, caseless matching beyond ASCII, a subject that is not valid UTF-8 |
| `05-untrusted` | patterns and subjects from outside the program: a compile context's length and nesting limits, a match context's match, depth and heap limits, the JIT under a limit, and why the DFA matcher is no defence |

## Things to know

- **Text crosses as bytes.** `vendor/pcre2` is PCRE2's 8-bit library: a pattern and a subject
  are a `PCRE2_SPTR` (`const uint8 ptr`) and a length. Keep them in a `string` and pass
  `strptr( s )` and `len( s )`. A string literal does not convert to a `PCRE2_SPTR`
  (`TKO0698`): put it in a `string` first.
- **A `ustring` is UTF-16.** Assign it to a `string` to get its UTF-8, then compile with
  `PCRE2_UTF` (and `PCRE2_UCP` for Unicode `\w`, `\d`, `\b`). `strptr` of a `ustring` compiles,
  with only warning `TKO0833`, and hands PCRE2 UTF-16 code units: never do it.
- **Every offset is in bytes.** The ovector, the error offset of a bad pattern and
  `pcre2_get_startchar` all count bytes. `mid( bytes, start + 1, length )` cuts the `string`
  correctly; the same numbers used on the `ustring` cut the wrong characters once anything
  before them is not ASCII.
- **What PCRE2 allocates, PCRE2 frees:** `pcre2_code_free`, `pcre2_match_data_free`,
  `pcre2_*_context_free`, `pcre2_substring_free`, `pcre2_substring_list_free`.
- **A pattern from outside the program needs limits.** PCRE2 backtracks, and `(a+)+$` takes
  exponential time. `pcre2_set_match_limit`, `pcre2_set_depth_limit` and `pcre2_set_heap_limit`
  on a match context make `pcre2_match` stop with an error code -- JIT code obeys the match limit
  only, and the default heap limit is about 20 GB. `pcre2_set_max_pattern_length` on a compile
  context refuses a long pattern. `pcre2_dfa_match` does not backtrack but is no defence: its
  time grows steeply on the same pattern, and a match limit of 100,000 did not stop it.

## Dynamic or static

Every example imports PCRE2 with

```
#import "vendor/pcre2" link dynamic
```

which links the shared library and copies it beside the program -- `pcre2.dll` on Windows,
`pcre2_linux_x86_64.so` on Linux, `pcre2_macos_arm64.dylib` on macOS. Change `dynamic` to
`static` and PCRE2 is built into the program instead, with nothing to copy.

These examples are BSD-licensed, as PCRE2 is.
