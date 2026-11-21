#!/usr/bin/env bash
# DEMO EKSPLOATACJI: zabija aplikację i pokazuje, że systemd ją podnosi
source "$(dirname "$0")/common.sh"
sync_time
ssh "${SSH_OPTS[@]}" "$TARGET" '
    echo ">> PID przed: $(systemctl show -p MainPID --value espresso-hmi)"
    systemctl kill -s KILL espresso-hmi
    sleep 3
    echo ">> PID po:    $(systemctl show -p MainPID --value espresso-hmi)"
    echo ">> Liczba restartów: $(systemctl show -p NRestarts --value espresso-hmi)"
    journalctl -u espresso-hmi --no-pager -n 12'
