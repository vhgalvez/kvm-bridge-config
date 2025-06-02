#!/bin/bash
# setup-management-network.sh
# 🛠️ Configura enp3s0f1 como Red de Gestión Privada (192.168.50.1/24 sin gateway)

set -euo pipefail

IF_MGMT="enp3s0f1"
MGMT_IP="192.168.50.1/24"
CON_NAME="enp3s0f1-gestion"

echo "🧼 Verificando y eliminando configuraciones previas de $IF_MGMT..."
existing_conn=$(nmcli -t -f NAME,DEVICE connection show | grep "$IF_MGMT" | cut -d: -f1 || true)
if [[ -n "$existing_conn" ]]; then
    echo "⚠️ Eliminando conexión previa '$existing_conn'..."
    nmcli connection delete "$existing_conn" || true
fi

echo "🔧 Configurando $IF_MGMT como red de gestión con IP $MGMT_IP (sin gateway)..."
nmcli connection add type ethernet ifname "$IF_MGMT" con-name "$CON_NAME" \
  ipv4.method manual \
  ipv4.addresses "$MGMT_IP" \
  ipv4.gateway "" \
  ipv4.dns "" \
  ipv6.method ignore \
  connection.autoconnect yes

echo "✅ Activando conexión $CON_NAME..."
nmcli connection up "$CON_NAME"

echo "🚀 Red de gestión configurada correctamente en $IF_MGMT con IP $MGMT_IP"
