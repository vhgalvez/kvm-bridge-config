#!/bin/bash
# 🌉 Crea un bridge br0 sin IP y le añade una interfaz física como esclava

set -euo pipefail

BRIDGE_NAME="br0"
IF_BRIDGE_SLAVE="enp4s0f1"

# Elimina conexiones previas si existen
delete_existing_connection() {
    local iface="$1"
    local existing
    existing=$(nmcli -t -f NAME,DEVICE connection show --active | grep "$iface" || true)
    if [[ -n "$existing" ]]; then
        echo "⚠️ Eliminando conexión anterior en $iface..."
        nmcli connection delete "${iface}" || true
    fi
}

echo "🧼 Verificando y limpiando configuraciones previas..."
delete_existing_connection "$BRIDGE_NAME"
delete_existing_connection "$IF_BRIDGE_SLAVE"

echo "🌉 Creando bridge $BRIDGE_NAME sin IP..."
nmcli connection add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME" \
  ipv4.method disabled ipv6.method ignore autoconnect yes

echo "🔗 Añadiendo interfaz esclava $IF_BRIDGE_SLAVE al bridge..."
nmcli connection add type ethernet ifname "$IF_BRIDGE_SLAVE" con-name "${IF_BRIDGE_SLAVE}-br" \
  master "$BRIDGE_NAME" ipv4.method disabled ipv6.method ignore autoconnect yes

echo "✅ Bridge $BRIDGE_NAME con esclava $IF_BRIDGE_SLAVE configurado."
