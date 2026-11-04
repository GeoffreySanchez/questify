#!/bin/bash
# Télécharge les tables DB2 lues par build_spells.lua dans tools/routebuilder/data/.
# Usage : bash tools/spells/fetch_db2.sh [--force]   (sans --force, les fichiers présents sont conservés)
set -euo pipefail
BUILD="1.60.1.70707"
TABLES="SkillLineAbility SpellLevels SpellName SpellMisc SpellEffect Talent TraitDefinition"
cd "$(dirname "$0")/../routebuilder/data"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1
for t in $TABLES; do
  if [ -s "$t.csv" ] && [ "$FORCE" = 0 ]; then echo "skip $t.csv"; continue; fi
  echo "fetch $t.csv"
  # Téléchargement vers un fichier temporaire (ignoré par git) : un échec ne touche pas le CSV existant.
  if ! curl -fsSL -o "$t.csv.tmp" "https://wago.tools/db2/$t/csv?build=$BUILD"; then
    echo "échec du téléchargement de $t (HTTP non 200)" >&2
    exit 1
  fi
  mv "$t.csv.tmp" "$t.csv"
done
