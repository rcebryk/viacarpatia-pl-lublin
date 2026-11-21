# Wersja systemu (obrazu) w /etc/os-release - widać ją w menu serwisowym aplikacji
# (wiersz "System:", QSysInfo::prettyProductName czyta PRETTY_NAME).
# Numer ustawia kas/rpi3-qt6.yml (ESPRESSO_SYSTEM_VERSION), opis zmian: demo-rpi/CHANGELOG.md.
ESPRESSO_SYSTEM_VERSION ??= "0.0.0-dev"

OS_RELEASE_FIELDS:append = " VARIANT VARIANT_ID IMAGE_ID IMAGE_VERSION"
VARIANT = "Espresso HMI"
VARIANT_ID = "espresso"
IMAGE_ID = "espresso-image"
IMAGE_VERSION = "${ESPRESSO_SYSTEM_VERSION}"
PRETTY_NAME = "Espresso OS ${ESPRESSO_SYSTEM_VERSION} (Yocto ${DISTRO_VERSION})"
