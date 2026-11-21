---
# Ustawienia całej prezentacji
theme: default
title: Od commita do filiżanki espresso
info: |
  Wdrażanie i eksploatacja systemów informatycznych.
  Wykład dla 3. roku Informatyki, Politechnika Lubelska.
colorSchema: dark
canvasWidth: 1280
aspectRatio: 16/9
fonts:
  provider: none
transition: fade
mdc: true
exportFilename: wyklad-od-commita-do-filizanki
layout: cover
subtitle: Rafał Cebryk
---

# Od commita do filiżanki espresso

CI/CD i eksploatacja oprogramowania HMI w ekspresach do kawy

<p class="vc-cover-course">Wdrażanie i eksploatacja systemów informatycznych</p>

---

# O mnie

<div class="vc-cards vc-about-stats" style="--cols: 4; margin-bottom: 18px">
  <div class="vc-card">
    <div class="vc-stat">16 lat</div>
    <div class="vc-stat-label">w IT</div>
  </div>
  <div class="vc-card">
    <div class="vc-stat">12 lat</div>
    <div class="vc-stat-label">w Mobica, obecnie części Cognizant</div>
  </div>
  <div class="vc-card">
    <div class="vc-stat">9. rok</div>
    <div class="vc-stat-label">w projekcie dla wiodącego włoskiego producenta maszyn vendingowych</div>
  </div>
  <div class="vc-card vc-card-light">
    <div class="vc-stat">duuużo</div>
    <div class="vc-stat-label">maszyn w terenie</div>
  </div>
</div>

<div class="vc-cards" style="--cols: 2">
  <div class="vc-card">
    <h3>Role</h3>
    <ul style="display: grid; grid-template-columns: 1fr 1fr; column-gap: 24px">
      <li>Konsultant</li>
      <li>Programista C++/Qt</li>
      <li>Architekt</li>
      <li>DevOps</li>
    </ul>
  </div>
  <div class="vc-card">
    <h3>Na co dzień</h3>
    <ul>
      <li>HMI dla ekspresów HoReCa i automatów vendingowych</li>
      <li>Gerrit, Jenkins, Docker, Yocto</li>
      <li>Automatyczne code review z AI</li>
    </ul>
  </div>
</div>

<style>
.vc-about-stats .vc-stat { font-size: 46px; }
.vc-about-stats .vc-stat-label { font-size: 19px; }
</style>

---
layout: agenda
---

# Plan prezentacji

1. Kontekst: aplikacja webowa a HMI na maszynie
2. Gerrit i CI: dwa repozytoria, dwa pipeline'y
3. AI w code review
4. Fabryka obrazów: Docker + Yocto
5. Wdrażanie: jak nowa wersja trafia do maszyny
6. Eksploatacja w terenie

---
layout: section
---

# Kontekst

Aplikacja webowa a HMI na maszynie

---

# Czym jest HMI w ekspresie do kawy

<div class="vc-cards">
  <div class="vc-card">
    <h3>Sprzęt</h3>
    <p>Płytka z procesorem ARM, Linux, ekran dotykowy. Zasoby jak w telefonie sprzed lat.</p>
  </div>
  <div class="vc-card">
    <h3>Oprogramowanie</h3>
    <p>Aplikacja C++/Qt na cały ekran: wybór napoju, receptury, menu serwisowe.</p>
  </div>
  <div class="vc-card">
    <h3>Użytkownicy</h3>
    <p>Klient kawiarni, barista, serwisant. Żaden z nich nie jest administratorem.</p>
  </div>
</div>

<div class="vc-note">HoReCa: hotele, restauracje, kawiarnie. Vending: automaty samoobsługowe.</div>

---
layout: two-cols
---

# Wdrożenie: web a maszyna w kawiarni

### Aplikacja webowa

- serwery w naszych rękach
- wdrożenie: minuty, wiele razy dziennie
- rollback jednym kliknięciem
- monitoring w czasie rzeczywistym

::right::

