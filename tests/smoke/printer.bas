'' smoke: the printer channel is OUT of a printer-free program -- no WINSPOOL import
'' unless something names it. extern fb_LPos pulls it and answers.
'' expect: lpos ok:-1
extern "rtlib"
	declare function fb_LPos( byval printer_index as long ) as long
end extern
print "lpos ok:"; fb_LPos( 0 ) >= 0
