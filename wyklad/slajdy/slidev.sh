#!/usr/bin/env bash
# Uruchamianie Slidev: lokalny Node.js (>= 22.12), a gdy go brak - kontener Dockera
# (albo Podmana: CONTAINER_ENGINE=podman).
#   ./slidev.sh dev      podgląd na żywo: http://localhost:3030  (prelegent: /presenter)
#   ./slidev.sh remote   jw. + dostęp z sieci i sterowanie z telefonu (opcjonalnie hasło: ./slidev.sh remote haslo)
#   ./slidev.sh lecture  na wykład (laptop A przy rzutniku): --remote z hasłem z .lecture-password,
#                        wypisuje adresy dla laptopa B (prezenter / same notatki)
#   ./slidev.sh build    statyczna strona w dist/ (na wykład, bez internetu)
#   ./slidev.sh export   PDF (kopia zapasowa)
#   ./slidev.sh npm ...  dowolne polecenie npm (np. aktualizacja zależności)
# Wymuszenie kontenera: SLIDEV_CONTAINER=1 ./slidev.sh dev
set -euo pipefail
cd "$(dirname "$0")"

# Obraz Playwright zawiera Node.js i przeglądarkę Chromium potrzebną do eksportu PDF
IMAGE="mcr.microsoft.com/playwright:v1.64.1-noble"

local_node_ok() {
    command -v node >/dev/null && command -v npm >/dev/null || return 1
    node -e 'const [a,b]=process.versions.node.split(".").map(Number); process.exit(a>22||(a===22&&b>=12)?0:1)'
}

if [[ "${SLIDEV_CONTAINER:-0}" != 1 ]] && local_node_ok; then
    MODE=local
    run() { "$@"; }
else
    MODE=container
    CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
    TTY=(); [[ -t 0 ]] && TTY=(-it)
    # pliki tworzone w kontenerze mają należeć do nas, nie do roota
    if [[ "$CONTAINER_ENGINE" == podman ]]; then
        USER_ARGS=(--userns=keep-id)
    else
        USER_ARGS=(--user "$(id -u):$(id -g)" -e HOME=/tmp)
    fi
    run() {
        # label=disable: SELinux bez przeetykietowania całego katalogu (z node_modules)
        "$CONTAINER_ENGINE" run --rm "${TTY[@]}" "${USER_ARGS[@]}" \
            --security-opt label=disable \
            -v "$PWD:/slajdy" -w /slajdy \
            -e npm_config_cache=/slajdy/.npm-cache \
            -e PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
            -p 3030:3030 \
            "$IMAGE" "$@"
    }
fi
echo ">> Slidev: tryb $MODE" >&2

cmd="${1:-dev}"; shift || true
if [[ "$cmd" != npm && ! -d node_modules ]]; then
    if [[ -f package-lock.json ]]; then run npm ci; else run npm install; fi
fi

case "$cmd" in
    dev)
        # W kontenerze serwer musi nasłuchiwać na 0.0.0.0 - to robi --remote
        if [[ "$MODE" == container ]]; then run npm run dev:remote -- "$@"; else run npm run dev -- "$@"; fi ;;
    remote)
        # Hasło chroni sterowanie prezentacją przed innymi osobami w tej samej sieci
        if [[ $# -gt 0 ]]; then run npx slidev --port 3030 --remote "$1"; else run npm run dev:remote; fi ;;
    lecture)
        # Hasło trzymamy poza gitem; przy pierwszym uruchomieniu powstaje losowe
        [[ -s .lecture-password ]] || od -An -N5 -tx1 /dev/urandom | tr -d ' \n' >.lecture-password
        pw="$(tr -d '[:space:]' <.lecture-password)"
        echo
        echo "== Laptop A (rzutnik):  http://localhost:3030/   (pełny ekran: f)"
        echo "   Otwórz przez localhost - tylko wtedy przewijanie na A synchronizuje się z B."
        echo "== Laptop B (adresy laptopa A w sieci):"
        for ip in $(ip -4 -o addr show scope global 2>/dev/null | awk '$2 !~ /^(docker|br-|veth|virbr)/ {sub(/\/.*/, "", $4); print $4}'); do
            echo "   prezenter:     http://$ip:3030/presenter/?password=$pw"
            echo "   same notatki:  http://$ip:3030/notes   (tylko śledzi prezentację, bez przewijania)"
        done
        if command -v firewall-cmd >/dev/null; then
            echo "   Jeśli B się nie łączy: sudo firewall-cmd --add-port=3030/tcp   (do restartu systemu)"
        fi
        echo
        run npx slidev --port 3030 --remote "$pw" ;;
    build)  run npm run build -- "$@" ;;
    export)
        # Lokalnie Chromium dla Playwright pobiera się raz, do ~/.cache/ms-playwright
        [[ "$MODE" == local ]] && run npx playwright install chromium
        run npm run export -- "$@" ;;
    npm)    run npm "$@" ;;
    *)      echo "Użycie: $0 {dev|remote|lecture|build|export|npm ...}" >&2; exit 1 ;;
esac
