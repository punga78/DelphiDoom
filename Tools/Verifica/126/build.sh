#!/bin/sh
# Builds the parity driver of the issue #126 (animation.cfg, lerp frames, player angles, tags) with the gcc of w64devkit.
#   build.sh [output folder]
# Nothing of Quake III is retyped. The driver compiles, unchanged, line ranges of (read only):
#   cgame/cg_players.c   CG_ParseAnimationFile, CG_SetLerpFrameAnimation .. CG_PlayerAnimation, CG_SwingAngles .. CG_PlayerAngles
#   cgame/cg_ents.c      CG_PositionEntityOnTag, CG_PositionRotatedEntityOnTag
#   renderer/tr_model.c  R_GetTag, R_LerpTag
#   game/q_math.c        AnglesToAxis, AxisClear, AngleSubtract, AnglesSubtract, AngleMod, VectorNormalize, MatrixMultiply, AngleVectors
#   game/q_shared.c      COM_Parse, Q_stricmp (the whole file)
# and the declarations they need (animNumber_t, animation_t, lerpFrame_t, playerEntity_t, footstep_t, gender_t).
# -ffp-contract=off keeps every float operation rounded on its own (SSE, as the 32 bit code of the original assumes).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
rng() { # rng <file> <first line pattern> <line pattern where the next part starts (excluded)>
  A=$(grep -n "$2" "$1" | head -1 | cut -d: -f1)
  B=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  sed -n "${A},$((B - 1))p" "$1"
}
{
  sed -n '98,108p;50p' "$CODE/cgame/cg_local.h"
  sed -n '112p;472,536p;541p' "$CODE/game/bg_public.h"
  sed -n '127,144p;147,161p' "$CODE/cgame/cg_local.h"
} > "$OUT/types_original.inc"
{
  rng "$CODE/cgame/cg_players.c" '^static qboolean.CG_ParseAnimationFile' '^static qboolean.CG_FileExists'
  rng "$CODE/cgame/cg_players.c" '^static void CG_SetLerpFrameAnimation' '^static void CG_SwingAngles'
  rng "$CODE/cgame/cg_players.c" '^static void CG_SwingAngles' '^static void CG_HasteTrail'
} > "$OUT/players_original.inc"
sed -n '36,85p' "$CODE/cgame/cg_ents.c" > "$OUT/ents_original.inc"
rng "$CODE/renderer/tr_model.c" '^static md3Tag_t \*R_GetTag' '^void R_ModelBounds' > "$OUT/model_original.inc"
{
  rng "$CODE/game/q_math.c" '^void AnglesToAxis' '^void AxisCopy'
  rng "$CODE/game/q_math.c" '^float.AngleSubtract' '^float.AngleNormalize360'
  rng "$CODE/game/q_math.c" '^vec_t VectorNormalize( vec3_t v )' '^vec_t VectorNormalize2'
  rng "$CODE/game/q_math.c" '^void MatrixMultiply' '^void AngleVectors'
  rng "$CODE/game/q_math.c" '^void AngleVectors' '^void PerpendicularVector'
} > "$OUT/math_original.inc"
cp "$HERE/stubs.h" "$HERE/q3gen.c" "$OUT/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -std=gnu89 \
  -I"$OUT" -I"$CODE/game" -I"$CODE/qcommon" \
  -o "$OUT/q3gen.exe" "$OUT/q3gen.c" "$CODE/game/q_shared.c" -lm
echo "built in $OUT"
