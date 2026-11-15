#!/bin/sh
# Builds the parity tool of the issue #236 (profile of Quake III of the script parser: l_script.c and
# l_precomp.c of code/botlib) with the gcc of w64devkit.
#   build.sh [output folder]
# Like Tools/Verifica/124 the REAL l_script.c and l_precomp.c are copied unchanged (with COM_Compress
# of q_shared.c, lines 315-381) and the stubs of 124/stub replace the rest of the engine.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
WORK=$OUT/work
STUB=$HERE/../124/stub
mkdir -p "$WORK/botlib" "$WORK/game"
cp "$STUB/game/"*.h "$WORK/game/"
cp "$STUB/botlib/"*.h "$WORK/botlib/"
for f in l_script.c l_script.h l_precomp.c l_precomp.h; do cp "$CODE/botlib/$f" "$WORK/botlib/"; done
sed -n '315,381p' "$CODE/game/q_shared.c" > "$WORK/comcompress.inc"
cp "$HERE/q3scan.c" "$WORK/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -D_USE_32BIT_TIME_T -DBOTLIB -I"$WORK" -I"$WORK/botlib" \
  -o "$OUT/q3scan.exe" "$WORK/q3scan.c" "$WORK/botlib/l_script.c" "$WORK/botlib/l_precomp.c" -lm
echo "built in $OUT"
