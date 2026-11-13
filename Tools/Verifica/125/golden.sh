#!/bin/sh
# Rebuilds the parity driver and writes the golden files of Tests\Data\Gui\golden.
#   golden.sh <work folder>
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
OUT=${1:-$HERE/out}
sh "$HERE/build.sh" "$OUT"
for S in menus menulist broken fonts scripts input input2; do
  "$OUT/uiparse.exe" "$REPO/Tests/Data/Gui/files" "$REPO/Tests/Data/Gui/scenarios/$S.txt" > "$REPO/Tests/Data/Gui/golden/$S.golden.txt"
done
echo "goldens written"
