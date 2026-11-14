#!/bin/sh
# Builds the parity driver of the issue #127 (player movement of Quake III, bg_pmove) with the
# gcc of w64devkit.
#   build.sh [output folder]
# Nothing of Quake III is retyped and nothing of it is modified:
#   game/bg_pmove.c, bg_slidemove.c, bg_misc.c   compiled as they are (read only), with the real
#                                                q_shared.h, bg_public.h, bg_local.h
#   game/q_math.c                                is NOT compiled whole (MSVC assembler in it);
#                                                the whole functions the movement needs are
#                                                extracted by name with awk: vec3_origin,
#                                                AngleVectors, VectorNormalize, VectorNormalize2
# pmgen.c (ours) holds the stubs of the engine (Com_Printf, trap_SnapVector, ...), the fake world
# and the scenarios. -ffp-contract=off keeps every float operation rounded on its own (SSE);
# MISSIONPACK is not defined (baseq3 / baseoa), _DEBUG neither.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
GAME=$ROOT/Reference/quake3/code/game
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"

# prints the function whose first line matches the pattern, up to the first line "}"
extract() {
  awk -v re="$2" 'p == 0 && $0 ~ re { p = 1 } p == 1 { print } p == 1 && /^}/ { exit }' "$1"
}

{
  echo '#include "q_shared.h"'
  grep -h '^vec3_t	vec3_origin' "$GAME/q_math.c"
  extract "$GAME/q_math.c" '^void AngleVectors'
  extract "$GAME/q_math.c" '^vec_t VectorNormalize[(]'
  extract "$GAME/q_math.c" '^vec_t VectorNormalize2'
} | tr -d '\r' > "$OUT/q_math_part.inc"

grep -q 'vec3_origin' "$OUT/q_math_part.inc"
grep -q 'void AngleVectors' "$OUT/q_math_part.inc"
grep -q 'vec_t VectorNormalize( vec3_t v )' "$OUT/q_math_part.inc"
grep -q 'vec_t VectorNormalize2' "$OUT/q_math_part.inc"

cp "$HERE/pmgen.c" "$HERE/premath.h" "$OUT/"
"$KIT/gcc.exe" -include "$HERE/premath.h" -O1 -w -ffp-contract=off -I"$GAME" -I"$OUT" -o "$OUT/pmgen.exe" \
  "$OUT/pmgen.c" "$GAME/bg_pmove.c" "$GAME/bg_slidemove.c" "$GAME/bg_misc.c" -lm
echo "built in $OUT"