### HMI ekspresu

- tysiące maszyn u klientów, często offline
- aktualizacja: serwisant z pendrive'em
- 10+ lat życia produktu
- „admin” to barista

---

# Ograniczenia, które zmieniają wszystko

<div class="vc-cards">
  <div class="vc-card">
    <div class="vc-stat">24/7</div>
    <div class="vc-stat-label">praca bez restartów i bez nadzoru</div>
  </div>
  <div class="vc-card">
    <div class="vc-stat">offline</div>
    <div class="vc-stat-label">część maszyn nigdy nie widzi internetu</div>
  </div>
  <div class="vc-card">
    <div class="vc-stat">10+ lat</div>
    <div class="vc-stat-label">tyle trzeba utrzymywać wydane wersje</div>
  </div>
</div>

<div class="vc-note">Każdy błąd wdrożenia kosztuje dojazd serwisanta, nie tylko kliknięcie „rollback”.</div>

---
layout: section
---

# Gerrit i CI

Bramka jakości przed każdą zmianą

---

# Droga commita

<div class="vc-flow">
  <div class="vc-flow-lane">Repozytorium<br>aplikacji<small>C++ / Qt</small></div>
  <div class="vc-flow-box">git push</div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">Gerrit<small>review: ludzie + AI</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box vc-flow-build">
    <b>Jenkins</b>
    <ul>
      <li>build</li>
      <li>testy jednostkowe</li>
      <li>aktualizacja plików .ts (tłumaczenia)</li>
      <li>klucze aktualizacji aplikacji</li>
    </ul>
  </div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box vc-flow-artifact">Paczka<br>aplikacji</div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box vc-flow-machine">Maszyna<br>u klienta</div>

  <div class="vc-flow-link">▲ toolchain do cross-kompilacji</div>

  <div class="vc-flow-lane vc-r3">Repozytorium<br>Yocto<small>warstwy, receptury</small></div>
  <div class="vc-flow-box vc-r3">git push</div>
  <div class="vc-flow-arrow vc-r3">→</div>
  <div class="vc-flow-box vc-r3">Gerrit<small>review: ludzie + AI</small></div>
  <div class="vc-flow-arrow vc-r3">→</div>
  <div class="vc-flow-box vc-flow-build vc-r3">
    <b>Jenkins</b>
    <ul>
      <li>bitbake: obraz systemu</li>
      <li>toolchain do cross-kompilacji</li>
      <li>klucze aktualizacji systemu</li>
    </ul>
  </div>
  <div class="vc-flow-arrow vc-r3">→</div>
  <div class="vc-flow-box vc-flow-artifact vc-r3">Obraz<br>systemu</div>
  <div class="vc-flow-arrow vc-r3">→</div>
</div>

---
layout: two-cols
---

# Gerrit a pull request na GitHubie

### Pull request

- gałąź z wieloma commitami
- poprawki = kolejne commity
- review całej gałęzi naraz

::right::

### Gerrit

- review **pojedynczego commita**
- poprawka = nowy **patchset** tego samego commita (`git commit --amend`)
- `Change-Id` w opisie wiąże patchsety ze sobą
- push na `refs/for/main`, nie na `main`

---

# Głosy: kto pozwala na merge

| Etykieta | Kto głosuje | Wartości | Znaczenie |
|---|---|---|---|
| **Code-Review** | ludzie (AI tylko ±1) | −2 … +2 | +2 = „zatwierdzam”, −2 = blokada |
| **Verified** | Jenkins | −1 … +1 | build i testy przeszły |

<div class="vc-note">Merge (submit) dopiero przy Code-Review +2 i Verified +1. Żadna zmiana nie trafia do <code>main</code> bez buildu.<br>U nas submit tylko <b>fast-forward</b>: rodzic zmiany musi być aktualną głową gałęzi.</div>

---

# Gerrit Trigger: Jenkins reaguje na każdy patchset

<div class="vc-file">app/espresso-hmi/ci/Jenkinsfile <span>(uproszczony)</span></div>

