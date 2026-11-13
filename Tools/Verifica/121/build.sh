#!/bin/sh
# Builds the parity tool of the issue #121 (network of Quake III: msg.c, huffman.c, net_chan.c)
# with the gcc of w64devkit.
#   build.sh [output folder]
# The code is not retyped: q3_types.inc and q3_original.inc are line ranges of the real
# Reference/quake3/code/qcommon/{huffman,msg,net_chan}.c, of qcommon.h and of game/q_shared.h
# (all read only). stubs.h replaces the rest of the engine (cvars, errors, the datagram send);
# netgen.c is the driver with the scenarios. -O0 -fwrapv: the original is full of int shifts and
# sums that the 32 bit x86 compilers of its time wrapped.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
{
  sed -n '354p;362p;1082,1083p;1095,1096p;1129,1134p;1148,1215p;1248,1254p;1261,1327p' "$CODE/game/q_shared.h"
  sed -n '35,44p;127,149p;169,169p;180,203p;1017,1047p' "$CODE/qcommon/qcommon.h"
} > "$OUT/q3_types.inc"
{
  sed -n '30,436p' "$CODE/qcommon/huffman.c"
  sed -n '25,1720p' "$CODE/qcommon/msg.c"
  sed -n '50,71p;79,459p' "$CODE/qcommon/net_chan.c"
} > "$OUT/q3_original.inc"
cp "$HERE/stubs.h" "$HERE/netgen.c" "$OUT/"
"$KIT/gcc.exe" -O0 -w -fwrapv -ffp-contract=off -o "$OUT/netgen.exe" "$OUT/netgen.c" -lm
echo "built in $OUT"
