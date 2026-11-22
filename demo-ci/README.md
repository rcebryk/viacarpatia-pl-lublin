# Demo CI: Gerrit + Jenkins + AI code review

Lokalna kopia (w małej skali) pipeline'u z projektu: każda zmiana wysłana do review w Gerricie
przechodzi build z testami w Jenkinsie i recenzję AI na osobnej maszynie. Oba wyniki wracają
do Gerrita jako głosy. Wszystko działa w Dockerze, a konfiguracja jest kodem w tym katalogu.

```
 programista                  Gerrit (8081)                       Jenkins (8080)
 git push ──── refs/for/main ──► zmiana / patchset ── stream-events ──► Gerrit Trigger
                                     ▲                                   │          │
                                     │ Verified +1/-1  ◄── build-agent ◄─┘          │
                                     │ (konto jenkins)     Qt 6, CMake, SDK Yocto   │
                                     │                                              │
                                     │ Code-Review +1/-1 ◄── ai-review-vm ◄── SSH ──┘
                                     │ + komentarze        Claude API
                                     │ (konto ai-reviewer)
                                     └── merge: Verified +1 i Code-Review +2 od CZŁOWIEKA
```

| Kontener | Rola | Obraz |
|---|---|---|
| `gerrit` | code review, repozytorium `espresso-hmi` | `gerritcodereview/gerrit:3.14.5` |
| `jenkins` | CI, Gerrit Trigger, konfiguracja jako kod (JCasC) | `jenkins/jenkins:2.580.2-lts-jdk25` + wtyczki |
| `build-agent` | build, testy, cross-build aarch64 | Fedora 45, Qt 6.11, SDK z Yocto (`demo-rpi/sdk`) |
| `ai-review-vm` | „osobna maszyna wirtualna” na AI review, tylko SSH | Debian, Python, SDK Anthropic 2.4.0 |

## Uruchomienie

Wymagania: Docker z Compose, około 6 GB RAM i około 5 GB miejsca na obrazy.
Do etapu cross-build potrzebne jest SDK z Yocto w `demo-rpi/sdk`. Bez niego etap jest pomijany.

```bash
cp .env.example .env          # opcjonalnie: wpisz ANTHROPIC_API_KEY (bez klucza: AI w trybie dry-run)
./scripts/setup.sh            # pierwszy raz kilka minut (budowa obrazów)
```

Skrypt jest idempotentny. Po zmianie kodu aplikacji w `app/espresso-hmi` uruchom go ponownie,
a zsynchronizuje kod do gałęzi `main` w Gerricie. Po zmianie klucza API w `.env` uruchom
`./scripts/setup.sh`, a potem `docker compose restart jenkins`.

- Gerrit: <http://localhost:8081>, zaloguj się przez *Sign In* -> `rafal` albo `admin` (tryb deweloperski, bez hasła).
- Konto prowadzącego `rafal` (grupa Administrators: +2 i Submit) ma klucz SSH `~/.ssh/id_ed25519.pub`.
  Inne ustawienia: `PRESENTER_USER`, `PRESENTER_NAME`, `PRESENTER_KEY` przed `setup.sh`.
  `setup.sh` dopisuje klucz hosta Gerrita do `~/.ssh/known_hosts`, żeby SSH nie pytało na rzutniku.
- Projekt `espresso-hmi` ma submit type **Fast Forward Only**: zmianę da się zmergować tylko wtedy,
  gdy jej rodzic jest aktualną głową `main`. W przeciwnym razie *Rebase* tworzy nowy patchset,
  a build i AI review uruchamiają się od nowa.
- Jenkins: <http://localhost:8080>, login `admin`, hasło w `secrets/jenkins_admin_password`
  (podgląd jest dostępny bez logowania).

## Zmiana na żywo (jak w pracy)

```bash
git clone "ssh://rafal@localhost:29418/espresso-hmi" && cd espresso-hmi
scp -O -p -P 29418 rafal@localhost:hooks/commit-msg .git/hooks/   # Change-Id; -O: Gerrit nie obsługuje SFTP
git config user.name "Rafał Cebryk"; git config user.email rafal@example.com   # bez prywatnego maila na rzutniku
# ... zmiana ...  (katalogi buildu Qt Creatora ignoruje .gitignore projektu)
git commit -am "Menu: nowy napój Flat white"
git push origin HEAD:refs/for/main                                 # Gerrit wypisze link do zmiany
```

