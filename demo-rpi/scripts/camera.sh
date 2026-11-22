#!/usr/bin/env bash
# Podgląd z kamery skierowanej na ekran RPi - osobne okno na rzutnik, BEZ odbicia lustrzanego
# (wbudowana kamerka Slidev i aplikacja Camera odbijają obraz, więc napisy byłyby odwrócone).
#
#   ./scripts/camera.sh              # pierwsza kamera USB (pomija wbudowaną "Integrated")
#   ./scripts/camera.sh /dev/video2  # konkretne urządzenie
#   CAM_SIZE=1280x720 ./scripts/camera.sh
#
# W oknie: f - pełny ekran, q / Esc - zamknij, przeciąganie myszą - przesuwanie okna.
set -euo pipefail

dev="${1:-}"
if [[ -z $dev ]]; then
    for d in /sys/class/video4linux/video*; do
        name=$(<"$d/name")
        [[ $name == *Integrated* ]] && continue
        # jedno urządzenie USB ma kilka węzłów /dev/video*; obraz jest na tym o indeksie 0
        [[ $(<"$d/index") == 0 ]] || continue
        dev="/dev/$(basename "$d")"; break
    done
fi
[[ -n $dev ]] || { echo "Brak kamery USB. Podaj urządzenie: $0 /dev/videoN" >&2; exit 1; }
echo ">> Kamera: $dev ($(<"/sys/class/video4linux/$(basename "$dev")/name"))"

exec ffplay -hide_banner -loglevel warning \
    -f v4l2 -input_format mjpeg -video_size "${CAM_SIZE:-1920x1080}" -framerate 30 \
    -fflags nobuffer -flags low_delay -framedrop \
    -window_title "Ekran RPi" "$dev"
