#!/bin/sh
# Writes Tests/Data/Pmove/pmove-golden.txt: the answer of the real C code of Quake III (bg_pmove.c,
# bg_slidemove.c) on 192 scenarios of commands over a made up world.
#   make-golden.sh <folder of build.sh>
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${1:-$HERE/out}
GOLDEN=$HERE/../../../Tests/Data/Pmove/pmove-golden.txt
mkdir -p "$(dirname "$GOLDEN")"
"$OUT/pmgen.exe" golden 2> "$OUT/coverage.txt" | tr -d '\r' > "$GOLDEN"
cat "$OUT/coverage.txt"
echo "written $GOLDEN"
