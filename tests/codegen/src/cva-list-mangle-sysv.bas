'' cva_list in a mangled name beside the shapes in cva-list-mangle.bas: a byval one next to
'' a pointer to one, inside a procedure type, after another type's candidates, and const.
'' See cva-list-mangle-sysv-linux-x86_64.test.
namespace N
type UDT
    as long x
end type
sub X( byref a as cva_list, byval p as cva_list ptr ) : end sub
sub Y( byval a as cva_list, byval p as cva_list ptr ) : end sub
sub Z( byval p as cva_list ptr, byref a as cva_list ) : end sub
sub F1( byval f as sub( byval as cva_list ), byval a as cva_list ) : end sub
sub F2( byval a as cva_list, byval f as sub( byval as cva_list ) ) : end sub
sub F3( byval a as cva_list, byval b as long, byval c as cva_list ) : end sub
sub SA( byval p as cva_list, byref u as UDT, byref v as UDT ) : end sub
sub SB( byref u as UDT, byval p as cva_list, byval q as cva_list ptr, byref r as cva_list ) : end sub
sub SC( byval p as const cva_list ) : end sub
end namespace