```groovy {1-2|4|6-8|all}
// Uruchamia Gerrit Trigger; zmiana jest już pobrana (konfiguracja joba)
// Zmienne od triggera: GERRIT_REFSPEC, GERRIT_PATCHSET_REVISION...
pipeline {
  agent { docker { image 'registry.local/qt-sdk:latest' } }
  stages {
    stage('Build') { steps { sh 'cmake -B build -G Ninja && cmake --build build' } }
    stage('Testy') { steps { sh 'ctest --test-dir build --output-on-failure' } }
    stage('.ts')   { steps { sh 'cmake --build build --target update_translations' } }
  }
}
```

---
layout: two-cols
---

# Build w kontenerze, nie na laptopie

### Bez kontenera

- „u mnie działa”
- każdy ma inną wersję kompilatora i Qt
- nowy programista: dzień instalowania

::right::

### Z obrazem Dockera

- to samo środowisko na laptopie i w Jenkinsie
- toolchain z Yocto zainstalowany w obrazie
- wersja obrazu = wersja środowiska

```dockerfile
FROM ubuntu:24.04
COPY sdk-installer.sh /tmp/
RUN /tmp/sdk-installer.sh -y -d /opt/sdk
```

---
layout: section
---

# AI w code review

Automatyczny recenzent w pipeline Jenkinsa

---

# Problem: review jest wąskim gardłem

<div class="vc-cards">
  <div class="vc-card">
    <h3>Czekanie</h3>
    <p>Zmiana czeka na recenzenta dniami. U nas cel: najwyżej 48 h.</p>
  </div>
  <div class="vc-card">
    <h3>Pośpiech</h3>
    <p>Komuś się spieszy: +2 „na szybko”, żeby przepchnąć zmianę.</p>
  </div>
  <div class="vc-card">
    <h3>Rutyna</h3>
    <p>Ludzie tracą czas na literówki, styl i oczywiste błędy.</p>
  </div>
</div>

<div class="vc-note">Cel: AI robi pierwsze przejście w kilka minut, człowiek skupia się na logice i architekturze.</div>

---

# Architektura

<div class="vc-chain vc-chain-md">
  <div class="vc-flow-box">Programista<small>git push</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">Gerrit<small>nowy patchset</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">Gerrit Trigger<small>zdarzenie</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">Jenkins<small>pipeline AI review</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box vc-flow-artifact">Agent na VM<small>Copilot CLI w Bubblewrap; demo: Claude API</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">Gerrit<small>komentarze w kodzie</small></div>
</div>

<div class="vc-file" style="margin-top: 10px; margin-bottom: 0">app/espresso-hmi/ci/Jenkinsfile.ai-review <span>(skrót)</span></div>

<div style="--slidev-code-font-size: 16px">

```groovy
pipeline {
  agent { label 'ai-review' }       // osobna maszyna, Jenkins łączy się przez SSH
  stages { stage('AI review') { steps {
    withCredentials([...]) {        // konto ai-reviewer w Gerricie + klucz API
      sh 'python ci/ai_review.py'   // diff -> Claude -> komentarze + Code-Review ±1
    } } } }
}
```

</div>

---

# Decyzje projektowe

<div class="vc-cards" style="--cols: 3">
  <div class="vc-card">
    <h3>Dlaczego osobna VM?</h3>
    <ul>
      <li>izolacja: agent nie widzi reszty infrastruktury</li>
      <li>osobne poświadczenia i licencja</li>
      <li>długie i nieprzewidywalne zadania nie blokują buildów</li>
    </ul>
  </div>
  <div class="vc-card">
    <h3>Czy AI może głosować?</h3>
    <ul>
      <li>komentarz: tak</li>
      <li>−1: tak, gdy jest pewne, że coś jest nie tak</li>
      <li>+1: tak, jako sygnał „nie widzę problemów”</li>
      <li>+2 i −2: nigdy, decyduje człowiek</li>
    </ul>
  </div>
  <div class="vc-card">
    <h3>Jak duża zmiana?</h3>
    <ul>
      <li>limit rozmiaru zmiany (u nas ok. 3000 plików)</li>
      <li>koszt i szum rosną z rozmiarem diffu</li>
      <li>każdy nowy patchset = review od nowa</li>
    </ul>
  </div>
