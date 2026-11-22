# Od commita do filiżanki espresso - konspekt

Wykład 90 min, 3. rok Informatyki. Temat formalny: Wdrażanie i eksploatacja
systemów informatycznych.

Oś narracji: jedna zmiana w kodzie HMI ekspresu, śledzona od commita,
przez code review, CI i budowę systemu, do maszyny u klienta i jej eksploatacji.

## Podział czasu

| Czas | Blok | Treść | Demo |
|---|---|---|---|
| 0–10 | Kontekst | Wdrożenie aplikacji webowej a HMI na maszynie: brak dostępu fizycznego, ograniczony sprzęt, 10+ lat życia produktu, serwisant zamiast admina. Ankieta: kto zna Git, Docker, Yocto | |
| 10–20 | Gerrit i CI | Dwa repozytoria, dwa pipeline'y: aplikacja (build, testy jednostkowe, pliki .ts, klucze aktualizacji aplikacji) i Yocto (obraz, toolchain do cross-kompilacji, klucze aktualizacji systemu). Patchsety, Change-Id, Code-Review / Verified; Gerrit Trigger | |
| 20–35 | AI code review | Architektura (Gerrit Trigger -> pipeline -> agent na osobnej VM -> Copilot -> komentarz); decyzje i ryzyka: izolacja, dane poza firmą, halucynacje, koszty, czy AI głosuje | zmiana z celowym błędem (na żywo) |
| 35–55 | Fabryka obrazów | Docker + Yocto: warstwy, receptury, `.bbappend`, przypięte wersje, sstate; czas buildu od zera vs z cache | `demo-rpi` cz. 1: konfiguracja kas, receptura, obraz |
| 55–75 | Wdrażanie | Kanały aktualizacji w praktyce (krótko): pendrive aplikacji, pendrive systemu (czyści partycję aplikacji), chmura, urządzenie szeregowe. Paczka aplikacji vs obraz systemu. OTA jako kierunek rozwoju | `demo-rpi` cz. 2: nowy napój w QML -> `deploy.sh` -> ekran |
| 75–83 | Eksploatacja | Samoczynne podnoszenie aplikacji, logi, wersja widoczna w menu serwisowym | `demo-rpi` cz. 3: symulowana awaria, systemd, journal |
| 83–90 | Pytania | Kariera w embedded / DevOps | |
