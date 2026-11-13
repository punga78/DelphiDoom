#!/bin/sh
# Writes Tests/Data/MapFile/bsp.golden.txt: the answer of the real C code on the three BSPs.
#   make-golden.sh <folder of build.sh>
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${1:-$HERE/out}
GOLDEN=$HERE/../../../Tests/Data/MapFile/bsp.golden.txt
: > "$GOLDEN"
for v in 0 1 2; do
  "$OUT/bspgen.exe" write $v "$OUT/variant$v.bsp"
  echo "bsp $v" >> "$GOLDEN"
  "$OUT/bspgen.exe" read "$OUT/variant$v.bsp" >> "$GOLDEN"
done
"$OUT/bspgen.exe" extras "$OUT/variant0.bsp" > "$HERE/../../../Tests/Data/MapFile/bsp_render.golden.txt"
echo "written $GOLDEN"
