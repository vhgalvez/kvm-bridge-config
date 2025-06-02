#!/bin/bash
# setup-bridge-br0.sh
# 🌉 Crea el bridge br0 sin IP y le añade enp4s0f1 como esclava (sin IP)

set -euo pipefail

BRIDGE_NAME="br0"
IF_BRIDGE_SLAVE="enp4s0f1"

# 🔁 Elimina conexiones previas para evitar conflictos
delete_existing_connection() {
    local iface="$1"
    echo "🔍 Buscando conexiones activas para $iface..."
    local conns
    conns=$(nmcli -t -f NAME,DEVICE connection show | grep "$iface" | cut -d: -f1 || true)
    for conn in $conns; do
        echo "⚠️ Eliminando conexión '$conn' en $iface..."
        nmcli connection delete "$conn" || true
    done
}

echo "🧼 Verificando y limpiando configuraciones previas..."
delete_existing_connection "$BRIDGE_NAME"
delete_existing_connection "$IF_BRIDGE_SLAVE"

echo "🌉 Creando bridge $BRIDGE_NAME sin dirección IP..."
nmcli connection add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME" \
  ipv4.method disabled ipv6.method ignore connection.autoconnect yes

echo "🔗 Añadiendo esclava $IF_BRIDGE_SLAVE al bridge $BRIDGE_NAME..."
nmcli connection add type ethernet ifname "$IF_BRIDGE_SLAVE" con-name "${IF_BRIDGE_SLAVE}-br" \
  master "$BRIDGE_NAME" connection.autoconnect yes

echo "✅ Bridge $BRIDGE_NAME configurado con $IF_BRIDGE_SLAVE como esclava."
nmcli connection up "$BRIDGE_NAME"
