# Search and replace

**`pcre2_substitute`** copies a subject with the matches of a pattern
replaced. The replacement names groups: `$1` is group 1, and `${1}` the same
where letters or digits follow.

```tiko
{{#include ../../examples/libraries/pcre2-replace.tiko}}
```

**Output**

```text
{{#include ../../examples/libraries/pcre2-replace.out}}
```

The result goes into **a buffer you provide**, and the last argument is its
size going in and the result's length coming back. With
`PCRE2_SUBSTITUTE_OVERFLOW_LENGTH`, a buffer that is too small makes
`pcre2_substitute` return `PCRE2_ERROR_NOMEMORY` with the size it needs, so
`Replace` first asks with a size of 0, then makes a `string` that big and
calls again. That size counts a terminating zero PCRE2 always writes; after
the second call, `size` is the result's length without it, so `Replace`
returns `left( result, size )`.

- `PCRE2_SUBSTITUTE_GLOBAL` replaces every match; without it, only the first.
- `PCRE2_SUBSTITUTE_EXTENDED` adds more syntax, such as `\U` to put what
  follows in upper case, up to `\E`.
- A replacement that names a group the pattern does not have, like `$2`
  here, is an error code, and `pcre2_get_error_message` explains it.

### Activities

1. Leave out `PCRE2_SUBSTITUTE_GLOBAL` and run the program again.
2. Turn `19/11/2026` into `19 Nov 2026`. `pcre2_substitute` cannot look a
   month's name up, so find each date with `pcre2_match` and build the
   result yourself.