</div>

---

# Ryzyka

<div class="vc-cards" style="--cols: 5">
  <div class="vc-card">
    <h3>Dane</h3>
    <p>Kod klienta wychodzi poza firmę. Co mówi umowa?</p>
  </div>
  <div class="vc-card">
    <h3>Szum i halucynacje</h3>
    <p>Dużo uwag spoza zmiany albo o sytuacjach niemożliwych.</p>
  </div>
  <div class="vc-card">
    <h3>Koszty</h3>
    <p>Licencje, czas VM, czas ludzi na fałszywe alarmy.</p>
  </div>
  <div class="vc-card">
    <h3>Zmiany modelu</h3>
    <p>Nowa wersja modelu = zmiana zachowania pipeline'u.</p>
  </div>
  <div class="vc-card">
    <h3>Prompt injection</h3>
    <p>Kod w zmianie może zawierać instrukcje dla AI.</p>
  </div>
</div>

<div class="vc-note">Prompt i model to konfiguracja produkcyjna: wersjonujemy je i przeglądamy jak kod.</div>

---

# Wdrożenie i eksploatacja recenzenta AI

<div class="vc-chain vc-chain-md">
  <div class="vc-flow-box">1. Lokalnie<small>skill code review na commicie z Gerrita</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">2. Interaktywnie<small>link do zmiany → raport → człowiek wybiera uwagi → Gerrit</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box vc-flow-artifact">3. Job w Jenkinsie<small>ręcznie, na produkcyjnych zmianach (jesteśmy tu)</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">4. Gerrit Trigger<small>każdy nowy patchset automatycznie</small></div>
</div>

<div class="vc-cards vc-cards-lg" style="--cols: 2; margin-top: 20px">
  <div class="vc-card">
    <h3>Reakcja zespołu</h3>
    <p>Najpierw opór: „AI marnuje nasz czas na nieprawdziwe uwagi”. Pomogło ograniczenie szumu.</p>
  </div>
  <div class="vc-card">
    <h3>Co mierzymy</h3>
    <p>Jeszcze nic. Następny krok: trafne uwagi, fałszywe alarmy, czas, koszt.</p>
  </div>
</div>

<div class="vc-note" style="margin-top: 12px">Recenzent AI to też system informatyczny: ma swoje wdrożenie, awarie i utrzymanie.</div>

---
layout: section
---

# Demo: AI review

Zmiana z celowym błędem. Czy AI go znajdzie?

---
layout: section
---

# Fabryka obrazów

Docker + Yocto: budujemy cały system operacyjny

---

# Dlaczego budujemy własny Linux?

<div class="vc-cards" style="--cols: 2">
  <div class="vc-card">
    <h3>Gotowa dystrybucja</h3>
    <ul>
      <li>setki zbędnych pakietów</li>
      <li>aktualizacje w rytmie dystrybucji, nie produktu</li>
      <li>trudno odtworzyć dokładnie ten sam system za 5 lat</li>
    </ul>
  </div>
  <div class="vc-card vc-card-light">
    <h3>Yocto Project</h3>
    <ul>
      <li>w obrazie tylko to, czego potrzebujemy</li>
      <li>pełna kontrola wersji każdego pakietu</li>
      <li>ten sam przepis = ten sam system, także za 10 lat</li>
    </ul>
  </div>
</div>

---
layout: two-cols
---

# Yocto w jednym slajdzie

