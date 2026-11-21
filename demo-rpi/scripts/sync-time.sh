#!/usr/bin/env bash
# Ustawia zegar RPi z laptopa (RPi 3B+ nie ma RTC: po włączeniu ma zły czas).
# Uruchom raz po włączeniu RPi - np. przed pracą z Qt Creatorem, który tego nie robi.
#   ./scripts/sync-time.sh            # domyślnie root@192.168.77.2
#   TARGET=root@10.0.0.5 ./scripts/sync-time.sh
source "$(dirname "$0")/common.sh"

sync_time
# strefa jak w usłudze espresso-hmi (system na RPi trzyma czas w UTC)
ssh "${SSH_OPTS[@]}" "$TARGET" 'echo ">> Czas na RPi: $(TZ=CET-1CEST,M3.5.0,M10.5.0/3 date)"'
