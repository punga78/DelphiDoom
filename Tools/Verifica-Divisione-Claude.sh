#!/bin/bash
# Issue #178: verifica che la divisione di CLAUDE.md non abbia perso righe e che i link relativi funzionino.
# Uso (dalla radice del repository, con Git Bash):  bash Tools/Verifica-Divisione-Claude.sh [revisione-originale]
# La revisione predefinita e' il commit che precede la divisione (HEAD~1 dopo il commit, altrimenti HEAD).
REV=${1:-HEAD}
TMP=$(mktemp -d)
git show "$REV:CLAUDE.md" > "$TMP/orig.md" || exit 2
grep -v '^[[:space:]]*$' "$TMP/orig.md" | tr -d '\r' > "$TMP/orig.lines"

# tutti i file nuovi
FILES=$(ls CLAUDE.md docs/CLAUDE_TRASVERSALI.md; find Libs -name CLAUDE.md)
cat $FILES | tr -d '\r' > "$TMP/new.all"

TOTAL=$(wc -l < "$TMP/orig.lines")
grep -v -x -F -f "$TMP/new.all" "$TMP/orig.lines" > "$TMP/missing.lines"
MISSING=$(wc -l < "$TMP/missing.lines")
echo "Righe non vuote dell'originale: $TOTAL"
echo "Righe mancanti: $MISSING"
[ "$MISSING" -gt 0 ] && cut -c1-120 "$TMP/missing.lines"

# link relativi nei markdown nuovi
BROKEN=0
for f in $FILES $(find Libs -name README.md); do
  dir=$(dirname "$f")
  grep -o -E '\]\([^)#]+(#[^)]*)?\)' "$f" | sed -E 's/^\]\(//; s/\)$//; s/#.*//' | while read -r link; do
    case "$link" in http*|mailto:*|"") continue;; esac
    if [ ! -e "$dir/$link" ]; then echo "LINK ROTTO in $f: $link"; fi
  done
done > "$TMP/broken.txt"
BROKEN=$(wc -l < "$TMP/broken.txt")
echo "Link relativi rotti: $BROKEN"
cat "$TMP/broken.txt"
rm -rf "$TMP"
[ "$MISSING" -eq 0 ] && [ "$BROKEN" -eq 0 ]
