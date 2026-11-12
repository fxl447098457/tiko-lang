[Home](Home) › [Finance](Category-Finance) › [Finance](Category-Finance) › **Beta**

# Beta

Returns how much an asset moves when its benchmark moves by one.

## Syntax

```freebasic
Beta( assetReturns( ), benchmarkReturns( ) )
```

## Examples

```freebasic
#import "std/money"
using money

'' The slope of the asset against its benchmark: how much it moves when
'' the benchmark moves by one.
''
'' SAMPLE COVARIANCE OVER SAMPLE VARIANCE.  The n-1 factors cancel, so
'' this is the regression slope -- what matters is not WHICH convention
'' but that BOTH legs use the same one.  Mixing them scales the answer
'' by (n-1)/n, which is the classic statistics bug.
dim as float64 r( 0 to 11 ) = { 0.02, -0.01, 0.03, 0.015, -0.025, 0.04, _
                               0.01, -0.005, 0.02, 0.03, -0.015, 0.025 }
dim as float64 b( 0 to 11 ) = { 0.018, -0.012, 0.025, 0.012, -0.02, 0.035, _
                               0.008, -0.004, 0.018, 0.028, -0.012, 0.022 }

print Beta( r( ), b( ) ).Value( )        '' 1.140670899270349

'' A portfolio identical to its benchmark has beta 1.
print Beta( b( ), b( ) ).Value( )        '' 1

'' A constant benchmark has no variance, so no slope.
dim as float64 flat_( 0 to 11 )
for each byref v in flat_
    v = 0.01
next
print Beta( r( ), flat_( ) ).Failure( ).Message( )
```

---

**Library:** [Finance](Category-Finance)  
**Category:** [Finance](Category-Finance)  
**Documented under:** Nothing Becomes A Keyword  
**Source:** `pkg/std/money/finport.tiko` in the [tiko repository](https://github.com/PaulSquires/tiko-lang).
