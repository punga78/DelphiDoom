#!/bin/sh
# Builds the parity tools of the issue #199 (FLIC) with the gcc of w64devkit.
#   build.sh [output folder]
# The decoder is not retyped: flc_original.inc is made of line ranges of
# Reference/OpenXcom/src/Engine/FlcPlayer.cpp (read only), the code that Libs\XcomFormats
# already ported and that Libs\Cinematic reuses. The remake of Warcraft (acoto87/war1) has
# no FLIC code, so the decoder of OpenXcom is the reference.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
ENGINE=$ROOT/Reference/OpenXcom/src/Engine
SRC=$ENGINE/FlcPlayer.cpp
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
{
  for range in 45,80 275,278 280,289 291,297 336,396 398,451 503,777 887,890 964,979; do
    sed -n "${range}p" "$SRC"
  done
} > "$OUT/flc_original.inc"
cp "$HERE/flcextract.cpp" "$HERE/flcgen.c" "$HERE/flcscan.c" "$OUT/"
"$KIT/g++.exe" -O1 -w -I"$HERE/shim" -I"$ENGINE" -I"$OUT" -o "$OUT/flcextract.exe" "$OUT/flcextract.cpp"
"$KIT/gcc.exe" -O1 -w -o "$OUT/flcgen.exe" "$OUT/flcgen.c"
"$KIT/gcc.exe" -O1 -w -o "$OUT/flcscan.exe" "$OUT/flcscan.c"
echo "built in $OUT"
