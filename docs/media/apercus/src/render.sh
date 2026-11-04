#!/bin/sh
# Rend les aperçus (maquettes) de l'interface en PNG 1920 x 1080 avec Chrome sans interface.
# Usage : sh docs/media/apercus/src/render.sh [fichier.html ...]   (sans argument : tous)
# Les icônes sont chargées depuis wow.zamimg.com au rendu : il faut une connexion.
# Profil Chrome jetable (dossier temporaire) : le profil de l'utilisateur n'est jamais touché.
set -eu
SRC=$(cd "$(dirname "$0")" && pwd)
OUT=$(dirname "$SRC")
CHROME=${CHROME:-"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"}
PROFILE=$(mktemp -d "${TMPDIR:-/tmp}/questify-apercus.XXXXXX")
trap 'rm -rf "$PROFILE"' EXIT
if [ "$#" -eq 0 ]; then set -- "$SRC"/*.html; fi
for html in "$@"; do
  name=$(basename "$html" .html)
  "$CHROME" --headless=new --user-data-dir="$PROFILE" --no-first-run --no-default-browser-check \
    --disable-extensions --hide-scrollbars --force-device-scale-factor=1 --window-size=1920,1080 \
    --virtual-time-budget=10000 --screenshot="$OUT/$name.png" "file://$SRC/$name.html" >/dev/null 2>&1
  echo "$OUT/$name.png"
done