<div class="vc-stack">
  <div class="vc-layer vc-layer-ours">meta-espresso<small>nasza warstwa: aplikacja, obraz</small></div>
  <div class="vc-layer">meta-qt6<small>biblioteki Qt 6</small></div>
  <div class="vc-layer">meta-raspberrypi<small>BSP (Board Support Package): kernel, bootloader</small></div>
  <div class="vc-layer">meta-openembedded<small>dodatkowe pakiety</small></div>
  <div class="vc-layer">openembedded-core + poky<small>podstawowe pakiety i klasy + dystrybucja referencyjna</small></div>
  <div class="vc-layer vc-layer-tool">bitbake<small>narzędzie budujące</small></div>
</div>

::right::

- **warstwa**: repozytorium z przepisami
- **receptura** (`.bb`): jak zbudować jeden pakiet
- **`.bbappend`**: zmiana cudzej receptury bez jej edycji
- **`.bbclass`**: wspólna logika receptur (`inherit`)
- **obraz**: lista pakietów → system na kartę SD
- **bitbake**: wykonuje tysiące zadań, cache w **sstate**

---

# Co spina cały system?

<div class="vc-deps">
  <div class="vc-deps-col">
    <div class="vc-deps-title">konfiguracja buildu</div>
    <div class="vc-flow-box vc-flow-artifact">kas/rpi3-qt6.yml<small>warstwy z przypiętym commitem, MACHINE, DISTRO, target</small></div>
    <div class="vc-flow-arrow">↓ <small>kas generuje</small></div>
    <div class="vc-flow-box">local.conf + bblayers.conf<small>ustawienia buildu i lista warstw dla bitbake</small></div>
  </div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-deps-col">
    <div class="vc-deps-title">bitbake espresso-image</div>
    <div class="vc-flow-box">espresso-image.bb<small>obraz: lista pakietów (IMAGE_INSTALL) + SDK</small></div>
    <div class="vc-deps-sub">
      <div class="vc-flow-box"><span class="nw">espresso-hmi_1.0.bb</span><small>aplikacja z <span class="nw">app/espresso-hmi</span></small></div>
      <div class="vc-flow-box"><span class="nw">espresso-network_1.0.bb</span><small>sieć: DHCP + stały adres</small></div>
      <div class="vc-flow-box">qtbase_%.bbappend<small>Qt rysuje przez eglfs</small></div>
      <div class="vc-flow-box">kernel, bootloader, Qt…<small>receptury z warstw społeczności</small></div>
    </div>
  </div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-deps-col">
    <div class="vc-deps-title">wynik</div>
    <div class="vc-flow-box vc-flow-artifact">obraz .wic.bz2<small>karta SD → Raspberry Pi</small></div>
    <div class="vc-flow-box vc-flow-artifact">SDK (instalator .sh)<small>toolchain + Qt → Qt Creator, Jenkins</small></div>
  </div>
</div>

<div class="vc-note">Wszystkie pliki: <code>demo-rpi/kas/</code> i <code>demo-rpi/meta-espresso/</code></div>

---

# Cały system w jednym pliku

<div class="vc-file">demo-rpi/kas/rpi3-qt6.yml <span>(skrót)</span></div>

<div style="--slidev-code-font-size: 16px">

```yaml {all|1-2|4-7|8|9-12}
machine: raspberrypi3-64
distro: poky
repos:
  core:
    url: https://git.openembedded.org/openembedded-core
    tag: yocto-6.0.4
    commit: 0f03c732a0a2d0506b41b1abe60b3f368b2300dc
  # ... meta-raspberrypi, meta-qt6, meta-espresso
local_conf_header:
  10_system: |
    INIT_MANAGER = "systemd"
    DISTRO_FEATURES:remove = "x11 wayland"
```

</div>

---

# Receptura aplikacji

<div class="vc-file">demo-rpi/meta-espresso/recipes-apps/espresso-hmi/espresso-hmi_1.0.bb <span>(skrót)</span></div>

<div style="--slidev-code-font-size: 17px">

