#!/usr/bin/env bash
# Konfiguruje port Ethernet laptopa na 192.168.77.1/24 do połączenia
# kablem bezpośrednio z RPi (192.168.77.2).  Użycie: ./scripts/laptop-net.sh [interfejs]
set -euo pipefail
ifname="${1:-$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="ethernet"{print $1; exit}')}"
[[ -n "$ifname" ]] || { echo "Nie znaleziono interfejsu Ethernet" >&2; exit 1; }

nmcli connection delete espresso-demo >/dev/null 2>&1 || true
nmcli connection add type ethernet ifname "$ifname" con-name espresso-demo \
    ipv4.method manual ipv4.addresses 192.168.77.1/24 ipv6.method disabled
nmcli connection up espresso-demo
echo ">> $ifname = 192.168.77.1; test: ping 192.168.77.2"
