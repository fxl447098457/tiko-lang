[Home](Home) › [Function Finder](Function-Finder) › **Numbers and math**

# Numbers and math

The functions to round and convert numbers, do checked arithmetic, trig and random numbers, grouped by what you want to do. The **From** column says what a program needs before it can call one:

- **built-in**: nothing; it is always available.
- `std/numeric`: `#import "std/numeric"`, then `using numeric` to call it by its bare name.

Jump to: [Round a number](#round-a-number) · [Absolute value, sign, smaller and larger](#absolute-value-sign-smaller-and-larger) · [Powers, roots and logarithms](#powers-roots-and-logarithms) · [Trigonometry and angles](#trigonometry-and-angles) · [Divide whole numbers](#divide-whole-numbers) · [Catch, clamp or wrap integer overflow](#catch-clamp-or-wrap-integer-overflow) · [Convert between number types](#convert-between-number-types) · [Convert between numbers and text](#convert-between-numbers-and-text) · [Random numbers](#random-numbers) · [Secure random bytes](#secure-random-bytes) · [NaN, infinity and other special values](#nan-infinity-and-other-special-values) · [Look inside floating-point numbers](#look-inside-floating-point-numbers) · [Control floating-point rounding and exceptions](#control-floating-point-rounding-and-exceptions) · [Read and set bits and bytes](#read-and-set-bits-and-bytes) · [Count, reverse and swap bits](#count-reverse-and-swap-bits) · [Summarise an array of numbers](#summarise-an-array-of-numbers) · [Keep running statistics](#keep-running-statistics) · [Vectors](#vectors) · [Matrices and rotations](#matrices-and-rotations) · [Complex numbers: build, read and print](#complex-numbers-build-read-and-print) · [Complex numbers: test and measure](#complex-numbers-test-and-measure) · [Complex numbers: powers, roots and logarithms](#complex-numbers-powers-roots-and-logarithms) · [Complex numbers: trigonometry](#complex-numbers-trigonometry)

## Round a number

| Function | What it does | From |
|---|---|---|
| [Round](Modern-Math-Round) | Rounds to the nearest whole number or number of decimals, halves away from zero. | `std/numeric` |
| [RoundHalfEven](Modern-Math-RoundHalfEven) | Rounds to the nearest whole number or number of decimals, halves to the even side. | `std/numeric` |
| [Floor](Modern-Math-Floor) | Rounds down, towards negative infinity, so Floor(-2.1) is -3. | `std/numeric` |
| [Ceil](Modern-Math-Ceil) | Rounds up, towards positive infinity, so Ceil(-2.7) is -2. | `std/numeric` |
| [Truncate](Modern-Math-Truncate) | Drops the fraction, rounding towards zero, so Truncate(-2.7) is -2. | `std/numeric` |
| [Int](Int) | Returns the largest whole number not above the value, so Int(-1.3) is -2. | built-in |
| [Fix](Fix) | Returns the whole-number part, rounding towards zero, so Fix(-4.9) is -4. | built-in |
| [Frac](Frac) | Returns the fractional part, keeping the sign, so Frac(-1.75) is -0.75. | built-in |
| [Modf](Modern-Math-Modf) | Splits a number into whole and fractional parts that both keep its sign. | `std/numeric` |

## Absolute value, sign, smaller and larger

| Function | What it does | From |
|---|---|---|
| [Abs](Abs) | Returns the absolute value of a number. | built-in |
| [Sgn](Sgn) | Returns -1, 0 or 1 for the sign of a number, in the number's own type. | built-in |
| [Sign](Modern-Math-Sign) | Returns -1, 0 or 1 for the sign of a number, always as a Long. | `std/numeric` |
| [Min](Modern-Math-Min) | Returns the smaller of two values; a NaN argument gives NaN. | `std/numeric` |
| [Max](Modern-Math-Max) | Returns the larger of two values; a NaN argument gives NaN. | `std/numeric` |
| [Clamp](Modern-Math-Clamp) | Limits a value to a range: below lo gives lo, above hi gives hi. | `std/numeric` |
| [Lerp](Modern-Math-Lerp) | Returns the point a fraction t of the way from a to b; t is not clamped. | `std/numeric` |

## Powers, roots and logarithms

| Function | What it does | From |
|---|---|---|
| [Sqr](Sqr) | Returns the square root of a number. | built-in |
| [Exp](Exp) | Returns e raised to a power. | built-in |
| [Log](Log) | Returns the natural logarithm; zero gives minus infinity and a negative gives NaN. | built-in |
| [IPow](Modern-Math-IPow) | Raises a whole number to a whole-number power exactly, with no trip through Double. | `std/numeric` |
| [ISqrt](Modern-Math-ISqrt) | Returns the exact whole-number square root, rounded down. | `std/numeric` |
| [Hypot](Modern-Math-Hypot) | Returns the square root of x*x + y*y without overflowing for large values. | `std/numeric` |
| [Cbrt](Modern-Math-Cbrt) | Returns the cube root of a number, negative numbers included. | `std/numeric` |
| [Exp2](Modern-Math-Exp2) | Returns 2 raised to a power. | `std/numeric` |
| [Expm1](Modern-Math-Expm1) | Returns e raised to a power, minus one, accurately for powers near zero. | `std/numeric` |
| [Log2](Modern-Math-Log2) | Returns the base-2 logarithm of a number. | `std/numeric` |
| [Log10](Modern-Math-Log10) | Returns the base-10 logarithm of a number. | `std/numeric` |
| [Log1p](Modern-Math-Log1p) | Returns the natural logarithm of one plus a number, accurately near zero. | `std/numeric` |
| [Pow](Modern-Math-Pow) | Returns one floating-point number raised to the power of another. | `std/numeric` |

## Trigonometry and angles

| Function | What it does | From |
|---|---|---|
| [Sin](Sin) | Returns the sine of an angle in radians. | built-in |
| [Cos](Cos) | Returns the cosine of an angle in radians. | built-in |
| [Tan](Tan) | Returns the tangent of an angle in radians. | built-in |
| [Asin](Asin) | Returns the angle in radians, from -pi/2 to pi/2, whose sine is the number. | built-in |
| [Acos](Acos) | Returns the angle in radians, from 0 to pi, whose cosine is the number. | built-in |
| [Atn](Atn) | Returns the angle in radians, from -pi/2 to pi/2, whose tangent is the number. | built-in |
| [Atan2](Atan2) | Returns the angle in radians, from -pi to pi, of the point at x, y. | built-in |
| [DegToRad](Modern-Math-DegToRad) | Converts an angle from degrees to radians. | `std/numeric` |
| [RadToDeg](Modern-Math-RadToDeg) | Converts an angle from radians to degrees. | `std/numeric` |
| [Sinh](Modern-Math-Sinh) | Returns the hyperbolic sine of a number. | `std/numeric` |
| [Cosh](Modern-Math-Cosh) | Returns the hyperbolic cosine of a number. | `std/numeric` |
| [Tanh](Modern-Math-Tanh) | Returns the hyperbolic tangent of a number, which lies between -1 and 1. | `std/numeric` |
| [Asinh](Modern-Math-Asinh) | Returns the inverse hyperbolic sine of a number. | `std/numeric` |
| [Acosh](Modern-Math-Acosh) | Returns the inverse hyperbolic cosine of a number of 1 or more. | `std/numeric` |
| [Atanh](Modern-Math-Atanh) | Returns the inverse hyperbolic tangent of a number between -1 and 1. | `std/numeric` |

## Divide whole numbers

| Function | What it does | From |
|---|---|---|
| [FloorDiv](Modern-Math-FloorDiv) | Divides whole numbers rounding towards negative infinity, so FloorDiv(-7, 2) is -4. | `std/numeric` |
| [FloorMod](Modern-Math-FloorMod) | Returns the remainder with the divisor's sign, so FloorMod(-1, 5) is 4. | `std/numeric` |
| [EuclidDiv](Modern-Math-EuclidDiv) | Divides whole numbers so that the matching EuclidMod remainder is never negative. | `std/numeric` |
| [EuclidMod](Modern-Math-EuclidMod) | Returns a remainder that is never negative, whatever the signs. | `std/numeric` |
| [DivMod](Modern-Math-DivMod) | Returns the quotient and the remainder of one division together, as a tuple. | `std/numeric` |
| [GCD](Modern-Math-GCD) | Returns the greatest common divisor of two whole numbers. | `std/numeric` |
| [LCM](Modern-Math-LCM) | Returns the least common multiple of two whole numbers, or 0 if either is 0. | `std/numeric` |

## Catch, clamp or wrap integer overflow

| Function | What it does | From |
|---|---|---|
| [AddChecked](Modern-Math-AddChecked) | Adds two integers, returning an empty Optional if the result would overflow. | `std/numeric` |
| [SubChecked](Modern-Math-SubChecked) | Subtracts two integers, returning an empty Optional if the result would overflow. | `std/numeric` |
| [MulChecked](Modern-Math-MulChecked) | Multiplies two integers, returning an empty Optional if the result would overflow. | `std/numeric` |
| [DivChecked](Modern-Math-DivChecked) | Divides two integers, returning an empty Optional on division by zero or overflow. | `std/numeric` |
| [NegChecked](Modern-Math-NegChecked) | Negates an integer, returning an empty Optional for the most negative value. | `std/numeric` |
| [AbsChecked](Modern-Math-AbsChecked) | Returns the absolute value as an Optional, empty for the most negative value. | `std/numeric` |
| [IPowChecked](Modern-Math-IPowChecked) | Raises an integer to a power, returning an empty Optional if the result overflows. | `std/numeric` |
| [AddSaturating](Modern-Math-AddSaturating) | Adds two integers, clamping the result to the type's minimum or maximum. | `std/numeric` |
| [SubSaturating](Modern-Math-SubSaturating) | Subtracts two integers, clamping the result to the type's minimum or maximum. | `std/numeric` |
| [MulSaturating](Modern-Math-MulSaturating) | Multiplies two integers, clamping the result to the type's minimum or maximum. | `std/numeric` |
| [NegSaturating](Modern-Math-NegSaturating) | Negates an integer; the most negative value becomes the maximum instead. | `std/numeric` |
| [AbsSaturating](Modern-Math-AbsSaturating) | Returns the absolute value; the most negative value becomes the maximum instead. | `std/numeric` |
| [AddWrapping](Modern-Math-AddWrapping) | Adds two integers and wraps around on overflow, on purpose. | `std/numeric` |
| [SubWrapping](Modern-Math-SubWrapping) | Subtracts two integers and wraps around on overflow, on purpose. | `std/numeric` |
| [MulWrapping](Modern-Math-MulWrapping) | Multiplies two integers and wraps around on overflow, on purpose. | `std/numeric` |
| [NegWrapping](Modern-Math-NegWrapping) | Negates an integer within its type, so the most negative value stays as it is. | `std/numeric` |

## Convert between number types

| Function | What it does | From |
|---|---|---|
| [CInt](Cint) | Converts a number or string to an Integer, rounding to the nearest; no overflow check. | built-in |
| [CUInt](Cuint) | Converts a number or string to a UInteger, rounding to the nearest; no overflow check. | built-in |
| [CByte](Cbyte) | Converts a number or string to a Byte, rounding to the nearest; no overflow check. | built-in |
| [CUByte](Cubyte) | Converts a number or string to a UByte, rounding to the nearest; no overflow check. | built-in |
| [CShort](Cshort) | Converts a number or string to a Short, rounding to the nearest; no overflow check. | built-in |
| [CUShort](Cushort) | Converts a number or string to a UShort, rounding to the nearest; no overflow check. | built-in |
| [CLng](Clng) | Converts a number or string to a 32-bit Long, rounding to the nearest; no overflow check. | built-in |
| [CULng](Culng) | Converts a number or string to a 32-bit ULong, rounding to the nearest; no overflow check. | built-in |
| [CLngInt](Clngint) | Converts a number or string to a 64-bit LongInt, rounding to the nearest. | built-in |
| [CULngInt](Culngint) | Converts a number or string to a 64-bit ULongInt, rounding to the nearest. | built-in |
| [CDbl](Cdbl) | Converts a number or string to a Double. | built-in |
| [CSng](Csng) | Converts a number or string to a Single. | built-in |
| [CBool](Cbool) | Converts a number, or the text "true" or "false", to a boolean; zero gives false. | built-in |
| [Cast](Cast) | Converts a value to any named type, such as Cast(Byte, flag). | built-in |
| [CPtr](Cptr) | Converts a pointer or an integer to the given pointer type. | built-in |
| [CSign](Csign) | Converts an unsigned value to signed, so division and shifts treat it as signed. | built-in |
| [CUnsg](Cunsg) | Converts a signed value to unsigned, so division and shifts treat it as unsigned. | built-in |

## Convert between numbers and text

| Function | What it does | From |
|---|---|---|
| [TryParseDouble](Modern-Math-TryParseDouble) | Parses a whole string as a Double, returning an empty Optional if it is not one. | `std/numeric` |
| [TryParseSingle](Modern-Math-TryParseSingle) | Parses a whole string as a Single, returning an empty Optional if it is not one. | `std/numeric` |
| [TryParseLong](Modern-Math-TryParseLong) | Parses a whole string as a Long, returning an empty Optional if invalid or too big. | `std/numeric` |
| [TryParseULong](Modern-Math-TryParseULong) | Parses a whole string as a ULong, returning an empty Optional if invalid or too big. | `std/numeric` |
| [TryParseLongInt](Modern-Math-TryParseLongInt) | Parses a whole string as a LongInt, in an optional base; empty if invalid or too big. | `std/numeric` |
| [TryParseULongInt](Modern-Math-TryParseULongInt) | Parses a whole string as a ULongInt, returning an empty Optional if invalid or too big. | `std/numeric` |
| [ToString](Modern-Math-ToString) | Returns a number as the shortest text that reads back as exactly the same value. | `std/numeric` |
| [CurrentLocaleFormat](Modern-Math-CurrentLocaleFormat) | Returns a NumFormat holding this machine's decimal and thousands separators. | `std/numeric` |
| [Str](Str) | Returns a number or boolean as text. | built-in |
| [WStr](Wstr) | Returns a number as a wide string. | built-in |
| [Val](Val) | Converts text to a double. | built-in |
| [ValInt](Valint) | Converts text to a 32-bit integer. | built-in |
| [ValLng](Vallng) | Converts text to a 64-bit integer. | built-in |
| [ValUInt](Valuint) | Converts text to an unsigned 32-bit integer. | built-in |
| [ValULng](Valulng) | Converts text to an unsigned 64-bit integer. | built-in |

## Random numbers

| Function | What it does | From |
|---|---|---|
| [Rnd](Rnd) | Returns a random Double from 0 up to but not including 1. | built-in |
| [Randomize](Randomize) | Seeds the random number generator that Rnd uses, and can choose its algorithm. | built-in |
| [RngSeeded](Modern-Math-RngSeeded) | Creates a random generator from a seed, so the same seed repeats the same sequence. | `std/numeric` |
| [RngFromEntropy](Modern-Math-RngFromEntropy) | Creates a random generator seeded by the operating system, different on every run. | `std/numeric` |
| [Rng.NextInt](Modern-Math-NextInt) | Returns a random whole number from lo to hi, both included, without bias. | `std/numeric` |
| [Rng.NextDouble](Modern-Math-NextDouble) | Returns a random Double from 0 up to but not including 1, with 53 random bits. | `std/numeric` |
| [Rng.NextDoubleRange](Modern-Math-NextDoubleRange) | Returns a random Double from lo up to but not including hi. | `std/numeric` |
| [Rng.NextSingle](Modern-Math-NextSingle) | Returns a random Single from 0 up to but not including 1. | `std/numeric` |
| [Rng.NextULong](Modern-Math-NextULong) | Returns a random 32-bit unsigned value. | `std/numeric` |
| [Rng.NextULongInt](Modern-Math-NextULongInt) | Returns a random 64-bit unsigned value, the generator's raw output. | `std/numeric` |
| [Rng.NextBoolean](Modern-Math-NextBoolean) | Returns true or false with equal chance. | `std/numeric` |
| [Rng.NextBooleanP](Modern-Math-NextBooleanP) | Returns true with probability p, from 0 for never to 1 for always. | `std/numeric` |
| [Rng.NextNormal](Modern-Math-NextNormal) | Returns a random value from the normal distribution, mean 0 and standard deviation 1. | `std/numeric` |
| [Rng.NextNormalP](Modern-Math-NextNormalP) | Returns a random value from a normal distribution with the given mean and deviation. | `std/numeric` |
| [Rng.NextExponential](Modern-Math-NextExponential) | Returns a random waiting time between events at rate lambda; its mean is 1/lambda. | `std/numeric` |
| [Rng.NextPoisson](Modern-Math-NextPoisson) | Returns a random count of events in one interval at rate lambda; its mean is lambda. | `std/numeric` |
| [Shuffle](Modern-Math-Shuffle) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [Choice](Modern-Math-Choice) | Returns one element of an array or container picked at random, by reference. | `std/numeric` |
| [ShuffleArray](Modern-Math-Shuffle#containers) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [ShuffleDeque](Modern-Math-Shuffle#containers) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [ShuffleList](Modern-Math-Shuffle#containers) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [ChoiceArray](Modern-Math-Choice#containers) | Returns one element of an array or container picked at random, by reference. | `std/numeric` |
| [ChoiceDeque](Modern-Math-Choice#containers) | Returns one element of an array or container picked at random, by reference. | `std/numeric` |

## Secure random bytes

| Function | What it does | From |
|---|---|---|
| [CryptoBytes](Modern-Math-CryptoBytes) | Fills a buffer with secure random bytes from the operating system; false on failure. | `std/numeric` |
| [CryptoULongInt](Modern-Math-CryptoULongInt) | Returns a secure random 64-bit value from the operating system. | `std/numeric` |

## NaN, infinity and other special values

| Function | What it does | From |
|---|---|---|
| [IsNaN](Modern-Math-IsNaN) | Returns true if the value is NaN, which an equality test cannot detect. | `std/numeric` |
| [IsInfinite](Modern-Math-IsInfinite) | Returns true if the value is plus or minus infinity. | `std/numeric` |
| [IsFinite](Modern-Math-IsFinite) | Returns true if the value is neither infinite nor NaN. | `std/numeric` |
| [IsNormal](Modern-Math-IsNormal) | Returns true if the value is finite, not zero and not subnormal. | `std/numeric` |
| [IsSubnormal](Modern-Math-IsSubnormal) | Returns true if the value is nonzero but below the smallest normal number. | `std/numeric` |
| [IsNegative](Modern-Math-IsNegative) | Returns true if the sign bit is set, which includes negative zero. | `std/numeric` |
| [Classify](Modern-Math-Classify) | Returns whether a value is NaN, infinite, zero, subnormal or normal. | `std/numeric` |
| [NaN](Modern-Math-NaN) | Returns a Double that is NaN, not a number. | `std/numeric` |
| [NaNF](Modern-Math-NaNF) | Returns a Single that is NaN, not a number. | `std/numeric` |
| [Infinity](Modern-Math-Infinity) | Returns positive infinity as a Double. | `std/numeric` |
| [InfinityF](Modern-Math-InfinityF) | Returns positive infinity as a Single. | `std/numeric` |
| [NegInfinity](Modern-Math-NegInfinity) | Returns negative infinity as a Double. | `std/numeric` |
| [NegInfinityF](Modern-Math-NegInfinityF) | Returns negative infinity as a Single. | `std/numeric` |
| [MinSubnormalDouble](Modern-Math-MinSubnormalDouble) | Returns the smallest Double above zero. | `std/numeric` |
| [MinSubnormalSingle](Modern-Math-MinSubnormalSingle) | Returns the smallest Single above zero. | `std/numeric` |

## Look inside floating-point numbers

| Function | What it does | From |
|---|---|---|
| [Frexp](Modern-Math-Frexp) | Splits a number into a fraction from 0.5 to 1 and a power of two. | `std/numeric` |
| [ScaleB](Modern-Math-ScaleB) | Multiplies a number by a power of two exactly, by adjusting its exponent. | `std/numeric` |
| [Ulp](Modern-Math-Ulp) | Returns the gap between a number and the next one its type can hold. | `std/numeric` |
| [Fma](Modern-Math-Fma) | Returns x * y + z with a single rounding at the end. | `std/numeric` |
| [LogB](Modern-Math-LogB) | Returns the binary exponent of a number as a floating-point value. | `std/numeric` |
| [CopySign](Modern-Math-CopySign) | Returns a number's size with the sign of a second number, zero's sign included. | `std/numeric` |
| [NextAfter](Modern-Math-NextAfter) | Returns the next representable number after x in the direction of y. | `std/numeric` |

## Control floating-point rounding and exceptions

| Function | What it does | From |
|---|---|---|
| [GetRoundingMode](Modern-Math-GetRoundingMode) | Returns the direction floating-point results are currently rounded in. | `std/numeric` |
| [SetRoundingMode](Modern-Math-SetRoundingMode) | Sets the direction floating-point results are rounded in; returns true on success. | `std/numeric` |
| [ClearFpExceptions](Modern-Math-ClearFpExceptions) | Clears every floating-point exception flag. | `std/numeric` |
| [ClearFpException](Modern-Math-ClearFpException) | Clears one floating-point exception flag and leaves the others alone. | `std/numeric` |
| [TestFpException](Modern-Math-TestFpException) | Returns true if a floating-point exception flag has been raised since it was cleared. | `std/numeric` |
| [RaiseFpException](Modern-Math-RaiseFpException) | Raises a floating-point exception flag by hand; returns true on success. | `std/numeric` |

## Read and set bits and bytes

| Function | What it does | From |
|---|---|---|
| [Bit](Bit) | Returns -1 if the numbered bit of an integer is set, or 0 if it is clear. | built-in |
| [BitSet](Bitset) | Returns a copy of an integer with the numbered bit set to 1. | built-in |
| [BitReset](Bitreset) | Returns a copy of an integer with the numbered bit cleared to 0. | built-in |
| [LoByte](Lobyte) | Returns the lowest byte of a number, bits 0 to 7. | built-in |
| [HiByte](Hibyte) | Returns the second byte of a number, bits 8 to 15. | built-in |
| [LoWord](Loword) | Returns the lowest 16 bits of a number. | built-in |
| [HiWord](Hiword) | Returns bits 16 to 31 of a number. | built-in |

## Count, reverse and swap bits

| Function | What it does | From |
|---|---|---|
| [PopCount](Modern-Math-PopCount) | Counts the bits that are set. | `std/numeric` |
| [LeadingZeros](Modern-Math-LeadingZeros) | Counts the zero bits above the highest set bit; zero gives the type's full width. | `std/numeric` |
| [TrailingZeros](Modern-Math-TrailingZeros) | Counts the zero bits below the lowest set bit; zero gives the type's full width. | `std/numeric` |
| [BitWidth](Modern-Math-BitWidth) | Returns how many bits the value needs, or 0 for zero. | `std/numeric` |
| [Parity](Modern-Math-Parity) | Returns 1 if an odd number of bits are set, or 0 if an even number are. | `std/numeric` |
| [BitReverse](Modern-Math-BitReverse) | Reverses the order of all the bits in the value's type. | `std/numeric` |
| [ByteSwap](Modern-Math-ByteSwap) | Reverses the order of the bytes, converting between big-endian and little-endian. | `std/numeric` |
| [IsPow2](Modern-Math-IsPow2) | Returns true if the value is a power of two; zero is not one. | `std/numeric` |
| [NextPow2](Modern-Math-NextPow2) | Returns the smallest power of two at or above the value; zero gives 1. | `std/numeric` |

## Summarise an array of numbers

| Function | What it does | From |
|---|---|---|
| [Sum](Modern-Math-Sum) | Adds up an array with compensated summation, so small values are not lost. | `std/numeric` |
| [NaiveSum](Modern-Math-NaiveSum) | Adds up an array with a plain loop: faster than Sum, but small values can be lost. | `std/numeric` |
| [Count](Modern-Math-Count) | Counts the elements in an array. | `std/numeric` |
| [Mean](Modern-Math-Mean) | Returns the average of an array, or NaN if it is empty. | `std/numeric` |
| [Median](Modern-Math-Median) | Returns the middle value of an array, without reordering it. | `std/numeric` |
| [Percentile](Modern-Math-Percentile) | Returns the value below which p percent of an array falls, with p from 0 to 100. | `std/numeric` |
| [Variance](Modern-Math-Variance) | Returns the sample variance of an array, dividing by n-1. | `std/numeric` |
| [VariancePopulation](Modern-Math-VariancePopulation) | Returns the population variance of an array, dividing by n. | `std/numeric` |
| [StdDev](Modern-Math-StdDev) | Returns the sample standard deviation of an array, dividing by n-1. | `std/numeric` |
| [StdDevPopulation](Modern-Math-StdDevPopulation) | Returns the population standard deviation of an array, dividing by n. | `std/numeric` |
| [MinOf](Modern-Math-MinOf) | Returns the smallest value in an array, or NaN if it is empty. | `std/numeric` |
| [MaxOf](Modern-Math-MaxOf) | Returns the largest value in an array, or NaN if it is empty. | `std/numeric` |
| [Range](Modern-Math-Range) | Returns the largest value in an array minus the smallest. | `std/numeric` |
| [Covariance](Modern-Math-Covariance) | Returns the sample covariance of two arrays of the same length. | `std/numeric` |
| [Correlation](Modern-Math-Correlation) | Returns the Pearson correlation of two arrays, from -1 to 1. | `std/numeric` |

## Keep running statistics

| Function | What it does | From |
|---|---|---|
| [RunningStats.Add](Modern-Math-Add) | Adds one value to a running count, mean, variance, minimum and maximum. | `std/numeric` |
| [RunningStats.Merge](Modern-Math-Merge) | Combines another accumulator's values into this one, exactly. | `std/numeric` |
| [RunningStats.Reset](Modern-Math-Reset) | Empties the accumulator so that it can be reused. | `std/numeric` |
| [RunningStats.MinValue](Modern-Math-MinValue) | Returns the smallest value added so far. | `std/numeric` |
| [RunningStats.MaxValue](Modern-Math-MaxValue) | Returns the largest value added so far. | `std/numeric` |

## Vectors

| Function | What it does | From |
|---|---|---|
| [Dot](Modern-Math-Dot) | Returns the dot product of two vectors; zero means they are perpendicular. | `std/numeric` |
| [Cross](Modern-Math-Cross) | Returns a Vec3 perpendicular to both inputs; swapping them flips its direction. | `std/numeric` |
| [Mul](Modern-Math-Mul) | Multiplies two vectors component by component. | `std/numeric` |
| [Length](Modern-Math-Length) | Returns the length of a vector. | `std/numeric` |
| [LengthSquared](Modern-Math-LengthSquared) | Returns the squared length of a vector, the cheap way to compare lengths. | `std/numeric` |
| [Distance](Modern-Math-Distance) | Returns the distance between two points. | `std/numeric` |
| [DistanceSquared](Modern-Math-DistanceSquared) | Returns the squared distance between two points, the cheap way to test a range. | `std/numeric` |
| [Normalize](Modern-Math-Normalize) | Returns a vector of length 1 in the same direction; a zero vector stays zero. | `std/numeric` |
| [Reflect](Modern-Math-Reflect) | Reflects a vector off a surface, given the surface's normalised normal. | `std/numeric` |
| [Angle](Modern-Math-Angle) | Returns the angle between two vectors in radians, from 0 to pi. | `std/numeric` |

## Matrices and rotations

| Function | What it does | From |
|---|---|---|
| [Determinant](Modern-Math-Determinant) | Returns the determinant of a matrix; zero means it has no inverse. | `std/numeric` |
| [Transpose](Modern-Math-Transpose) | Returns a matrix with its rows and columns swapped. | `std/numeric` |
| [TryInverse](Modern-Math-TryInverse) | Writes the inverse of a matrix into a second one, or returns false if there is none. | `std/numeric` |
| [TransformPoint](Modern-Math-TransformPoint) | Applies a matrix to a point, translation included. | `std/numeric` |
| [TransformVector](Modern-Math-TransformVector) | Applies a matrix to a direction, leaving out the translation. | `std/numeric` |
| [Conjugate](Modern-Math-Conjugate) | Returns the conjugate of a quaternion, the reverse rotation when it is normalised. | `std/numeric` |
| [Rotate](Modern-Math-Rotate) | Rotates a vector by a normalised quaternion. | `std/numeric` |
| [ToMatrix](Modern-Math-ToMatrix) | Converts a quaternion into the matching rotation matrix. | `std/numeric` |
| [Slerp](Modern-Math-Slerp) | Blends between two rotations at constant speed, taking the shorter way round. | `std/numeric` |

## Complex numbers: build, read and print

| Function | What it does | From |
|---|---|---|
| [Complex](Modern-Math-Complex) | Holds a complex number as two Doubles, re and im. | `std/numeric` |
| [Complex operators](Modern-Math-Complex-Operators) | Adds, subtracts, multiplies, divides, raises and compares complex numbers. | `std/numeric` |
| [CSet](Modern-Math-CSet) | Builds a complex number from its real and imaginary parts. | `std/numeric` |
| [CPolar](Modern-Math-CPolar) | Builds a complex number from a modulus and an angle in radians. | `std/numeric` |
| [CZero](Modern-Math-CZero) | Returns the complex number 0. | `std/numeric` |
| [COne](Modern-Math-COne) | Returns the complex number 1. | `std/numeric` |
| [CImaginaryOne](Modern-Math-CImaginaryOne) | Returns the imaginary unit i. | `std/numeric` |
| [CNaN](Modern-Math-CNaN) | Returns a complex number whose two parts are both NaN. | `std/numeric` |
| [CInfinity](Modern-Math-CInfinity) | Returns a complex number whose two parts are both positive infinity. | `std/numeric` |
| [CReal](Modern-Math-CReal) | Returns the real part of a complex number. | `std/numeric` |
| [CImag](Modern-Math-CImag) | Returns the imaginary part of a complex number, without the i. | `std/numeric` |
| [CSetReal](Modern-Math-CSetReal) | Sets the real part of a complex variable in place. | `std/numeric` |
| [CSetImag](Modern-Math-CSetImag) | Sets the imaginary part of a complex variable in place. | `std/numeric` |
| [CSwap](Modern-Math-CSwap) | Swaps the values of two complex variables. | `std/numeric` |
| [CToString](Modern-Math-CToString) | Returns a complex number as text such as 3+4i that reads back exactly. | `std/numeric` |
| [CToStringPolar](Modern-Math-CToStringPolar) | Returns a complex number as polar text, such as 5 * exp(0.927i). | `std/numeric` |

## Complex numbers: test and measure

| Function | What it does | From |
|---|---|---|
| [CIsNaN](Modern-Math-CIsNaN) | Returns true if a complex number is NaN; one infinite part makes it infinite instead. | `std/numeric` |
| [CIsInfinite](Modern-Math-CIsInfinite) | Returns true if either part of a complex number is infinite. | `std/numeric` |
| [CIsFinite](Modern-Math-CIsFinite) | Returns true if both parts of a complex number are finite. | `std/numeric` |
| [CIsReal](Modern-Math-CIsReal) | Returns true if the imaginary part of a complex number is zero. | `std/numeric` |
| [CIsZero](Modern-Math-CIsZero) | Returns true if both parts of a complex number are zero. | `std/numeric` |
| [CAbs](Modern-Math-CAbs) | Returns the modulus, the distance from zero, without overflowing for large parts. | `std/numeric` |
| [CNorm](Modern-Math-CNorm) | Returns the modulus squared, the cheap way to compare sizes. | `std/numeric` |
| [CArg](Modern-Math-CArg) | Returns the phase angle of a complex number in radians, from -pi to pi. | `std/numeric` |
| [CLogAbs](Modern-Math-CLogAbs) | Returns the logarithm of the modulus, without overflowing for large parts. | `std/numeric` |
| [CConj](Modern-Math-CConj) | Returns the conjugate, the same number with its imaginary part negated. | `std/numeric` |
| [CNegate](Modern-Math-CNegate) | Returns a complex number with both parts negated. | `std/numeric` |
| [CReciprocal](Modern-Math-CReciprocal) | Returns one divided by a complex number; zero gives zero. | `std/numeric` |
| [CSgn](Modern-Math-CSgn) | Returns a complex number scaled to modulus 1, or zero for zero. | `std/numeric` |

## Complex numbers: powers, roots and logarithms

| Function | What it does | From |
|---|---|---|
| [CExp](Modern-Math-CExp) | Returns e raised to a complex power. | `std/numeric` |
| [CLog](Modern-Math-CLog) | Returns the natural logarithm of a complex number, or its logarithm to a given base. | `std/numeric` |
| [CLog10](Modern-Math-CLog10) | Returns the base-ten logarithm of a complex number. | `std/numeric` |
| [CSqrt](Modern-Math-CSqrt) | Returns the principal square root of a complex number or of a negative real. | `std/numeric` |
| [CPow](Modern-Math-CPow) | Raises a complex or real number to a complex or real power. | `std/numeric` |
| [CNthRoot](Modern-Math-CNthRoot) | Returns any one of the n nth roots of a complex number. | `std/numeric` |

## Complex numbers: trigonometry

| Function | What it does | From |
|---|---|---|
| [CSin](Modern-Math-CSin) | Returns the sine of a complex number. | `std/numeric` |
| [CCos](Modern-Math-CCos) | Returns the cosine of a complex number. | `std/numeric` |
| [CTan](Modern-Math-CTan) | Returns the tangent of a complex number, finite even for a large imaginary part. | `std/numeric` |
| [CSec](Modern-Math-CSec) | Returns the secant of a complex number, one over the cosine. | `std/numeric` |
| [CCsc](Modern-Math-CCsc) | Returns the cosecant of a complex number, one over the sine; zero gives zero. | `std/numeric` |
| [CCot](Modern-Math-CCot) | Returns the cotangent of a complex number, one over the tangent. | `std/numeric` |
| [CAsin](Modern-Math-CAsin) | Returns the inverse sine of a complex number, or of any real number. | `std/numeric` |
| [CAcos](Modern-Math-CAcos) | Returns the inverse cosine of a complex number, or of any real number. | `std/numeric` |
| [CAtan](Modern-Math-CAtan) | Returns the inverse tangent of a complex number. | `std/numeric` |
| [CAsec](Modern-Math-CAsec) | Returns the inverse secant of a complex number, or of any real number. | `std/numeric` |
| [CAcsc](Modern-Math-CAcsc) | Returns the inverse cosecant of a complex number, or of any real number. | `std/numeric` |
| [CAcot](Modern-Math-CAcot) | Returns the inverse cotangent of a complex number; zero gives zero. | `std/numeric` |
| [CSinh](Modern-Math-CSinh) | Returns the hyperbolic sine of a complex number. | `std/numeric` |
| [CCosh](Modern-Math-CCosh) | Returns the hyperbolic cosine of a complex number. | `std/numeric` |
| [CTanh](Modern-Math-CTanh) | Returns the hyperbolic tangent of a complex number. | `std/numeric` |
| [CSech](Modern-Math-CSech) | Returns the hyperbolic secant of a complex number, one over its cosh. | `std/numeric` |
| [CCsch](Modern-Math-CCsch) | Returns the hyperbolic cosecant of a complex number, one over its sinh; zero gives zero. | `std/numeric` |
| [CCoth](Modern-Math-CCoth) | Returns the hyperbolic cotangent of a complex number, one over its tanh. | `std/numeric` |
| [CAsinh](Modern-Math-CAsinh) | Returns the inverse hyperbolic sine of a complex number. | `std/numeric` |
| [CAcosh](Modern-Math-CAcosh) | Returns the inverse hyperbolic cosine of a complex number, or of any real number. | `std/numeric` |
| [CAtanh](Modern-Math-CAtanh) | Returns the inverse hyperbolic tangent of a complex number, or of any real number. | `std/numeric` |
| [CAsech](Modern-Math-CAsech) | Returns the inverse hyperbolic secant of a complex number. | `std/numeric` |
| [CAcsch](Modern-Math-CAcsch) | Returns the inverse hyperbolic cosecant of a complex number. | `std/numeric` |
| [CAcoth](Modern-Math-CAcoth) | Returns the inverse hyperbolic cotangent of a complex number. | `std/numeric` |

## See Also

- [Math Library guide](Category-Math-Library)
- [Mathematical functions](Category-Mathematical-Functions)
- [Converting data types](Category-Converting-Data-Types)
- [Bit manipulation](Category-Bit-Manipulation)
- [Money and finance](Category-Finance)

---

[Home](Home) · [Function Finder](Function-Finder) · [Keyword Index](Keyword-Index)

<!-- Generated by tools/wikifinder/finder.py. Edit the data, not this page. -->
