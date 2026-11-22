# Regular expressions

A regular expression describes the shape of some text rather than the text
itself: `(\d+)\.(\d\d)` is digits, a dot and two more digits. tiko ships
PCRE2, the Perl-compatible regular-expression library, as the vendor package
`vendor/pcre2`, and what you call is PCRE2's own C interface, written the way
PCRE2's documentation writes it.

```tiko
{{#include ../../examples/libraries/pcre2.tiko}}
```

**Output**

```text
{{#include ../../examples/libraries/pcre2.out}}
```

**`pcre2_compile`** turns a pattern into a `pcre2_code ptr` once, to be
matched as often as you like. When the pattern is wrong it returns `nullptr`
with an error code and the byte where it gave up, and
**`pcre2_get_error_message`** says what the code means.

PCRE2 works on **UTF-8 bytes**. A pattern or subject is a `PCRE2_SPTR` and a
length: keep the text in a `string` and pass `strptr( s )` and `len( s )`. A
`ustring` holds UTF-16, and assigning it to a `string` converts it, as
`subject = text` does. A string literal does not convert to a `PCRE2_SPTR`,
which is why `Compile` takes a `string`. `PCRE2_UTF` reads the bytes as
UTF-8, so `\p{Lu}` matches the two bytes of `Ł`; `PCRE2_UCP` makes `\w` match
every letter, not only ASCII ones.

- **`pcre2_match`** returns a positive number when it finds a match, and
  `PCRE2_ERROR_NOMATCH` (-1) or another negative code when it does not.
- The **match data** holds the **ovector**: for the whole match and then each
  group, numbered by its `(`, a start and an end offset. Group *n* is
  `ov[2 * n]` to `ov[2 * n + 1]`.
- **`pcre2_next_match`** gives the offset and options for the next attempt,
  and returns 0 when there is nothing more to find.

```admonish danger title="Pitfall"
**The offsets count bytes, not characters.** 17 bytes come before `Łukasz`,
but only 16 characters, because `ë` is two bytes. Used on `text`, the offset
would cut the wrong characters. Cut the `string` with the offsets, then
convert, as the loop does with `who`.
```

PCRE2 finds a match by backtracking, and a pattern like `(a+)+$` tries every
way of splitting the `a`s, twice as many for each `a` more. When a pattern
comes from outside the program, give the match a **match context** with
`pcre2_set_match_limit`: the match stops with `PCRE2_ERROR_MATCHLIMIT` instead
of running on.

The code and match data are PCRE2's, freed with `pcre2_code_free` and
`pcre2_match_data_free`. Building the program copies PCRE2's shared library
beside it; `#import "vendor/pcre2" link static` links it in instead.

### Activities

1. Find every word that starts with a capital letter in `text`, and compile
   the pattern once without `PCRE2_UCP` to see which words are missed.
2. Print each name with its position in characters, computed from the byte
   offset.
