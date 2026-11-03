#!/usr/bin/env bash
# Vérification syntaxique de tous les fichiers Lua du projet (addon, outils, tests).
# Compile chaque fichier avec luajit -bl (aucune exécution) et refuse la syntaxe Lua 5.2+
# que LuaJIT accepte mais que le client WoW (Lua 5.1) refuse : goto et étiquettes ::nom::.
# Sans erreur : aucune sortie, code de retour 0.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LUAJIT="${LUAJIT:-luajit}"
if ! command -v "$LUAJIT" >/dev/null 2>&1; then
  LUAJIT=/opt/homebrew/bin/luajit
fi
status=0
while IFS= read -r -d '' file; do
  if ! out=$("$LUAJIT" -bl "$file" 2>&1 >/dev/null); then
    echo "$out"
    status=1
  fi
  case "$file" in
    "$ROOT"/Questify_Vanilla/*)
      if grep -nE '^[[:space:]]*goto[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*(--.*)?$|::[A-Za-z_][A-Za-z0-9_]*::' "$file" >/dev/null; then
        grep -nE '^[[:space:]]*goto[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*(--.*)?$|::[A-Za-z_][A-Za-z0-9_]*::' "$file" \
          | sed "s|^|$file:|; s|\$| (goto/labels are not Lua 5.1)|"
        status=1
      fi
      ;;
  esac
done < <(find "$ROOT/Questify_Vanilla" "$ROOT/tools" "$ROOT/tests" -type f -name '*.lua' -print0 2>/dev/null)
exit $status
