#!/bin/bash
# setup-test-network.sh
# 🧪 Configura enp4s0f0 como Red de Pruebas Aislada (192.168.60.1/24 sin gateway)

set -euo pipefail

IF_TEST="enp4s0f0"
TEST_IP="192.168.60.1/24"
CON_NAME="enp4s0f0-tests"

echo "🧼 Verificando y eliminando configuraciones previas de $IF_TEST..."
existing_conn=$(nmcli -t -f NAME,DEVICE connection show | grep "$IF_TEST" | cut -d: -f1 || true)
if [[ -n "$existing_conn" ]]; then
    echo "⚠️ Eliminando conexión previa '$existing_conn'..."
    nmcli connection delete "$existing_conn" || true
fi

echo "🔧 Configurando $IF_TEST como red de pruebas con IP $TEST_IP (sin gateway)..."
nmcli connection add type ethernet ifname "$IF_TEST" con-name "$CON_NAME" \
  ipv4.method manual \
  ipv4.addresses "$TEST_IP" \
  ipv4.gateway "" \
  ipv4.dns "" \
  ipv6.method ignore \
  connection.autoconnect yes

echo "✅ Activando conexión $CON_NAME..."
nmcli connection up "$CON_NAME"

echo "🚀 Red de pruebas configurada correctamente en $IF_TEST con IP $TEST_IP"