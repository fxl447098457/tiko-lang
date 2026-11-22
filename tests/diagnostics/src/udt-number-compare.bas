type S
   v as long
   declare operator cast () as string
end type
operator S.cast () as string : return str( v ) : end operator
type P
   v as long
   declare operator cast () as any ptr
end type
operator P.cast () as any ptr : return 0 : end operator
type N
   v as long
   declare operator cast () as string
   declare operator cast () as long
end type
operator N.cast () as string : return str( v ) : end operator
operator N.cast () as long : return v : end operator
enum Colr : C0, C5 = 5 : end enum
dim as S vs : dim as P vp : dim as N vn : dim as long i = 5 : dim as Colr k = C5
if vs = 5 then print "1"
if 5 <> vs then print "2"
if vs < i then print "3"
if vs >= 5.0 then print "4"
if vp = 5 then print "5"
if vs = k then print "6"
if vn = 5 then print "7"
if 5 <> vn then print "8"
if vs = "5" then print "9"
