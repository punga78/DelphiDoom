#!/bin/sh
# Builds the parity tool of the server message parser (issue #121, second slice: cl_parse.c) with the
# gcc of w64devkit.
#   build-demo.sh [output folder]
# Like build.sh nothing is retyped: q3_parse.inc has the line ranges of the real
# Reference/quake3/code/client/cl_parse.c (CL_DeltaEntity .. CL_ParseSnapshot, CL_ParseGamestate,
# CL_ParseCommandString, CL_ParseServerMessage) and the svc_ops_e enum of qcommon.h. parsegen.c replaces
# cl, clc and cls with the few fields the parser touches, and is the "server" that writes the messages.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
sh "$HERE/build.sh" "$OUT" > /dev/null
{
  sed -n '1110,1110p;1119,1125p' "$CODE/game/q_shared.h"
  sed -n '253,263p' "$CODE/qcommon/qcommon.h"
  sed -n '26,36p' "$CODE/client/cl_parse.c"
} > "$OUT/q3_parse_types.inc"
{
  sed -n '61,311p' "$CODE/client/cl_parse.c"
  sed -n '387,461p' "$CODE/client/cl_parse.c"
  sed -n '566,582p;590,653p' "$CODE/client/cl_parse.c"
} > "$OUT/q3_parse.inc"
cp "$HERE/stubs.h" "$HERE/parsegen.c" "$OUT/"
"$KIT/gcc.exe" -O0 -w -fwrapv -ffp-contract=off -o "$OUT/parsegen.exe" "$OUT/parsegen.c" -lm
echo "built in $OUT"
