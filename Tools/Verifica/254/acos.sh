#!/bin/sh
# Issue #254, fase 2c: Tests/Data/Q3Host/acos.golden.txt = what CG_ACOS answers (Q_acos of common.c on gcc -m32 with SSE).
#   acos.sh <work folder> > Tests/Data/Q3Host/acos.golden.txt
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=$1
mkdir -p "$OUT"
"$KIT/gcc.exe" -m32 -O1 -w -msse2 -mfpmath=sse -ffp-contract=off -o "$OUT/acosgen.exe" "$HERE/acosgen.c"
"$OUT/acosgen.exe"
