# Qt Creator: cross-kompilacja i debugowanie na Raspberry Pi

Zestaw (kit) Qt Creatora, który buduje aplikację `app/espresso-hmi` toolchainem z Yocto,
wgrywa ją na RPi i debuguje na urządzeniu (gdbserver w obrazie deweloperskim).

## 1. SDK (26 s)

```bash
./scripts/install-sdk.sh            # -> /opt/poky/6.0.4
```

SDK przypina się do katalogu przy instalacji. Po przeniesieniu katalogu zainstaluj je ponownie.
Wszystkie ścieżki niżej są względem `/opt/poky/6.0.4` (dalej: `SDK`):

| Element | Ścieżka |
|---|---|
| plik toolchaina CMake | `SDK/sysroots/x86_64-pokysdk-linux/usr/share/cmake/Qt6Toolchain.cmake` |
| kompilator C++ | `SDK/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-g++` |
| kompilator C | `SDK/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-gcc` |
| debugger | `SDK/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-gdb` |
| Qt (qmake) | `SDK/sysroots/x86_64-pokysdk-linux/usr/bin/qmake` (Qt 6.12.1) |
| sysroot | `SDK/sysroots/cortexa53-nocrypto-poky-linux` |

`Qt6Toolchain.cmake` generuje meta-qt6 z myślą o IDE. Ma ścieżki względne, nie potrzebuje
`environment-setup` i sam ustawia kompilator, flagi procesora, sysroot oraz `QT_HOST_PATH`.
Sprawdzone: w czystym środowisku systemowe CMake z tym plikiem buduje binarkę aarch64.

## 2. Urządzenie

*Edit → Preferences → Devices → Add → Remote Linux Device*
- Host: `192.168.77.2` (kabel Ethernet, `./scripts/laptop-net.sh` na laptopie), port 22, użytkownik `root`
- Uwierzytelnianie: obraz deweloperski ma roota bez hasła. Jeśli kreator poprosi o klucz:
  `ssh-copy-id root@192.168.77.2`. Po każdym nagraniu karty trzeba to powtórzyć, bo klucz jest w rootfs.
- *Test*: Qt Creator sprawdzi połączenie i narzędzia na urządzeniu. Wymaga m.in. `base64`
  (bez niego test kończy się „Device test failed”), więc obraz ma busybox z włączonym `base64`
  (`meta-espresso/recipes-core/busybox/`) oraz `rsync`.

## 3. Składniki zestawu

*Edit → Preferences → Kits*:
1. **Compilers → Add → GCC → C++** (i osobno C): ścieżki z tabeli. Nazwa: `Yocto 6.0 aarch64 GCC`.
2. **Debuggers → Add**: `aarch64-poky-linux-gdb`. Nazwa: `Yocto 6.0 aarch64 GDB`.
3. **Qt Versions → Add**: `qmake` z SDK. Nazwa: `Qt 6.12.1 (Yocto, RPi 3)`.
   Qt Creator pokaże ostrzeżenie o braku przykładów i dokumentacji, co jest normalne dla Qt z SDK.

## 4. Zestaw (kit)

*Kits → Add*, nazwa `Espresso RPi 3 (Yocto 6.0)`:

| Pole | Wartość |
|---|---|
| Run device type | Remote Linux Device |
| Run device | RPi z punktu 2 |
| Build device | Desktop (lokalny komputer) |
| Sysroot | `SDK/sysroots/cortexa53-nocrypto-poky-linux` |
| Compiler C / C++ | `Yocto 6.0 aarch64 GCC` |
| Debugger | `Yocto 6.0 aarch64 GDB` |
| Qt version | `Qt 6.12.1 (Yocto, RPi 3)` |
| CMake Tool | systemowe CMake (wystarczy, wszystko ustawia plik toolchaina) |
| CMake Configuration | dopisz `-DCMAKE_TOOLCHAIN_FILE:FILEPATH=SDK/sysroots/x86_64-pokysdk-linux/usr/share/cmake/Qt6Toolchain.cmake` |

## 5. Projekt

Otwórz `app/espresso-hmi/CMakeLists.txt` i zaznacz nowy kit (obok kitu desktopowego).

**Build settings** (kit RPi): dopisz `-DESPRESSO_BUILD_TESTS:BOOL=OFF`. Testy są budowane
na aarch64, więc nie da się ich uruchomić na laptopie. Testy uruchamiasz kitem desktopowym i w CI.

**Run settings → Deployment** (kolejność kroków):
1. *Run custom remote command*: `systemctl stop espresso-hmi`. Aplikacja z usługi trzyma ekran (DRM),
   a dwie aplikacje eglfs naraz nie zadziałają.
2. *Deploy files*: metoda rsync (wysyła tylko zmienione pliki; SFTP też działa). Pliki trafiają
   według `cmake --install`, czyli `/usr/bin/espresso-hmi`.

**Run settings → Run** (środowisko jak w usłudze systemd, `meta-espresso/.../espresso-hmi.service`):
```
QT_QPA_PLATFORM=eglfs
QT_QPA_EGLFS_INTEGRATION=eglfs_kms
QT_QPA_EGLFS_KMS_CONFIG=/etc/espresso-hmi/kms.json
QT_QPA_EGLFS_HIDECURSOR=1
QT_QPA_EGLFS_PHYSICAL_WIDTH=155
QT_QPA_EGLFS_PHYSICAL_HEIGHT=86
LANG=C.UTF-8
TZ=CET-1CEST,M3.5.0,M10.5.0/3
XDG_RUNTIME_DIR=/tmp
```

**Run (Ctrl+R)**: build, deploy, start na ekranie 7".
**Debug (F5)**: to samo pod gdbserverem. Breakpoint np. w `DrinkCatalog::stepIndexAt`
(`src/core/drinkcatalog.cpp`) zatrzyma się, gdy na RPi wybierzesz napój.

Po zakończeniu sesji przywróć aplikację z usługi:
```bash
ssh root@192.168.77.2 systemctl start espresso-hmi
```

## Uwagi
- Zegar RPi: `./scripts/deploy.sh` i `crash-demo.sh` ustawiają go z laptopa. Qt Creator tego nie robi,
  więc przy pracy tylko z IDE uruchom raz `./scripts/sync-time.sh`.
- gdbserver i root bez hasła są tylko w obrazie deweloperskim (`espresso-image.bb`). W obrazie
  produkcyjnym nie powinno ich być.
- Ten sam toolchain (`demo-rpi/sdk`) buduje aplikację w Jenkinsie (`demo-ci`, etap cross-build).
