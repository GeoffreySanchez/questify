#!/bin/sh
# Rend les aperçus (maquettes) de l'interface en PNG 1920 x 1080 avec Chrome sans interface.
# Usage : sh docs/media/apercus/src/render.sh [fichier.html ...]   (sans argument : tous)
#   Un fichier de src/ est rendu dans apercus/, un fichier de src/en/ (version anglaise) dans
#   apercus/en/ : le PNG garde le sous-dossier de sa source. Sans argument : src/*.html puis
#   src/en/*.html.
# Les icônes sont chargées depuis wow.zamimg.com au rendu : il faut une connexion.
# Profil Chrome jetable (dossier temporaire) : le profil de l'utilisateur n'est jamais touché.
set -eu
SRC=$(cd "$(dirname "$0")" && pwd)
OUT=$(dirname "$SRC")
CHROME=${CHROME:-"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"}
PROFILE=$(mktemp -d "${TMPDIR:-/tmp}/questify-apercus.XXXXXX")
trap 'rm -rf "$PROFILE"' EXIT
if [ "$#" -eq 0 ]; then
  set -- "$SRC"/*.html
  for html in "$SRC"/en/*.html; do
    if [ -f "$html" ]; then set -- "$@" "$html"; fi
  done
fi
for html in "$@"; do
  name=$(basename "$html" .html)
  dir=$(cd "$(dirname "$html")" && pwd)
  # sous-dossier de la source par rapport à src/ ("" ou "/en"), repris pour le PNG
  sub=${dir#"$SRC"}
  if [ "$sub" = "$dir" ]; then
    echo "render.sh: $html n'est pas dans $SRC" >&2
    exit 1
  fi
  mkdir -p "$OUT$sub"
  "$CHROME" --headless=new --user-data-dir="$PROFILE" --no-first-run --no-default-browser-check \
    --disable-extensions --hide-scrollbars --force-device-scale-factor=1 --window-size=1920,1080 \
    --virtual-time-budget=10000 --screenshot="$OUT$sub/$name.png" "file://$dir/$name.html" >/dev/null 2>&1
  echo "$OUT$sub/$name.png"
done
