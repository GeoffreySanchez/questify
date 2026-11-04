#!/usr/bin/env bash
# Publie les pages de docs/wiki/ dans le wiki GitHub du dépôt (questify.wiki.git).
# Le wiki doit déjà exister : GitHub ne crée son dépôt qu'après une première page faite sur le site.
# Usage : tools/publish_wiki.sh   (utilise le remote origin pour trouver le dépôt)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORIGIN="$(git -C "$ROOT" remote get-url origin)"
WIKI_URL="${ORIGIN%.git}.wiki.git"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/questify-wiki.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

git clone -q "$WIKI_URL" "$WORK/wiki" || {
  echo "publish_wiki.sh : wiki introuvable ($WIKI_URL). Crée d'abord une page sur le site GitHub (onglet Wiki)." >&2
  exit 1
}
cp "$ROOT"/docs/wiki/*.md "$WORK/wiki/"
cd "$WORK/wiki"
git add -A
if git diff --cached --quiet; then
  echo "Wiki déjà à jour."
  exit 0
fi
git commit -q -m "Mise à jour depuis docs/wiki ($(git -C "$ROOT" rev-parse --short HEAD))"
git push -q
echo "Wiki publié : ${ORIGIN%.git}/wiki"
