#!/bin/sh
# Builds the parity tools of the issue #114 (RoQ) with the gcc of w64devkit.
#   build.sh [output folder]
# The decoder is not retyped: roq_original.inc is made of line ranges of
# Reference/quake3/code/client/cl_cin.c (read only). The 32 bit compiler of the kit
# is used: the original keeps pointer differences in 32 bit integers.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
SRC=$ROOT/Reference/quake3/code/client/cl_cin.c
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
{
  for range in 37,53 60,60 71,136 178,186 203,324 334,551 561,937 947,1099 1109,1118 1143,1155 1165,1291 1301,1323; do
    sed -n "${range}p" "$SRC"
  done
} > "$OUT/roq_original.inc"
cp "$HERE/stubs.h" "$HERE/roqextract.c" "$HERE/roqgen.c" "$HERE/modeextract.c" "$OUT/"
"$KIT/i686-w64-mingw32-gcc.exe" -O1 -w -o "$OUT/roqextract.exe" "$OUT/roqextract.c"
"$KIT/gcc.exe" -O1 -w -o "$OUT/roqgen.exe" "$OUT/roqgen.c"
"$KIT/i686-w64-mingw32-gcc.exe" -O1 -w -o "$OUT/modeextract.exe" "$OUT/modeextract.c"
echo "built in $OUT"
