'' smoke: spawn + typed channels under -mt -- the worker sends, the main sums.
'' Deterministic: each worker's contributions are distinct values on one channel.
'' expect: sum of squares: 55
#import "std/tasks"
sub Squares( byval out_ as tasks.SendChan( of int32 ), byval n as int32 )
	for i as int32 = 1 to n
		out_.Send( i * i )
	next
	out_.Close( )
end sub
dim ch as tasks.Channel( of int32 ) = tasks.Channel( of int32 )( 8 )
spawn Squares( ch, 5 )
dim total as int32 = 0
for each v in ch
	total += v
next
print "sum of squares:"; total
