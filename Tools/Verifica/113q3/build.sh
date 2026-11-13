#!/bin/sh
# Builds the parity tool of the Quake III profile of the console (issue #113): cmd.c and cvar.c of
# Quake III Arena with the gcc of w64devkit.
#   build.sh [output folder]
# The code is not retyped: types.inc and original.inc are line ranges of the real
# Reference/quake3/code/{qcommon/cmd.c, qcommon/cvar.c, qcommon/common.c, game/q_shared.c, game/q_shared.h}
# (all read only). stubs.h and the first part of driver.c replace the rest of the engine; driver.c has the
# operations of the scenarios. -O0 -fwrapv: the original is from the days of the 32 bit x86 compilers.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
{
  sed -n '354,356p;358,364p;367p;379,384p;552p;934,980p' "$CODE/game/q_shared.h"
} > "$OUT/types.inc"
{
  sed -n '74,93p;711,787p;870,890p;902,916p' "$CODE/game/q_shared.c"
  sed -n '527,629p' "$CODE/qcommon/common.c"
} > "$OUT/helpers.inc"
sed -n '27,715p' "$CODE/qcommon/cmd.c" > "$OUT/cmd.inc"
sed -n '27,906p' "$CODE/qcommon/cvar.c" > "$OUT/cvar.inc"
sed -n '1032,1080p;1087,1135p;1148,1156p;1165,1204p;1213,1251p' "$CODE/game/q_shared.c" > "$OUT/info.inc"
cp "$HERE/stubs.h" "$HERE/driver.c" "$OUT/"
"$KIT/gcc.exe" -O0 -w -fwrapv -ffp-contract=off -o "$OUT/q3console.exe" "$OUT/driver.c" -lm
echo "built in $OUT"
