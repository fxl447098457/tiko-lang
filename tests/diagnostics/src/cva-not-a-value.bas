' cva_start, cva_end and cva_copy are statements. fbc-modern 1.20: error 9, and 3 for PRINT.
sub f cdecl (byval n as long, ...)
    dim as cva_list a, b
    dim as any ptr p = cva_start()
    dim as long x = cva_end(a)
    dim as long y = cva_copy(a, b)
    print cva_start(a, n)
end sub
