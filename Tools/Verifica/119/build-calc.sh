#!/bin/sh
# Builds the parity driver of the issue #119, second part (q3calc.c: tr_shade_calc.c, tr_shade.c ComputeTexCoords,
# tr_noise.c of Quake III) with the gcc of w64devkit.
#   build-calc.sh [output folder]
# Nothing is retyped: q3calc.c includes the three renderer files unchanged and links game/q_shared.c and
# game/q_math.c. The renderer entry points that tr_shade.c names (OpenGL, GL_Bind, r_* cvars ...) are never called:
# a first link lists them and a stub file (data for the pointers and cvars, empty functions for GL_*, RB_*, R_*,
# GLimp_*) is generated beside the executable. -D__sun__ turns the x86 asm of myftol off (id386 = 0): the C path,
# (int)x, is the one that runs. q3calc.c gives M_PI the float value of q_shared.h (see there). -ffp-contract=off keeps each float operation rounded on its own (as the SSE code
# of the Delphi classes does).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
FLAGS="-O1 -w -ffp-contract=off -std=gnu89 -DBOTLIB -DC_ONLY -D__sun__ -I$CODE/renderer -I$CODE/game -I$CODE/qcommon"
SRC="$HERE/q3calc.c $CODE/game/q_shared.c $CODE/game/q_math.c"
: > "$OUT/stubs.c"
"$KIT/gcc.exe" $FLAGS -o "$OUT/q3calc.exe" $SRC "$OUT/stubs.c" -lm 2> "$OUT/link.txt" || true
sed -n "s/.*undefined reference to \`\(.*\)'.*/\1/p" "$OUT/link.txt" | sort -u | while read name; do
  case "$name" in
    GL_*|RB_*|R_*|GLimp_*) echo "void $name(void) {}" ;;
    *) echo "char $name[65536];" ;;
  esac
done > "$OUT/stubs.c"
"$KIT/gcc.exe" $FLAGS -o "$OUT/q3calc.exe" $SRC "$OUT/stubs.c" -lm
echo "built in $OUT"
