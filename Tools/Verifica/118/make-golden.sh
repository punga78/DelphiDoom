#!/bin/sh
# Writes Tests/Data/Collision/q3world0.bsp, q3world1.bsp (synthetic BSPs, no game data) and
# q3cm.golden.txt: the answer of the real C code of cm_load.c, cm_test.c and cm_trace.c.
#   make-golden.sh <folder of build.sh>
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${1:-$HERE/out}
DATA=$HERE/../../../Tests/Data/Collision
GOLDEN=$DATA/q3cm.golden.txt
"$OUT/cmgen.exe" write 0 "$DATA/q3world0.bsp"
"$OUT/cmgen.exe" write 1 "$DATA/q3world1.bsp"
: > "$GOLDEN"
echo "bsp q3world0.bsp" >> "$GOLDEN"
"$OUT/cmgen.exe" run "$DATA/q3world0.bsp" 1001 >> "$GOLDEN"
echo "bsp q3world1.bsp" >> "$GOLDEN"
"$OUT/cmgen.exe" run "$DATA/q3world1.bsp" 77 >> "$GOLDEN"
echo "written $GOLDEN"
