# Wspólne funkcje skryptów demo CI (dołączane przez "source")
set -euo pipefail

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$CI_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/app/espresso-hmi"
SECRETS="$CI_DIR/secrets"

GERRIT_URL="${GERRIT_URL:-http://localhost:8081}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
PROJECT="espresso-hmi"
# Konto prowadzącego w Gerricie (klucz SSH z ~/.ssh), na wykład: klon, push, +2
PRESENTER_USER="${PRESENTER_USER:-rafal}"
PRESENTER_NAME="${PRESENTER_NAME:-Rafał Cebryk}"
PRESENTER_KEY="${PRESENTER_KEY:-$HOME/.ssh/id_ed25519.pub}"
# SDK z Yocto (demo-rpi/sdk) montowany do agenta buildu pod tą samą ścieżką
export ESPRESSO_SDK_DIR="${ESPRESSO_SDK_DIR:-$REPO_ROOT/demo-rpi/sdk}"

log()  { printf '\033[1;34m>> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mXX %s\033[0m\n' "$*" >&2; exit 1; }

# docker bez ponownego logowania po dodaniu do grupy "docker"
dc() {
    if docker info >/dev/null 2>&1; then
        docker compose -f "$CI_DIR/docker-compose.yml" "$@"
    else
        sg docker -c "docker compose -f '$CI_DIR/docker-compose.yml' $(printf '%q ' "$@")"
    fi
}

dk() {
    if docker info >/dev/null 2>&1; then
        docker "$@"
    else
        sg docker -c "docker $(printf '%q ' "$@")"
    fi
}

# Odpowiedź REST Gerrita zaczyna się od ")]}'" (ochrona przed XSSI) - usuwamy ją
gerrit_json() { sed '1{/^)]}'"'"'$/d}'; }

admin_pw() { cat "$SECRETS/gerrit_admin_password"; }

# Adres repozytorium z hasłem admina; hasło może zawierać "/" i "+", więc je kodujemy
admin_git_url() {
    local pw; pw="$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$(admin_pw)")"
    echo "http://admin:${pw}@localhost:8081/a/$PROJECT"
}

# gerrit_api METODA ŚCIEŻKA [JSON] - wywołanie REST jako admin (Basic auth, prefiks /a/)
gerrit_api() {
    local method="$1" path="$2" data="${3:-}"
    local args=(-sS -u "admin:$(admin_pw)" -X "$method" -w '\n%{http_code}')
    [[ -n "$data" ]] && args+=(-H 'Content-Type: application/json; charset=UTF-8' --data-binary "$data")
    curl "${args[@]}" "$GERRIT_URL/a$path"
}

# zwraca kod HTTP z ostatniej linii odpowiedzi gerrit_api
http_code() { tail -n1; }

wait_for_url() {
    local url="$1" name="$2" tries="${3:-90}"
    for _ in $(seq 1 "$tries"); do
        curl -s -o /dev/null "$url" && return 0
        sleep 2
    done
    die "$name nie odpowiada pod $url"
}
