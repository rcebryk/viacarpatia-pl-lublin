#!/usr/bin/env bash
# Stawia całe demo CI od zera (idempotentnie - można uruchamiać wielokrotnie):
#   1. sekrety: klucze SSH, klucz podpisu paczek, hasła (demo-ci/secrets/, poza gitem)
#   2. Gerrit: konta jenkins i ai-reviewer, etykieta Verified, projekt espresso-hmi z kodem
#   3. Jenkins + agenci (konfiguracja jako kod: jenkins/casc.yaml)
source "$(dirname "$0")/lib.sh"

# --- 1. sekrety ----------------------------------------------------------------
make_secrets() {
    mkdir -p "$SECRETS"
    chmod 700 "$SECRETS"
    local f
    for f in jenkins_agent_key gerrit_jenkins_key; do
        [[ -f "$SECRETS/$f" ]] || ssh-keygen -q -t ed25519 -N '' -C "$f" -f "$SECRETS/$f"
    done
    # klucz podpisu paczek aplikacji ("klucze aktualizacji aplikacji")
    if [[ ! -f "$SECRETS/app_signing_key.pem" ]]; then
        openssl genpkey -algorithm ed25519 -out "$SECRETS/app_signing_key.pem" 2>/dev/null
        openssl pkey -in "$SECRETS/app_signing_key.pem" -pubout -out "$SECRETS/app_signing_key.pub.pem"
    fi
    for f in jenkins_admin_password gerrit_ai_reviewer_password gerrit_jenkins_password gerrit_presenter_password; do
        [[ -f "$SECRETS/$f" ]] || openssl rand -base64 18 | tr -d '/+=' > "$SECRETS/$f"
    done
    # klucz Claude API z .env (pusty = AI review w trybie dry-run)
    local key=""
    [[ -f "$CI_DIR/.env" ]] && key="$(sed -n 's/^ANTHROPIC_API_KEY=//p' "$CI_DIR/.env" | tail -n1)"
    printf '%s' "$key" > "$SECRETS/anthropic_api_key"
    # Prywatne tylko dla właściciela. Jenkins w kontenerze działa jako UID 1000,
    # agenci czytają tylko klucze publiczne (*.pub)
    chmod 600 "$SECRETS"/*
    chmod 644 "$SECRETS"/*.pub "$SECRETS"/*.pub.pem
    chmod 755 "$SECRETS"
}

# --- 2. Gerrit -----------------------------------------------------------------
gerrit_admin_login() {
    # Tryb DEVELOPMENT_BECOME_ANY_ACCOUNT: logowanie jako admin (konto 1000000) bez hasła,
    # potem generujemy hasło HTTP do REST API.
    local jar; jar="$(mktemp)"
    curl -s -c "$jar" -b "$jar" -o /dev/null "$GERRIT_URL/login/?account_id=1000000"
    curl -s -c "$jar" -b "$jar" -o /dev/null "$GERRIT_URL/"
    local xsrf; xsrf="$(awk '$6=="XSRF_TOKEN"{print $7}' "$jar")"
    curl -s -b "$jar" -H "X-Gerrit-Auth: $xsrf" -H 'Content-Type: application/json' \
         -X PUT -d '{"generate":true}' "$GERRIT_URL/accounts/self/password.http" \
        | gerrit_json | tr -d '"\n' > "$SECRETS/gerrit_admin_password"
    rm -f "$jar"
    [[ -s "$SECRETS/gerrit_admin_password" ]] || die "Nie udało się zalogować do Gerrita jako admin"
}

ensure_group() {   # ensure_group NAZWA -> wypisuje UUID grupy
    local name="$1" out enc
    enc="$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$name")"
    out="$(gerrit_api GET "/groups/$enc")"
    if [[ "$(http_code <<<"$out")" != 200 ]]; then
        out="$(gerrit_api PUT "/groups/$enc" '{"visible_to_all":true}')"
    fi
    sed '$d' <<<"$out" | gerrit_json | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'
}

ensure_account() { # ensure_account LOGIN NAZWA PLIK_HASŁA [PLIK_KLUCZA_PUB] [GRUPA]
    local user="$1" name="$2" pwfile="$3" keyfile="${4:-}" group="${5:-Service Users}"
    local body
    body="$(python3 - "$user" "$name" "$pwfile" "$keyfile" "$group" <<'EOF'
import json, sys
user, name, pwfile, keyfile, group = sys.argv[1:6]
d = {"name": name, "email": f"{user}@example.com",
     "http_password": open(pwfile).read().strip(), "groups": [group]}
if keyfile:
    d["ssh_key"] = open(keyfile).read().strip()
print(json.dumps(d))
EOF
)"
    case "$(gerrit_api PUT "/accounts/$user" "$body" | http_code)" in
        201) log "Gerrit: utworzono konto $user" ;;
        409) # konto już jest - odświeżamy hasło (sekret mógł zostać wygenerowany na nowo)
             gerrit_api PUT "/accounts/$user/password.http" \
                 "{\"http_password\":\"$(cat "$pwfile")\"}" >/dev/null ;;
        *)   die "Gerrit: nie udało się utworzyć konta $user" ;;
    esac
}

# Konto prowadzącego: klon/push przez SSH z własnym kluczem, +2 i Submit na wykładzie
ensure_presenter() {
    if [[ ! -f "$PRESENTER_KEY" ]]; then
        warn "Brak klucza $PRESENTER_KEY - pomijam konto $PRESENTER_USER (ustaw PRESENTER_KEY)"
        return 0
    fi
    ensure_account "$PRESENTER_USER" "$PRESENTER_NAME" "$SECRETS/gerrit_presenter_password" \
        "$PRESENTER_KEY" Administrators
    # Klucz hosta Gerrita do known_hosts - bez pytania "Are you sure...?" na rzutniku.
    # Po reset.sh Gerrit ma nowy klucz, więc stary wpis usuwamy.
    ssh-keygen -q -R "[localhost]:29418" >/dev/null 2>&1 || true
    ssh-keyscan -q -p 29418 -t ed25519,rsa localhost 2>/dev/null >> "$HOME/.ssh/known_hosts"
}

configure_gerrit() {
    log "Gerrit: logowanie jako admin"
    gerrit_admin_login

    ensure_account jenkins "Jenkins CI" "$SECRETS/gerrit_jenkins_password" "$SECRETS/gerrit_jenkins_key.pub"
    ensure_account ai-reviewer "AI Reviewer (Claude)" "$SECRETS/gerrit_ai_reviewer_password"
    ensure_presenter

    # Tylko grupa "CI Builders" (Jenkins) może głosować Verified
    local builders; builders="$(ensure_group "CI Builders")"
    gerrit_api PUT "/groups/CI%20Builders/members/jenkins" >/dev/null

    # Etykieta Verified (-1/0/+1) w All-Projects + wymóg przy merge
    if [[ "$(gerrit_api GET /projects/All-Projects/labels/Verified | http_code)" != 200 ]]; then
        log "Gerrit: etykieta Verified"
        gerrit_api PUT /projects/All-Projects/labels/Verified '{
            "commit_message": "Etykieta Verified: wynik buildu i testów z Jenkinsa",
            "function": "NoBlock",
            "values": {" 0": "Brak wyniku", "-1": "Build albo testy nie przeszły", "+1": "Build i testy przeszły"},
            "default_value": 0,
            "copy_condition": "changekind:NO_CODE_CHANGE"
        }' >/dev/null
        gerrit_api PUT /projects/All-Projects/submit_requirements/Verified '{
            "name": "Verified",
            "description": "Zmiana musi mieć Verified +1 od CI i żadnego -1.",
            "submittability_expression": "label:Verified=MAX AND -label:Verified=MIN",
            "allow_override_in_child_projects": false
        }' >/dev/null
    fi
    gerrit_api POST /projects/All-Projects/access "{
        \"add\": {\"refs/heads/*\": {\"permissions\": {\"label-Verified\": {\"rules\": {
            \"$builders\": {\"action\": \"ALLOW\", \"min\": -1, \"max\": 1}}}}}}
    }" >/dev/null

    # Projekt z kodem aplikacji
    if [[ "$(gerrit_api GET "/projects/$PROJECT" | http_code)" != 200 ]]; then
        log "Gerrit: projekt $PROJECT"
        gerrit_api PUT "/projects/$PROJECT" '{
            "description": "Espresso HMI - aplikacja Qt/QML ekspresu (demo wykładu)",
            "create_empty_commit": true, "branches": ["main"]
        }' >/dev/null
    fi
    # Submit tylko fast-forward (jak w projekcie u nas): rodzic zmiany musi być aktualną
    # głową main, inaczej rebase -> nowy patchset -> build i AI review od nowa.
    # Dzięki temu Verified +1 dotyczy dokładnie tego commita, który trafi do main.
    [[ "$(gerrit_api PUT "/projects/$PROJECT/config" '{"submit_type": "FAST_FORWARD_ONLY"}' | http_code)" == 200 ]] \
        || die "Gerrit: nie udało się ustawić submit type FAST_FORWARD_ONLY"
    # Administratorzy mogą wypchnąć kod prosto na main (import, synchronizacja);
    # zwykłe zmiany idą przez review: refs/for/main
    local admins; admins="$(ensure_group Administrators)"
    gerrit_api POST "/projects/$PROJECT/access" "{
        \"add\": {\"refs/heads/*\": {\"permissions\": {\"push\": {\"rules\": {
            \"$admins\": {\"action\": \"ALLOW\"}}}}}}
    }" >/dev/null
    sync_app
}

sync_app() {
    # Kod aplikacji z repozytorium wykładu -> gałąź main w Gerricie (z pominięciem review:
    # to "stan wyjściowy" dema; zmiany na wykładzie idą już przez refs/for/main)
    local tmp; tmp="$(mktemp -d)"
    git clone -q "$(admin_git_url)" "$tmp/repo"
    find "$tmp/repo" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
    cp -a "$APP_DIR/." "$tmp/repo/"
    (
        cd "$tmp/repo"
        git add -A
        if git diff --cached --quiet; then
            log "Gerrit: kod aplikacji aktualny"
        else
            log "Gerrit: synchronizacja kodu z app/espresso-hmi"
            git -c user.name="Administrator" -c user.email="admin@example.com" \
                commit -q -m "Espresso HMI: synchronizacja z repozytorium wykładu" \
                -m "Źródło: app/espresso-hmi ($(git -C "$REPO_ROOT" rev-parse --short HEAD))."
            git push -q origin HEAD:refs/heads/main
        fi
    )
    rm -rf "$tmp"
}

# Zmiana wypchnięta, zanim Gerrit Trigger połączy się z Gerritem, nie uruchomi CI
# (Gerrit bez pluginu events-log nie odtwarza pominiętych zdarzeń) - czekamy na połączenie
wait_for_gerrit_trigger() {
    local since cid
    cid="$(dc ps -q jenkins)"
    since="$(dk inspect -f '{{.State.StartedAt}}' "$cid" | tr -d '[:space:]')"
    log "Czekam, aż Gerrit Trigger połączy się z Gerritem"
    for _ in $(seq 1 90); do
        # bez "| grep -q": przy pipefail przerwany potok dawałby fałszywy wynik
        if grep -q "Ready to receive data from Gerrit" <<<"$(dc logs --since "$since" jenkins 2>/dev/null)"; then
            return 0
        fi
        sleep 2
    done
    warn "Gerrit Trigger nie zgłosił połączenia - sprawdź: docker compose logs jenkins"
}

# --- przebieg -------------------------------------------------------------------
make_secrets
log "Uruchamiam Gerrita"
dc up -d gerrit
wait_for_url "$GERRIT_URL/config/server/version" Gerrit
configure_gerrit

if grep -q '^  jenkins:' "$CI_DIR/docker-compose.yml"; then
    log "Uruchamiam Jenkinsa i agentów (pierwszy raz: budowa obrazów)"
    dc up -d --build
    wait_for_url "$JENKINS_URL/login" Jenkins 150
    wait_for_gerrit_trigger
fi

log "Gotowe"
echo "   Gerrit:  $GERRIT_URL   (logowanie: Sign In -> admin)"
echo "   Jenkins: $JENKINS_URL  (admin / $(cat "$SECRETS/jenkins_admin_password"))"