```bash {1-3|4-5|6-7|8-9|all}
SUMMARY = "Espresso HMI - demonstracyjny interfejs ekspresu do kawy (Qt 6 / QML)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
FILESEXTRAPATHS:prepend := "${THISDIR}/../../../../app:${THISDIR}/files:"
SRC_URI = "file://espresso-hmi/ file://espresso-hmi.service file://kms.json"
inherit qt6-cmake systemd
EXTRA_OECMAKE += "-DESPRESSO_BUILD_TESTS=OFF"
SYSTEMD_SERVICE:${PN} = "espresso-hmi.service"
RDEPENDS:${PN} += "qtbase-plugins qtdeclarative-qmlplugins liberation-fonts"
```

</div>

<div class="vc-note">W produkcji zamiast <code>file://</code>: <code>git://…;protocol=ssh</code> + <code>SRCREV</code> – obraz przypina dokładny commit aplikacji.</div>

---

# `.bbappend`: zmiana cudzej receptury

```bash
# meta-espresso/recipes-qt/qt6/qtbase_%.bbappend
#
# Qt ma rysować bezpośrednio na ekranie przez DRM/KMS (eglfs),
# z akceleracją OpenGL ES; dotyk obsługuje libinput.
# :class-target = tylko Qt dla RPi, nie wersja budowana na hoście
PACKAGECONFIG:append:class-target = " eglfs gbm gles2 kms libinput fontconfig"
```

<div class="vc-note">Nie forkujemy <code>meta-qt6</code>. Nasza zmiana żyje w naszej warstwie i przeżyje aktualizację Qt.</div>

---

# Ile to trwa?

<div class="vc-cards">
  <div class="vc-card">
    <div class="vc-stat">2,5 h</div>
    <div class="vc-stat-label">pierwszy build obrazu z Qt 6, od zera (5735 zadań)</div>
  </div>
  <div class="vc-card">
    <div class="vc-stat">2 min</div>
    <div class="vc-stat-label">przebudowa obrazu po zmianie, z cache sstate</div>
  </div>
  <div class="vc-card">
    <div class="vc-stat">32 GB</div>
    <div class="vc-stat-label">na dysku: źródła 11 GB, sstate 7 GB, build 14 GB; obraz to 130 MB</div>
  </div>
</div>

<div class="vc-note">Dlatego Jenkins ma współdzielony cache, a build Yocto nie startuje przy każdej zmianie aplikacji.</div>

---
layout: section
---

# Demo: jak powstał ten system

Raspberry Pi 3B+, ekran 7", Yocto 6.0 + Qt 6

---
layout: section
---

# Wdrażanie

Jak nowa wersja trafia do maszyny

---

# Cztery kanały aktualizacji

| Kanał | Co aktualizuje | Skala | Ryzyko |
|---|---|---|---|
| Pendrive aplikacji | aplikację | jedna maszyna | stara lub zła paczka |
| Pendrive systemu | cały system, czyści partycję aplikacji | jedna maszyna | długi przestój, potem trzeba wgrać aplikację |
| Upload przez chmurę | aplikację | wiele maszyn | przerwana transmisja |
| Urządzenie szeregowe | aplikację | jedna maszyna | wolny transfer |

<div class="vc-note">Pełnego OTA jeszcze nie ma: najczęściej jedzie serwisant z pendrive'em.</div>

---
layout: two-cols
---

# Paczka aplikacji a obraz systemu

### Paczka aplikacji

- mała, wgrywana często
- osobna partycja aplikacji
- każdy kanał: pendrive, chmura, łącze szeregowe

::right::

### Obraz systemu

- duży, wgrywany rzadko
- czyści partycję aplikacji: start od czystego stanu
- nowy system nie zobaczy starej, niepasującej aplikacji

<div class="vc-note">Aktualizacja systemu czyści też dane maszyny: technik robi backup ustawień i importuje go po wgraniu.</div>

---

# Klucze: maszyna instaluje tylko nasze paczki

