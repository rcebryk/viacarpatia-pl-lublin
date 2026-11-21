#!/usr/bin/env bash
# Powłoka w kontenerze buildu z gotowym środowiskiem bitbake/devtool
source "$(dirname "$0")/common.sh"
ensure_kas
cd "$REPO"
exec "$KAS_CONTAINER" shell "$KAS_FILE"
