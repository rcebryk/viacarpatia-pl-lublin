# Changelog - system (obraz Yocto)

Wersja systemu: `ESPRESSO_SYSTEM_VERSION` w `kas/rpi3-qt6.yml`. Widać ją w `/etc/os-release`
i w menu serwisowym aplikacji (przytrzymaj logo 2 s, wiersz „System”).
Numeracja [SemVer](https://semver.org/lang/pl/): MAJOR - niekompatybilna zmiana (np. układ partycji),
MINOR - nowe funkcje, PATCH - poprawki. Zmiany aplikacji: `app/espresso-hmi/CHANGELOG.md`.

## [1.0.0] - 2026-11-21

Pierwsze wydanie - karty SD na wykład.

### Zawartość
- Yocto 6.0.4 „wrynose” (LTS), Raspberry Pi 3B+ w trybie 64-bit (`raspberrypi3-64`).
- Qt 6.12.1, grafika eglfs + KMS/DRM bez X11/Wayland, oficjalny ekran 7" DSI z dotykiem.
- systemd: aplikacja Espresso HMI jako usługa z automatycznym restartem.
- Sieć: Ethernet przez DHCP oraz stały adres 192.168.77.2/24 (kabel do laptopa).
- Narzędzia deweloperskie: SSH (root bez hasła - tylko demo), gdbserver, rsync, base64 (Qt Creator).
- Wersja systemu w `/etc/os-release` (`PRETTY_NAME`, `IMAGE_VERSION`).

### Poprawione
- Czcionka: Qt na eglfs prosi o „Noto Sans”, której w obrazie nie ma; fontconfig podstawiał
  Liberation Mono i szerokie napisy wychodziły poza ekran. Teraz: Liberation Sans.
- Ekran DSI był czarny bez modułów jądra - obraz zawiera `kernel-modules`.
