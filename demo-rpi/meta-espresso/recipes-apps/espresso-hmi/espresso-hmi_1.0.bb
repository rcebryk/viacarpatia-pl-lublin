SUMMARY = "Espresso HMI - demonstracyjny interfejs ekspresu do kawy (Qt 6 / QML)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Kod aplikacji leży w app/espresso-hmi w repozytorium wykładu (poza warstwą):
# ten sam kod budują bitbake, programista z SDK (deploy.sh) i Jenkins (demo-ci).
# W prawdziwym projekcie byłoby tu: SRC_URI = "git://...;branch=..."
# oraz SRCREV = "<commit>" - receptura "przypina" konkretną wersję aplikacji.
FILESEXTRAPATHS:prepend := "${THISDIR}/../../../../app:${THISDIR}/files:"

SRC_URI = " \
    file://espresso-hmi/ \
    file://espresso-hmi.service \
    file://kms.json \
"
S = "${UNPACKDIR}/espresso-hmi"

DEPENDS = "qtbase qtdeclarative qtdeclarative-native"

inherit qt6-cmake systemd

# Testy jednostkowe uruchamia CI (Jenkins), nie build obrazu
EXTRA_OECMAKE += "-DESPRESSO_BUILD_TESTS=OFF"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/espresso-hmi.service ${D}${systemd_system_unitdir}/
    install -d ${D}${sysconfdir}/espresso-hmi
    install -m 0644 ${UNPACKDIR}/kms.json ${D}${sysconfdir}/espresso-hmi/
}

# Usługa startuje automatycznie przy starcie systemu
SYSTEMD_SERVICE:${PN} = "espresso-hmi.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += "${sysconfdir}/espresso-hmi"

# Zależności w czasie działania: wtyczka platformy eglfs, moduły QML,
# czcionka z polskimi znakami
RDEPENDS:${PN} += " \
    qtbase-plugins \
    qtdeclarative-qmlplugins \
    liberation-fonts \
"
