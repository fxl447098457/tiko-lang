[Home](Home) › [Math Library](Category-Math-Library) › [Math Library](Category-Math-Library) › **CryptoBytes**

# CryptoBytes

Fills a buffer with secure random bytes from the operating system; false on failure.

## Syntax

```freebasic
CryptoBytes( ptr, n )
```

## Examples

```freebasic
#import "std/numeric"
using numeric

'' From the OS CSPRNG -- BCryptGenRandom or getrandom -- not from the
'' Rng, which is fast and reproducible but NOT secure
dim as uint8 buf( 0 to 15 )
print CryptoBytes( @buf( 0 ), 16 )        '' true

dim as int32 nonzero = 0
for each b in buf
    if b <> 0 then nonzero += 1
next
print nonzero > 0            '' -1 (true)

'' For keys, tokens and salts. Never Rng, and never RND.
```

---

**Library:** [Math Library](Category-Math-Library)  
**Category:** [Math Library](Category-Math-Library)  
**Documented under:** Nothing Becomes A Keyword
