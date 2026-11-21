# Changelog - aplikacja Espresso HMI

Wersja aplikacji: `project(espresso-hmi VERSION ...)` w `CMakeLists.txt`. Widać ją w menu serwisowym
(wiersz „Aplikacja”) i w prawym dolnym rogu ekranu. Numeracja [SemVer](https://semver.org/lang/pl/).
Zmiany systemu (obrazu Yocto): `demo-rpi/CHANGELOG.md`.

## [1.0.0] - 2026-11-21

Pierwsze wydanie.

### Funkcje
- Menu napojów z C++ (`DrinkCatalog`), siatka kafelków z przewijaniem.
- Ekran parzenia z krokami i anulowaniem.
- Menu serwisowe (przytrzymaj logo 2 s): wersje aplikacji, Qt i systemu, czas pracy, symulacja awarii.
- Tłumaczenia (polski, angielski), poprawne zamknięcie na SIGTERM (systemd).
- Testy jednostkowe i testy interfejsu (QtTest, offscreen).

### Poprawione
- Siódmy napój nie mieścił się na ekranie - siatka przewijana.
- „Anuluj” na ekranie parzenia uruchamiał napój spod spodu.
