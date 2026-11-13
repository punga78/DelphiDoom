#!/bin/sh
# Builds the parity tool of the info strings of Quake III (issue #121) with the gcc of w64devkit.
#   build-info.sh [output folder]
# q3_info.inc is made of line ranges of the real Reference/quake3/code/game/q_shared.c (Q_strncpyz,
# Q_stricmpn, Q_stricmp, Com_sprintf and the Info_* functions); nothing is retyped.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
{
  sed -n '711,725p;727,764p;785,787p;870,890p;936,1251p' "$CODE/game/q_shared.c"
} > "$OUT/q3_info.inc"
cp "$HERE/stubs.h" "$HERE/infogen.c" "$OUT/"
"$KIT/gcc.exe" -O0 -w -fwrapv -ffp-contract=off -o "$OUT/infogen.exe" "$OUT/infogen.c" -lm
echo "built in $OUT"
