'' color-xterm.bas -- the bytes COLOR writes on an xterm, pinned (build/ptylane.sh).
''
'' On a 16-colour xterm COLOR goes out as fb_hTermOut's SEQ_SET_COLOR_EX: "ESC[<n>m",
'' 30+ / 90+ for the foreground and 40+ / 100+ for the background. tiko-rt wrote that
'' with !"\033[%dm" until 2026-11-20 -- but tiko's \nnn is FreeBASIC's DECIMAL escape,
'' so \033 is '!' and every COLOR printed "![93m" on linux-x86_64 and macos-arm64.
''
'' color-xterm.expected is fbc's own output, measured: this program compiled by fbc
'' (-gen gcc -target linux-x86_64), linked against fbc's linux libfb, run under
'' script(1) with TERM=xterm-256color in WSL, rendered with cat -v.
''
'' A bright foreground, a dark and a bright background, then back to 7,0.
color 14, 1 : print "A";
color 15, 9 : print "B";
color 7, 0 : print "C"
