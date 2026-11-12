' Operand count and list type. fbc-modern 1.20: 14, 16 or 7 for the count, 24 for the type,
' except 'any ptr', which fbc accepts and tiko refuses on every target.
sub f cdecl (byval n as long, ...)
    dim as cva_list a, b
    dim as long l, m
    dim as any ptr p, q
    dim as long ptr lp
    cva_start()
    cva_start(a)
    cva_start(a, n, n)
    cva_end()
    cva_end(a, b)
    cva_copy(a)
    cva_start(l, n)
    cva_start(p, n)
    cva_end(l)
    cva_end(p)
    cva_copy(l, m)
    cva_copy(p, q)
    cva_copy(a, p)
    print cva_arg(l, long)
    print cva_arg(p, long)
    print cva_arg(lp, long)
    cva_arg(l, long)
end sub
