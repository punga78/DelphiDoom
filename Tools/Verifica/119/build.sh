#!/bin/sh
# Builds the parity driver of the issue #119 (Quake III shaders) with the gcc of w64devkit.
#   build.sh [output folder]
# Nothing of Quake III is retyped: q3shader.c includes, unchanged, code/renderer/tr_shader.c (the static functions
# ParseShader, ParseStage, FinishShader, ScanAndLoadShaderFiles... are the ones that run) and links
# code/game/q_shared.c (COM_ParseExt, SkipBracedSection, COM_Compress ...). The renderer, the file system and the
# images are stubs in q3shader.c. -ffp-contract=off keeps each float operation rounded on its own.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -std=gnu89 -DBOTLIB \
  -I"$CODE/renderer" -I"$CODE/game" -I"$CODE/qcommon" \
  -o "$OUT/q3shader.exe" \
  "$HERE/q3shader.c" "$CODE/game/q_shared.c" -lm
echo "built in $OUT"
