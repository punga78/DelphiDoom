#!/bin/sh
# Writes Tests/Data/Q3Host/math.golden.txt: the answers of the math system calls of Quake III (mathgen.c).
#   math.sh <work folder> > Tests/Data/Q3Host/math.golden.txt
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=$1
mkdir -p "$OUT"
"$KIT/gcc.exe" -m32 -O1 -w -msse2 -mfpmath=sse -ffp-contract=off -o "$OUT/mathgen.exe" "$HERE/mathgen.c"
"$OUT/mathgen.exe"
