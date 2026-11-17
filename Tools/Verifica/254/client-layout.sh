#!/bin/sh
# Issue #254, fase 2c: Tests/Data/Q3Host/client-layout.golden.txt = layout of the structures cgame and ui share with
# the client host (offsetof and sizeof from the real headers, gcc -m32 of w64devkit).
#   client-layout.sh <work folder> > Tests/Data/Q3Host/client-layout.golden.txt
set -e
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
Q3=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=$1
mkdir -p "$OUT"
cd "$OUT"
"$KIT/gcc.exe" -m32 -w -I"$Q3/game" -I"$Q3/qcommon" -I"$Q3/cgame" -I"$Q3/ui" -I"$Q3/renderer" -I"$Q3/client" \
  -o client-layout.exe "$HERE/client-layout.c"
./client-layout.exe
