#!/usr/bin/env bash
# Buduje i instaluje SDK (toolchain do cross-kompilacji na aarch64 + Qt 6) do katalogu sdk/
source "$(dirname "$0")/common.sh"
ensure_kas
cd "$REPO"

"$KAS_CONTAINER" shell "$KAS_FILE" -c "bitbake espresso-image -c populate_sdk"

installer=$(ls -t "$(deploy_dir)"/sdk/*espresso-image*toolchain*.sh | head -1)
echo ">> Instaluję $installer do $REPO/sdk"
rm -rf "$REPO/sdk"
"$installer" -y -d "$REPO/sdk"