Szczegółowy przebieg z wykładu jest w notatkach slajdu „Gerrit a pull request na GitHubie”.

## Scenariusze na wykład (gotowe zmiany)

```bash
./scripts/demo-change.sh ok         # Flat white:         Verified +1, AI Code-Review +1
./scripts/demo-change.sh test-fail  # Gorąca woda, czas 0: testy FAIL -> Verified -1
./scripts/demo-change.sh ai-catch   # "Ostatni napój" w menu serwisowym, indeks -1 bez kontroli:
                                    #   testy przechodzą (Verified +1),
                                    #   AI znajduje błąd -> Code-Review -1 i komentarz przy linii
```

Puenta: testy i AI uzupełniają się nawzajem. Testy łapią regresję w logice, a AI zauważa błąd,
którego żaden test nie sprawdza. Zmiany nie da się zmergować bez **+2 od człowieka**.

Ponowne uruchomienie obu jobów dla zmiany: komentarz `recheck` w Gerricie.

## Pipeline buildu (`ci/Jenkinsfile` w repozytorium aplikacji)

1. Konfiguracja i build (Ninja, `-Werror`)
2. Testy jednostkowe QtTest, raport JUnit dla każdego testu osobno.
   Błąd testu oznacza build UNSTABLE, czyli Verified −1.
3. `qmllint` dla plików QML
4. Tłumaczenia: `lupdate`, nowe teksty do przetłumaczenia trafiają do artefaktów
5. Cross-build aarch64 toolchainem z Yocto (SDK)
6. Paczki `.tar.gz` (x86_64 i aarch64) + SHA-256 + podpis Ed25519 (klucz `secrets/app_signing_key.pem`)

Sprawdzenie podpisu paczki:
```bash
openssl pkeyutl -verify -rawin -pubin -inkey secrets/app_signing_key.pub.pem \
    -in espresso-hmi-*.tar.gz -sigfile espresso-hmi-*.tar.gz.sig
```

## AI review (`ci/ai_review.py`, `ci/ai-review-prompt.md`)

- Diff patchsetu z numerami linii trafia do Claude (`claude-opus-5-5`, effort `medium`).
  Odpowiedź przychodzi w JSON zgodnym ze schematem: plik, linia, waga, treść.
- Wynik idzie do Gerrita przez REST z konta `ai-reviewer`: komentarze przy liniach i głos
  **Code-Review −1**, jeśli jest choć jedna uwaga `error`, w przeciwnym razie **+1**.
- Gdy nie ma klucza (dry-run) albo API nie odpowiada, AI wystawia głos 0. Awaria narzędzia nie blokuje zmian.
- Prompt leży w repozytorium, więc jego zmiany przechodzą review jak kod.
- Model i effort są ustawione w `ci/Jenkinsfile.ai-review` (`AI_REVIEW_MODEL`, `AI_REVIEW_EFFORT`).
- Koszt: Claude Opus 5.5 kosztuje $4 za milion tokenów wejścia i $20 za milion tokenów wyjścia.
  Recenzja małej zmiany to zwykle kilka tysięcy tokenów, czyli około kilku centów.
  Liczba tokenów każdej recenzji jest w komentarzu w Gerricie.
- W projekcie w firmie tę rolę pełni GitHub Copilot. Architektura jest ta sama.

## Pliki

```
docker-compose.yml        4 kontenery, wolumeny Gerrita i Jenkinsa
jenkins/                  Dockerfile, plugins.txt, casc.yaml (konfiguracja jako kod)
build-agent/              obraz agenta buildu
ai-review-vm/             obraz "osobnej maszyny" AI review
common/agent-entrypoint.sh  start sshd z kluczem Jenkinsa
scripts/setup.sh          stawia wszystko (sekrety, konta Gerrita, etykieta Verified, projekt, Jenkins)
scripts/demo-change.sh    zmiany do dema
scripts/reset.sh          usuwa wszystko (kontenery, wolumeny, sekrety)
secrets/                  generowane przez setup.sh, poza gitem
```

## Uwagi
- Gerrit działa w trybie `DEVELOPMENT_BECOME_ANY_ACCOUNT`: każdy może zalogować się jako dowolny
  użytkownik. Takie ustawienie nadaje się tylko do lokalnego demo.
- Agenci przyjmują dowolny klucz hosta SSH (`nonVerifyingKeyVerificationStrategy`), co jest uproszczeniem demo.
- Sekrety (`secrets/`) Jenkins czyta przez JCasC i nigdy nie trafiają do gita.
