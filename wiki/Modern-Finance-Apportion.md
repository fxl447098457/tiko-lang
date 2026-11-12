[Home](Home) › [Finance](Category-Finance) › [Finance](Category-Finance) › **Apportion**

# Apportion

Splits a Currency total by weights into parts that add up to it exactly.

## Syntax

```freebasic
Apportion( total, weights( ), result( ) )
```

## Examples

```freebasic
#import "std/money"
using money

'' Splits a total so the parts sum EXACTLY to it -- the rounding
'' remainder is distributed rather than dropped, which is what makes
'' three-way splits of a penny add up
dim as Currency total_ = CurrencyFromDouble( 10.0 )
dim as int64 weights( 0 to 2 ) = { 1, 1, 1 }
dim parts( 0 to 2 ) as Currency

Apportion( total_, weights( ), parts( ) )

dim as Currency sum_ = CurrencyFromInt( 0 )
for each part in parts
    print part.ToString( )
    sum_ = sum_ + part
next
print sum_.ToString( )       '' 10.0000 -- exactly the input
```

---

**Library:** [Finance](Category-Finance)  
**Category:** [Finance](Category-Finance)  
**Documented under:** Nothing Becomes A Keyword
