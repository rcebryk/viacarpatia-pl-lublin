# Fragment konfiguracji busyboxa (merge z domyślną konfiguracją Poky).
# base64 jest potrzebne Qt Creatorowi do przesyłania plików na urządzenie
# (test urządzenia "Remote Linux" kończy się błędem bez tego polecenia).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://espresso-devtools.cfg"