<div class="vc-chain vc-chain-lg">
  <div class="vc-flow-box">Jenkins<small>podpisuje paczkę kluczem prywatnym</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box vc-flow-artifact">Paczka + podpis<small>pendrive / chmura / szeregowo</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">Maszyna<small>sprawdza podpis kluczem publicznym z obrazu systemu</small></div>
</div>

<div class="vc-cards vc-cards-lg" style="--cols: 2; margin-top: 28px">
  <div class="vc-card">
    <h3>Osobne klucze</h3>
    <p>Inne dla aktualizacji aplikacji, inne dla systemu. Wyciek jednego nie otwiera wszystkiego.</p>
  </div>
  <div class="vc-card">
    <h3>Pytanie do sali</h3>
    <p>Co się stanie, gdy ktoś podłączy do maszyny własny pendrive?</p>
  </div>
</div>

---

# SDK: toolchain z Yocto w Qt Creatorze

<div class="vc-chain">
  <div class="vc-flow-box">bitbake<small>-c populate_sdk</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box vc-flow-artifact">Instalator SDK<small>jeden plik .sh, 1,3 GB</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">/opt/poky/6.0.4<small>26 s, 7,3 GB</small></div>
  <div class="vc-flow-arrow">→</div>
  <div class="vc-flow-box">Qt Creator<small>kit "RPi 3 (Yocto)"</small></div>
</div>

<div class="vc-cards" style="--cols: 3; margin-top: 24px">
  <div class="vc-card">
    <h3>Toolchain</h3>
    <ul>
      <li>aarch64-poky-linux-g++</li>
      <li>Qt6Toolchain.cmake</li>
      <li>sysroot = biblioteki z obrazu</li>
    </ul>
  </div>
  <div class="vc-card">
    <h3>Urządzenie</h3>
    <ul>
      <li>Remote Linux: 192.168.77.2</li>
      <li>deploy przez rsync / SFTP</li>
      <li>Run = start na ekranie 7"</li>
    </ul>
  </div>
  <div class="vc-card">
    <h3>Debug</h3>
    <ul>
      <li>aarch64-poky-linux-gdb</li>
      <li>gdbserver na RPi</li>
      <li>breakpoint na urządzeniu</li>
    </ul>
  </div>
</div>

---

# Demo: zmiana na żywo

````md magic-move
```cpp
QList<Drink> defaultMenu()
{
    return {
        { tr("Espresso"),   30,  "#8d5b3c", 5, false },
        { tr("Cappuccino"), 180, "#c08f62", 8, true  },
        { tr("Latte"),      250, "#d2ab7e", 9, true  },
    };
}
```
```cpp
QList<Drink> defaultMenu()
{
    return {
        { tr("Espresso"),   30,  "#8d5b3c", 5, false },
        { tr("Cappuccino"), 180, "#c08f62", 8, true  },
        { tr("Latte"),      250, "#d2ab7e", 9, true  },
        { tr("Flat white"), 160, "#b5835a", 6, true  },
    };
}
```
````

<div class="vc-note"><code>./scripts/deploy.sh</code>: cross-kompilacja, scp, restart usługi. Kilka sekund.</div>

---

# Kierunek rozwoju: OTA

<div class="vc-cards" style="--cols: 2">
  <div class="vc-card">
    <h3>Partycje A/B</h3>
    <ul>
      <li>nowy system zapisujemy na nieaktywną partycję</li>
      <li>restart do nowej wersji</li>
      <li>nie wstała? bootloader wraca do starej</li>
      <li>narzędzia: RAUC, SWUpdate, Mender</li>
    </ul>
  </div>
  <div class="vc-card vc-card-light">
    <h3>Cyber Resilience Act (UE)</h3>
    <ul>
      <li>obowiązek zgłaszania podatności od 09.2026</li>
      <li>pełne wymagania od 12.2027</li>
      <li>producent musi dostarczać poprawki bezpieczeństwa przez lata</li>
    </ul>
  </div>
</div>

---
layout: section
---

# Eksploatacja

W kawiarni nie ma administratora

---

# Projektuj pod awarię

