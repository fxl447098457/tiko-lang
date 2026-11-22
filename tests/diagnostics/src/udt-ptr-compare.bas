dim shared as double gd = 2
dim shared as long gl = 1
type L
   v as long
   declare operator cast () as long ptr
end type
operator L.cast () as long ptr : return @gl : end operator
type S
   v as long
   declare operator cast () as string
end type
operator S.cast () as string : return "x" : end operator
type N
   v as long
   declare operator cast () as integer
end type
operator N.cast () as integer : return 0 : end operator
dim as L vl : dim as S vs : dim as N vn
dim as double ptr pd
dim as any ptr pa
print (vl = pd)
print (vl = pa)
print (vs = pa)
print (vn = pa)
type T
   v as long
   declare operator cast () as long ptr
   declare operator cast () as double ptr
end type
operator T.cast () as long ptr : return @gl : end operator
operator T.cast () as double ptr : return @gd : end operator
dim as T vt
print (vt = pa)
