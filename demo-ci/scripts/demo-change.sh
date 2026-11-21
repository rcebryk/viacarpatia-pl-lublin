#!/usr/bin/env bash
# Demo na wykład: tworzy zmianę w aplikacji i wysyła ją do review w Gerricie.
#
#   ./scripts/demo-change.sh ok         nowy napój "Flat white"  -> Verified +1, AI: Code-Review +1
#   ./scripts/demo-change.sh test-fail  "Gorąca woda" z czasem 0  -> testy FAIL, Verified -1
#   ./scripts/demo-change.sh ai-catch   "ostatni napój" w menu serwisowym, indeks -1 bez sprawdzenia
#                                       -> Verified +1 (testy go nie widzą), AI: Code-Review -1 z komentarzem
# Każde wywołanie to nowa zmiana oparta na aktualnym main.
source "$(dirname "$0")/lib.sh"

variant="${1:-}"
[[ "$variant" =~ ^(ok|test-fail|ai-catch)$ ]] || die "Użycie: $0 ok|test-fail|ai-catch"
[[ -f "$SECRETS/gerrit_admin_password" ]] || die "Najpierw uruchom ./scripts/setup.sh"

WORK="$CI_DIR/work/espresso-hmi"
remote="$(admin_git_url)"
if [[ ! -d "$WORK/.git" ]]; then
    git clone -q "$remote" "$WORK"
    curl -fsS -o "$WORK/.git/hooks/commit-msg" "$GERRIT_URL/tools/hooks/commit-msg"   # Change-Id
    chmod +x "$WORK/.git/hooks/commit-msg"
fi
cd "$WORK"
git remote set-url origin "$remote"
git fetch -q origin
git checkout -q -B demo origin/main
git config user.name "Administrator"
git config user.email "admin@example.com"

edit() {  # edit PLIK STARY NOWY - podmiana fragmentu, błąd gdy fragmentu brak
    python3 - "$@" <<'EOF'
import sys
path, old, new = sys.argv[1:4]
s = open(path, encoding="utf-8").read()
if old not in s:
    sys.exit(f"nie znaleziono fragmentu w {path}")
open(path, "w", encoding="utf-8").write(s.replace(old, new, 1))
EOF
}

case "$variant" in
ok)
    edit src/core/drinkcatalog.cpp \
'        { QCoreApplication::translate("DrinkCatalog", "Latte"),       250, QStringLiteral("#d2ab7e"), 9, true  },' \
'        { QCoreApplication::translate("DrinkCatalog", "Latte"),       250, QStringLiteral("#d2ab7e"), 9, true  },
        { QCoreApplication::translate("DrinkCatalog", "Flat white"),  160, QStringLiteral("#b5835a"), 6, true  },'
    edit CMakeLists.txt 'project(espresso-hmi VERSION 1.0.0' 'project(espresso-hmi VERSION 1.1.0'
    git commit -qam "Menu: nowy napój Flat white" \
        -m "Flat white (160 ml, z mlekiem) na życzenie klientów sieci kawiarni. Wersja 1.1.0."
    ;;
test-fail)
    # Reguła biznesowa: czas parzenia musi być dodatni - pilnuje jej test defaultMenuIsValid
    edit src/core/drinkcatalog.cpp \
'"Gorąca woda"), 200, QStringLiteral("#5d7b8c"), 4, false },' \
'"Gorąca woda"), 200, QStringLiteral("#5d7b8c"), 0, false },'
    git commit -qam "Gorąca woda: bez czasu parzenia" \
        -m "Woda leci od razu, nie ma czego parzyć."
    ;;
ai-catch)
    # "Ostatni napój" w menu serwisowym. Błąd: lastDrink startuje od -1, a drinkName() nie sprawdza
    # zakresu - menu serwisowe otwarte przed pierwszą kawą czyta poza listą (w release: zwykle crash).
    # Testy UI nie otwierają menu serwisowego, więc przechodzą.
    edit src/app/menu.h \
'    Q_INVOKABLE int stepIndexAt(int stepCount, double progress) const;' \
'    Q_INVOKABLE int stepIndexAt(int stepCount, double progress) const;
    Q_INVOKABLE QString drinkName(int index) const;'
    cat >> src/app/menu.cpp <<'CPP'

QString Menu::drinkName(int index) const
{
    return m_drinks[index].name;
}
CPP
    edit qml/Main.qml \
'            required property var modelData
' \
'            required property var modelData
            required property int index
'
    edit qml/Main.qml \
'                onClicked: brew.start(cell.modelData)' \
'                onClicked: {
                    brew.start(cell.modelData)
                    service.lastDrink = cell.index
                }'
    edit qml/ServicePanel.qml \
'    id: panel
' \
'    id: panel

    property int lastDrink: -1
'
    edit qml/ServicePanel.qml \
'        uptimeText.text = MachineInfo.uptime()
        visible = true' \
'        uptimeText.text = MachineInfo.uptime()
        lastDrinkName.text = Menu.drinkName(lastDrink)
        visible = true'
    edit qml/ServicePanel.qml \
'            Text { id: uptimeText; color: "white"; font.pixelSize: 20 }' \
'            Text { id: uptimeText; color: "white"; font.pixelSize: 20 }
            Text { text: qsTr("Ostatni napój:"); color: "#cbb39b"; font.pixelSize: 20 }
            Text { id: lastDrinkName; color: "white"; font.pixelSize: 20 }'
    git commit -qam "Menu serwisowe: ostatni wydany napój" \
        -m "Technik widzi w menu serwisowym nazwę ostatnio wybranego napoju."
    ;;
esac

log "Wysyłam zmianę do review (refs/for/main)"
git push origin HEAD:refs/for/main 2>&1 | grep -oE "$GERRIT_URL/c/[^ ]+" || true
echo "   Jenkins: $JENKINS_URL  (joby espresso-hmi-build i espresso-hmi-ai-review)"
