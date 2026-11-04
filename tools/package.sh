#!/usr/bin/env bash
# Contrôle de version puis zip pour installation manuelle.
#
# Ordre : tools/check_syntax.sh, luajit tests/run.lua, luajit tools/validate_guides.lua, cohérence des
# TOC et des fichiers listés, puis le zip dist/Questify_Vanilla-<version>-forever.zip (WoW: Forever).
# SKIP_GUIDE_VALIDATION=1 saute la validation des guides (CI sans clone).
# Le premier contrôle qui échoue arrête tout : aucun zip n'est produit.
#
# La version vient de « ## Version: » dans Questify_Vanilla/Questify_Vanilla.toc (0.1.0 si absente).
# Le dossier Questify_Vanilla/ est à la racine du zip ; LICENSE y est copiée (GPL) ; .DS_Store et
# les fichiers temporaires d'éditeur sont exclus. tests/, tools/ et docs/ n'y figurent jamais.
set -u
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDON="Questify_Vanilla"
ADDON_DIR="$ROOT/$ADDON"
TOC="$ADDON_DIR/$ADDON.toc"
TOC_FOREVER="$ADDON_DIR/${ADDON}_Camelot.toc"
DEFAULT_VERSION="0.1.0"

LUAJIT="${LUAJIT:-luajit}"
if ! command -v "$LUAJIT" >/dev/null 2>&1; then
  LUAJIT=/opt/homebrew/bin/luajit
fi

step() { printf '\n== %s\n' "$*"; }
fail() { printf 'package.sh: %s\n' "$*" >&2; exit 1; }

cd "$ROOT" || fail "dossier du projet introuvable : $ROOT"
command -v "$LUAJIT" >/dev/null 2>&1 || fail "luajit introuvable (variable LUAJIT)"
command -v zip >/dev/null 2>&1 || fail "zip introuvable"
command -v unzip >/dev/null 2>&1 || fail "unzip introuvable"
[ -f "$TOC" ] || fail "TOC introuvable : $TOC"

step "1/5 Syntaxe (tools/check_syntax.sh)"
"$ROOT/tools/check_syntax.sh" || fail "check_syntax.sh a échoué"
echo "OK"

step "2/5 Tests (luajit tests/run.lua)"
"$LUAJIT" tests/run.lua || fail "tests/run.lua a échoué"

step "3/5 Guides (luajit tools/validate_guides.lua)"
# La validation lit le clone QuestieDB de .cache/ : SKIP_GUIDE_VALIDATION=1 la saute (CI GitHub, sans clone).
if [ "${SKIP_GUIDE_VALIDATION:-0}" = "1" ]; then
  echo "Sautée (SKIP_GUIDE_VALIDATION=1)"
else
  "$LUAJIT" tools/validate_guides.lua || fail "validate_guides.lua a échoué"
fi

step "4/5 TOC et fichiers listés"
[ -f "$TOC_FOREVER" ] || fail "TOC Forever introuvable : $TOC_FOREVER"
cmp -s "$TOC" "$TOC_FOREVER" || fail "$ADDON.toc et ${ADDON}_Camelot.toc diffèrent (ils doivent être identiques)"

VERSION="$(sed -n 's/^##[[:space:]]*Version:[[:space:]]*//p' "$TOC" | head -n 1 | tr -d '\r' | sed 's/[[:space:]]*$//')"
if [ -z "$VERSION" ]; then
  echo "package.sh: pas de ligne « ## Version: » dans $ADDON.toc, version par défaut $DEFAULT_VERSION" >&2
  VERSION="$DEFAULT_VERSION"
fi
case "$VERSION" in
  *[!A-Za-z0-9._-]*|"") fail "version invalide dans le TOC : « $VERSION »" ;;
esac
echo "Version : $VERSION"

