'' cva_list in a mangled name, by reference, by value and through a pointer -- the shapes that
'' show the substitution rule. See cva-list-mangle-linux-arm64.test.
namespace N
sub P( byref a as cva_list ) : end sub
sub Q( byref a as cva_list, byref b as cva_list ) : end sub
sub R( byval a as cva_list, byval b as cva_list ) : end sub
sub S( byval a as cva_list, byref b as cva_list ) : end sub
sub T( byref a as cva_list, byval b as cva_list ) : end sub
sub U( byval a as cva_list, byval b as cva_list, byref c as cva_list, byref d as cva_list ) : end sub
sub V( byval a as cva_list ptr, byval b as cva_list ) : end sub
sub W( byval a as cva_list ptr, byval b as cva_list ptr ) : end sub
end namespace
