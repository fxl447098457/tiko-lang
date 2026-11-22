'' Under '-z nocmdline' this '#cmdline' is warned about and dropped, so FROMSOURCE is not
'' defined and the '#error' is not reached.
#cmdline "-d FROMSOURCE"
#ifdef FROMSOURCE
#error "the #cmdline was honoured"
#endif
print 1
