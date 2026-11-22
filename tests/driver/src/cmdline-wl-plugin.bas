'' '-Wl -plugin,x.so' MAKES GNU ld LOAD x.so AND RUN IT, at link time: compiling this file
'' would run the attacker's code. The '-rpath' before it is one a source may pass, and is
'' not reported. '--build-id' is there because it takes an OPTIONAL value: were the piece
'' after it waved through as its value, '-plugin' would reach the linker unchecked.
#cmdline "-Wl -rpath,$ORIGIN -Wl --build-id,-plugin,./marker.so -Wl @cmdline-args.rsp -Wl /STACK:8388608 -Wl /OUT:C:/evil.exe"
print 1
