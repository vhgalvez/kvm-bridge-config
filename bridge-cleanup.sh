#!/bin/bash
# bridge-cleanup.sh - Elimina solo el bridge creado por bridge-setup

set -euo pipefail

BRIDGE_NAME="br0"
SLAVE_NAME="br0-port1"

echo "[+] Eliminando conexiones creadas por el script..."
nmcli connection delete "$SLAVE_NAME" &>/dev/null || true
nmcli connection delete "$BRIDGE_NAME" &>/dev/null || true

echo "[✔] Limpieza completa: $BRIDGE_NAME y $SLAVE_NAME eliminados."