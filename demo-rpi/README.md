# Demo: Yocto + Qt 6 na Raspberry Pi 3B+ (HMI ekspresu do kawy)

Materiał do wykładu „Wdrażanie i eksploatacja systemów informatycznych”.
Budujemy własny Linux dla Raspberry Pi 3B+ z oficjalnym ekranem 7" DSI,
na którym po starcie uruchamia się aplikacja Qt 6/QML udająca HMI ekspresu.

| Element | Wersja |
|---|---|
| Yocto Project | 6.0.4 „wrynose” (LTS, wsparcie do 04.2030) |
| Qt | 6.12 (meta-qt6, open source) |
| Maszyna | `raspberrypi3-64` (aarch64) |
| Grafika | eglfs + KMS/DRM, bez X11/Wayland |
| Init | systemd |
| Narzędzie buildu | kas 5.5 w kontenerze (Docker; Podman: `KAS_CONTAINER_ENGINE=podman`) |

## Struktura

```
kas/rpi3-qt6.yml          cała konfiguracja buildu: warstwy + przypięte commity + local.conf
meta-espresso/            nasza warstwa Yocto
  recipes-core/images/    obraz espresso-image (+ SDK)
  recipes-apps/           receptura aplikacji + usługa systemd + konfiguracja KMS
  recipes-qt/qt6/         qtbase_%.bbappend - przykład modyfikacji cudzej receptury
  recipes-core/espresso-network/  stały adres 192.168.77.2 na Ethernecie
  recipes-core/os-release/  wersja systemu w /etc/os-release (menu serwisowe)
scripts/                  build, SDK, flash, deploy, demo awarii
CHANGELOG.md              wersje systemu (ESPRESSO_SYSTEM_VERSION w kas/rpi3-qt6.yml)
```

## Przygotowanie (przed wykładem, raz)

Polecenia uruchamiaj z katalogu `demo-rpi/`. Wymagania: Docker (użytkownik w grupie `docker`), ok. 100 GB wolnego miejsca, kilka godzin na pierwszy build.

```bash
./scripts/build.sh          # pobiera kas-container, buduje obraz (1. raz: kilka godzin)
./scripts/build-sdk.sh      # buduje i instaluje SDK do ./sdk (kompilator aarch64 + Qt)
./scripts/flash.sh /dev/sdX # zapis na kartę SD (sprawdź urządzenie: lsblk!)
./scripts/laptop-net.sh     # Ethernet laptopa = 192.168.77.1
ping 192.168.77.2           # RPi po starcie
```

Cache (`~/yocto-cache/downloads`, `~/yocto-cache/sstate-cache`) sprawia, że kolejne
buildy trwają minuty. Warto zanotować czas pierwszego buildu - to gotowy slajd.

## Scenariusz demo na wykładzie

**1. „Jak powstał ten system” (blok Yocto)**
- `kas/rpi3-qt6.yml` - warstwy, przypięte commity (powtarzalność!), `MACHINE`, `DISTRO`.
- `meta-espresso/recipes-apps/espresso-hmi/espresso-hmi_1.0.bb` - receptura aplikacji.
- `meta-espresso/recipes-qt/qt6/qtbase_%.bbappend` - modyfikacja cudzej receptury.
- Czas buildu: od zera vs z cache sstate (`./scripts/build.sh` z gorącym cache).
- Build w kontenerze: Fedora hosta nie jest wspierana przez Yocto - kontener to rozwiązuje.

**2. „Zmieniam aplikację na żywo” (blok wdrażania)**
1. Pokaż ekran z 6 napojami.
2. W `../app/espresso-hmi/src/core/drinkcatalog.cpp` (aplikacja jest wspólna dla obu dem) dopisz do `defaultMenu()`:
   ```cpp
   { QCoreApplication::translate("DrinkCatalog", "Flat white"), 160, QStringLiteral("#b5835a"), 6, true },
   ```
   i zmień `VERSION 1.0.0` -> `1.1.0` w `CMakeLists.txt`.
   Siatka ma 3 kolumny, więc 7. napój trafi do 3. rzędu - albo zamień nim „Gorąca woda”.
3. `./scripts/deploy.sh` - cross-kompilacja + scp + restart usługi (kilka sekund).
4. Menu serwisowe (przytrzymaj logo 2 s): nowa wersja aplikacji, ta sama wersja systemu.
   To jest właśnie „paczka aplikacji” vs „obraz systemu” z prawdziwych maszyn.

**3. „Aplikacja się wywraca” (blok eksploatacji)**
- Menu serwisowe -> „Symuluj awarię” (abort) albo `./scripts/crash-demo.sh` (kill -9).
- Ekran wraca po ok. 1 s - `Restart=always` w usłudze systemd.
- `journalctl -u espresso-hmi` - log awarii i licznik restartów (`NRestarts`).

## Qt Creator: cross-kompilacja i debugowanie na RPi

`./scripts/install-sdk.sh` instaluje SDK do `/opt/poky/6.0.4` (ok. 26 s). Konfiguracja zestawu (kit)
Qt Creatora, wdrażanie i zdalne debugowanie (gdbserver) krok po kroku: [QTCREATOR.md](QTCREATOR.md).

## Alternatywa bez SDK: devtool

```bash
./scripts/build.sh espresso-hmi                              # tylko aplikacja
./scripts/shell.sh
devtool deploy-target -s espresso-hmi root@192.168.77.2      # w powłoce kontenera
```

## Zabezpieczenie demo
- Druga karta SD z gotowym obrazem.
- Nagrane wideo z całego demo.
- Kabel Ethernet laptop <-> RPi zamiast Wi-Fi uczelni.
- Kamera dokumentowa / telefon na statywie - ekran 7" jest niewidoczny z sali.
- Konsola szeregowa (UART na GPIO 14/15, 115200) na wypadek, gdyby ekran i sieć zawiodły.

## Rozwiązywanie problemów
- **Czarny ekran, aplikacja działa** - sprawdź nazwę wyjścia:
  `QT_QPA_EGLFS_DEBUG=1 QT_LOGGING_RULES="qt.qpa.*=true" espresso-hmi` (po `systemctl stop espresso-hmi`)
  i popraw `name` w `/etc/espresso-hmi/kms.json` (np. `DSI-1`).
- **Testy na monitorze HDMI** - w `kms.json` zamień tryby: DSI `off`, HDMI `preferred`.
- **Obraz do góry nogami** (zależy od obudowy) - dodaj `lcd_rotate=2` do `RPI_EXTRA_CONFIG`.
- **Brak dotyku** - `ls /dev/input/`, `dmesg | grep -i ft5`; sterownik `edt-ft5x06`.
- **Brak pamięci przy buildzie Qt** - zmniejsz `BB_NUMBER_THREADS`/`PARALLEL_MAKE` w `kas/rpi3-qt6.yml`.

## Uwaga o bezpieczeństwie
Obraz ma root bez hasła i otwarty SSH (`empty-root-password`, `allow-root-login`).
To świadome uproszczenie na potrzeby demo - dobry punkt do dyskusji, czym różni
się obraz deweloperski od produkcyjnego.
