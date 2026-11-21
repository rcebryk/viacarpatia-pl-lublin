#!/usr/bin/env bash
# Usuwa całe demo CI: kontenery, wolumeny (Gerrit, Jenkins), sekrety i robocze klony.
# Potem ./scripts/setup.sh stawia wszystko od zera. Obrazy Dockera zostają (szybki restart).
source "$(dirname "$0")/lib.sh"

if [[ "${1:-}" != "--yes" ]]; then
    read -r -p "Usunąć Gerrita, Jenkinsa, wszystkie zmiany i sekrety demo? [t/N] " ans
    [[ "$ans" == "t" || "$ans" == "T" ]] || exit 1
fi
dc down -v --remove-orphans
rm -rf "$SECRETS" "$CI_DIR/work"
log "Demo CI usunięte. Start od zera: ./scripts/setup.sh"
