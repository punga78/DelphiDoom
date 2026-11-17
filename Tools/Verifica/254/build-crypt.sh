#!/bin/sh
# Builds cryptgen.exe (issue #254, phase 3) and writes Tests/Data/Q3Host/netcrypt.golden.txt:
#   build-crypt.sh <work folder> > Tests/Data/Q3Host/netcrypt.golden.txt
# The real functions are cut out of the files of Quake III by line ranges (Com_HashKey of common.c, the encoders and
# decoders of sv_net_chan.c and cl_net_chan.c, CL_WritePacket of cl_input.c); msg.c, huffman.c and net_chan.c come
# from Tools/Verifica/121 (the same ranges as its build.sh). gcc of w64devkit, -O0 -fwrapv.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
V121=$HERE/../121
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
{
  sed -n '668,677p' "$CODE/qcommon/common.c"
  sed -n '36,77p;90,127p' "$CODE/server/sv_net_chan.c"
  sed -n '199,206p' "$CODE/server/sv_net_chan.c"
  sed -n '38,81p;92,127p;143,148p;158,167p' "$CODE/client/cl_net_chan.c"
  sed -n '688,798p' "$CODE/client/cl_input.c"
} > "$OUT/crypt_real.inc"
cp "$V121/stubs.h" "$HERE/cryptgen.c" "$OUT/"
"$KIT/gcc.exe" -O0 -w -fwrapv -ffp-contract=off -o "$OUT/cryptgen.exe" "$OUT/cryptgen.c" -lm
"$OUT/cryptgen.exe"
