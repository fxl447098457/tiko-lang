'' See ../string-arith-operands.test.
sub Chk( byref s as const string, byval ok as boolean )
end sub
dim as long n = 0
dim as string s = "x"
dim as wstring * 8 w = "y"
Chk( "A( \"\" ) b", n = 0 )
print "A( \"\" ) b", n = 0
print s * "b"
print w mod s
print s and s
s -= "b"
w \= s
s += 1
n *= "3"
n += "3"
print s + "b"; s & "b"; s = "b"; s <> w; s < "b"; s >= w
s += "b"
s &= 1
w += s