missing=0
# Fichiers du TOC : une ligne par fichier, chemins avec « \ » (lignes vides et commentaires ignorés).
while IFS= read -r line; do
  line="$(printf '%s' "$line" | tr -d '\r')"
  case "$line" in ""|"#"*) continue ;; esac
  rel="${line//\\//}"
  if [ ! -f "$ADDON_DIR/$rel" ]; then
    echo "fichier du TOC absent : $rel" >&2
    missing=1
  fi
  # Guides.xml liste un <Script file="..."/> par guide, chemins relatifs à son dossier.
  case "$rel" in
    *.xml)
      xmldir="$(dirname "$ADDON_DIR/$rel")"
      if [ -f "$ADDON_DIR/$rel" ]; then
        while IFS= read -r ref; do
          ref="${ref//\\//}"
          if [ ! -f "$xmldir/$ref" ]; then
            echo "fichier de $rel absent : $ref" >&2
            missing=1
          fi
        done < <(sed -n -E 's/.*<(Script|Include)[[:space:]][^>]*file="([^"]*)".*/\2/p' "$ADDON_DIR/$rel")
      fi
      ;;
  esac
done < "$TOC"
[ "$missing" -eq 0 ] || fail "des fichiers listés dans le TOC ou dans un XML sont absents"
echo "OK"

step "5/5 Zip (Forever)"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/questify-package.XXXXXX")" || fail "mktemp a échoué"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$ROOT/dist" || fail "création de dist/ échouée"

# stageAddon <saveur> : copie l'addon dans $STAGE/<saveur> et retire les fichiers système.
stageAddon() {
  local flavor="$1"; shift
  local dir="$STAGE/$flavor"
  mkdir -p "$dir" || fail "mkdir $dir"
  cp -R "$ADDON_DIR" "$dir/$ADDON" || fail "copie de $ADDON échouée"
  if [ -f "$ROOT/LICENSE" ]; then
    cp "$ROOT/LICENSE" "$dir/$ADDON/LICENSE" || fail "copie de LICENSE échouée"
  fi
  find "$dir" \( -name '.DS_Store' -o -name '._*' -o -name '*.swp' -o -name '*~' \) -delete
}

# zipAddon <saveur> : zippe $STAGE/<saveur>/Questify_Vanilla en dist/Questify_Vanilla-<version>-<saveur>.zip.
zipAddon() {
  ZIP="$ROOT/dist/$ADDON-$VERSION-$1.zip"
  rm -f "$ZIP"
  ( cd "$STAGE/$1" && zip -r -X -q "$ZIP" "$ADDON" ) || fail "zip $1 a échoué"
}

# checkZip <entrée requise...> : tout sous Questify_Vanilla/, rien d'interdit, entrées requises présentes.
checkZip() {
  local entries bad required
  entries="$(unzip -Z1 "$ZIP")" || fail "zip illisible : $ZIP"
  bad="$(printf '%s\n' "$entries" | grep -v "^$ADDON/" || true)"
  [ -z "$bad" ] || fail "entrées hors de $ADDON/ dans $ZIP :
$bad"
  bad="$(printf '%s\n' "$entries" | grep -E '(^|/)(\.DS_Store|tests|tools|docs|dist|\.cache|\.superpowers)(/|$)' || true)"
  [ -z "$bad" ] || fail "entrées interdites dans $ZIP :
$bad"
  for required in "$@"; do
    printf '%s\n' "$entries" | grep -qx "$ADDON/$required" || fail "absent de $ZIP : $required"
  done
  echo "OK : $ZIP ($(du -h "$ZIP" | cut -f1), $(printf '%s\n' "$entries" | wc -l | tr -d ' ') entrées)"
}

# Forever : TOC de base + _Camelot (Interface 16001), routes Forever.
stageAddon forever
zipAddon forever
checkZip "$ADDON.toc" "${ADDON}_Camelot.toc" "Guides/Guides.xml" "Guides/ClassQuestData.lua" \
  "Guides/Alliance/A_DwarfGnome_01.lua"
