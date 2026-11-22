dim shared as long gl = 1
dim shared as double gd = 2
type T
   v as long
   declare operator cast () as long ptr
   declare operator cast () as double ptr
end type
operator T.cast () as long ptr : return @gl : end operator
operator T.cast () as double ptr : return @gd : end operator
type A
   v as long
   declare operator cast () as long ptr
   declare operator cast () as any ptr
end type
operator A.cast () as long ptr : return @gl : end operator
operator A.cast () as any ptr : return @gd : end operator
dim as T vt : dim as A va
dim as long ptr pl = @gl
dim as double ptr pd = @gd
dim as byte ptr pb = cast(byte ptr, @gd)
print "1"; (vt = pl)
print "2"; (vt = pd)
print "3"; (pd <> vt)
print "4"; (va = pl)
print "5"; (va = pb)
print "6"; (va < pb)
dim as any ptr pa = @gd
type Q
   v as long
   declare operator cast () as any ptr
end type
operator Q.cast () as any ptr : return @gd : end operator
dim as Q vq
dim as any ptr pq = @gd
print "7"; (vq = pq)
print "8"; (pq <> vq)
