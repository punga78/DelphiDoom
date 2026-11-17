#!/bin/sh
# Issue #254, fase 2d: Tests/Data/Q3Host/botlayout.golden.txt = layout of the structures the BOTLIB system calls pass
# by pointer (offsetof and sizeof from the real headers, gcc -m32 of w64devkit).
#   botlayout.sh <work folder> > Tests/Data/Q3Host/botlayout.golden.txt
set -e
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
Q3=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=$1
mkdir -p "$OUT"
cd "$OUT"
"$KIT/gcc.exe" -m32 -w -I"$Q3/game" -I"$Q3/qcommon" -o botlayout.exe "$HERE/botlayout.c"
./botlayout.exe