```ini {5-6|all}
[Service]
ExecStart=/usr/bin/espresso-hmi
Environment=QT_QPA_PLATFORM=eglfs

Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
```

<div class="vc-note">Aplikacja się wywróci? <code>systemd</code> podniesie ją po sekundzie. Nikt nie musi przyjeżdżać.</div>

---

# Co widzi serwisant

<div class="vc-cards" style="--cols: 2">
  <div class="vc-card">
    <h3>Menu serwisowe</h3>
    <ul>
      <li>wersja aplikacji i systemu</li>
      <li>czas pracy</li>
      <li>identyfikator maszyny</li>
    </ul>
  </div>
  <div class="vc-card">
    <h3>Logi</h3>
    <ul>
      <li><code>journalctl -u espresso-hmi</code></li>
      <li>liczba restartów usługi</li>
      <li>co zebrać, zanim zgłosi problem</li>
    </ul>
  </div>
</div>

<div class="vc-note">Pierwsze pytanie przy każdym zgłoszeniu: jaka wersja jest na tej maszynie?</div>

---
layout: section
---

# Demo: aplikacja się wywraca

Menu serwisowe → „Symuluj awarię”

---

# Ćwiczenie: błąd bezpieczeństwa w terenie

<div class="vc-big">W aplikacji wykryto podatność. Macie 3000 maszyn: 60% z dostępem do chmury, reszta offline w różnych krajach.</div>

<div class="vc-cards" style="--cols: 3; margin-top: 28px">
  <div class="vc-card"><h3>Jak wdrożycie poprawkę?</h3></div>
  <div class="vc-card"><h3>W jakiej kolejności?</h3></div>
  <div class="vc-card"><h3>Skąd będziecie wiedzieć, że się udało?</h3></div>
</div>

---

# Podsumowanie

<div class="vc-cards" style="--cols: 3">
  <div class="vc-card"><h3>Wdrożenie zaczyna się przy commicie</h3><p>review, build, testy, zanim cokolwiek trafi do main</p></div>
  <div class="vc-card"><h3>Powtarzalność</h3><p>przypięte wersje, kontenery, konfiguracja jako kod</p></div>
  <div class="vc-card"><h3>Aplikacja osobno od systemu</h3><p>różne cykle życia, różne kanały aktualizacji</p></div>
  <div class="vc-card"><h3>Podpisuj, co instalujesz</h3><p>klucze w pipeline, weryfikacja na maszynie</p></div>
  <div class="vc-card"><h3>Projektuj pod awarię</h3><p>system sam wraca do działania, wersja zawsze widoczna</p></div>
  <div class="vc-card"><h3>AI pomaga, człowiek odpowiada</h3><p>recenzent AI to też system do utrzymania</p></div>
</div>

---

# Czego szukają pracodawcy w embedded i DevOps

<div class="vc-cards" style="--cols: 3">
  <div class="vc-card">
    <h3>Fundamenty</h3>
    <ul>
      <li>C/C++</li>
      <li>Linux: systemd, sieć, shell</li>
      <li>Git na poziomie rebase i review</li>
    </ul>
  </div>
  <div class="vc-card">
    <h3>Automatyzacja</h3>
    <ul>
      <li>CI/CD: Jenkins, GitLab CI</li>
      <li>kontenery</li>
      <li>Yocto lub Buildroot</li>
    </ul>
  </div>
  <div class="vc-card">
    <h3>Nawyki</h3>
    <ul>
      <li>czytanie cudzego kodu</li>
      <li>dobre opisy commitów</li>
      <li>myślenie o tym, co po wdrożeniu</li>
    </ul>
  </div>
</div>

---
layout: end
subtitle: Rafał Cebryk
---

## Pytania?

Kod demo i slajdy:<br>github.com/rcebryk/viacarpatia-pl-lublin

<img class="vc-qr" src="/qr-repo.svg" alt="Kod QR: github.com/rcebryk/viacarpatia-pl-lublin" />

