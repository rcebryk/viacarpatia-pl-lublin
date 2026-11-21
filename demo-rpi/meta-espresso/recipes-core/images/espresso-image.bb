SUMMARY = "Obraz demonstracyjny: HMI ekspresu do kawy (Qt 6, eglfs) na Raspberry Pi 3B+"
LICENSE = "MIT"

# core-image: klasa bazowa obrazów
# populate_sdk_qt6_base: "bitbake espresso-image -c populate_sdk" zbuduje SDK
#                   z toolchainem do cross-kompilacji i bibliotekami Qt 6
inherit core-image populate_sdk_qt6_base

# Do SDK tylko potrzebne moduły Qt: Base, Declarative (QML), Tools (lupdate do .ts).
# Klasa populate_sdk_qt6 dodaje WSZYSTKIE moduły, łącznie z Qt WebEngine (Chromium):
# wiele godzin kompilacji i brak pamięci przy 31 GB RAM.
TOOLCHAIN_HOST_TASK:append = " nativesdk-packagegroup-qt6-toolchain-host-essentials"
TOOLCHAIN_TARGET_TASK:append = " packagegroup-qt6-essentials"

# UWAGA: tylko do demo! Root bez hasła i logowanie po SSH.
# Na prawdziwej maszynie to byłaby poważna luka bezpieczeństwa.
IMAGE_FEATURES += " \
    ssh-server-openssh \
    allow-empty-password \
    empty-root-password \
    allow-root-login \
"

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    espresso-hmi \
    espresso-network \
    openssh-sftp-server \
    kernel-modules \
    gdbserver \
    rsync \
"
# gdbserver: zdalne debugowanie z Qt Creatora (breakpointy na RPi); rsync: szybkie
# wdrażanie z Qt Creatora (tylko zmienione pliki). Tak jak root bez hasła - tylko
# w obrazie deweloperskim; obraz produkcyjny ich nie zawiera.
# kernel-modules: sterowniki ekranu DSI 7" (panel, mostek tc358762, regulator attiny,
# i2c-mux) i dotyku (edt-ft5x06) są modułami. meta-raspberrypi dodaje je tylko jako
# "rekomendowane" (MACHINE_EXTRA_RRECOMMENDS), a nasze IMAGE_INSTALL = "..." ich nie
# dociąga - bez tej linii ekran zostaje czarny.

IMAGE_LINGUAS = ""

# Trochę wolnego miejsca na rootfs (logi, ręcznie wgrywane wersje aplikacji)
IMAGE_ROOTFS_EXTRA_SPACE = "262144"
