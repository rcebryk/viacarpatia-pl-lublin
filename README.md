# Wdrażanie i eksploatacja systemów informatycznych - wykład

Wykład (90 min) dla studentów 3. roku Informatyki, Politechnika Lubelska.
Temat zilustrowany praktyką: oprogramowanie HMI (C++/Qt) dla ekspresów
HoReCa i automatów vendingowych - od commita do maszyny w kawiarni.

## Struktura repozytorium

| Katalog | Zawartość |
|---|---|
| `wyklad/konspekt.md` | scenariusz wykładu i podział czasu |
| `wyklad/slajdy/` | prezentacja w Slidev ([README](wyklad/slajdy/README.md)) |
| `app/espresso-hmi/` | aplikacja HMI ekspresu (Qt 6 / QML, testy, pipeline'y CI w `ci/`) - wspólna dla obu dem |
| `demo-rpi/` | demo: Yocto 6.0 + Qt 6 na Raspberry Pi 3B+ z ekranem 7" ([README](demo-rpi/README.md)) |
| `demo-ci/` | demo: Gerrit + Jenkins + AI code review (Claude) w Dockerze ([README](demo-ci/README.md)) |

## Jak uruchomić

- Slajdy online: https://rcebryk.github.io/viacarpatia-pl-lublin/ (budowane przez GitHub Actions)
- Slajdy: `cd wyklad/slajdy && ./slidev.sh dev`, potem http://localhost:3030 (lokalnie)
- Aplikacja na komputerze: `cmake -S app/espresso-hmi -B build && cmake --build build && ctest --test-dir build`
  (Qt 6.5+, CMake, Ninja)
- System dla Raspberry Pi (Yocto + kas w Dockerze): [demo-rpi/README.md](demo-rpi/README.md)
- Cross-kompilacja i debugowanie na RPi w Qt Creatorze: [demo-rpi/QTCREATOR.md](demo-rpi/QTCREATOR.md)
- Gerrit + Jenkins + AI code review lokalnie w Dockerze: [demo-ci/README.md](demo-ci/README.md)

## Licencje

- Kod (aplikacja, dema, skrypty, pipeline'y, kod prezentacji): [MIT](LICENSE).
- Treść wykładu (slajdy, konspekt): [CC BY 4.0](wyklad/LICENSE.md),
  z wyjątkiem logotypów i tła szablonu oraz czcionki Carlito (szczegóły w tym pliku).

