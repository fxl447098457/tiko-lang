[Home](Home) › [Math Library](Category-Math-Library) › [Math Library](Category-Math-Library) › **CryptoULongInt**

# CryptoULongInt

Returns a secure random 64-bit value from the operating system.

If the operating system's random source fails it writes one line to stderr and aborts the program, rather than return a value an attacker could predict. A program that can recover from that calls `CryptoBytes`, which returns `false` instead.

## Syntax

```freebasic
CryptoULongInt( )
```

## Examples

```freebasic
#import "std/numeric"
using numeric

'' Eight cryptographically secure bytes as one number
dim as uint64 a = CryptoULongInt( )
dim as uint64 b = CryptoULongInt( )

print a <> b                 '' -1 (true), with overwhelming probability

'' This is what RngFromEntropy uses for its seed
```

---

**Library:** [Math Library](Category-Math-Library)  
**Category:** [Math Library](Category-Math-Library)  
**Documented under:** Nothing Becomes A Keyword
