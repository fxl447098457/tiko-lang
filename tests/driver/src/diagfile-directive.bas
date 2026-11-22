'' diagfile-directive.bas -- a '#cmdline' may NOT redirect the diagnostics file (TKO0178):
'' where the compiler writes is the command line's to say.
#cmdline "--diagnostics-file build/.diagfile-refused.tsv"
#print inner
