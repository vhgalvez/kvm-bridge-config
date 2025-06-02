#!/bin/bash
# setup-admin-interface.sh
# Configura enp3s0f0 con IP fija y gateway para acceso LAN e Internet
# Compatible con Rocky Linux 9+, AlmaLinux 9+, RHEL 9+

set -euo pipefail

IFACE="enp3s0f0"
STATIC_IP="192.168.0.40/24"
GATEWAY="192.168.0.1"
DNS="8.8.8.8,1.1.1.1"

echo "🛠️ Eliminando conexiones anteriores para $IFACE (si existen)..."
nmcli connection delete "$IFACE" || true
nmcli connection delete "${IFACE}-static" || true

echo "🌐 Configurando $IFACE con IP fija $STATIC_IP y gateway $GATEWAY..."
nmcli connection add type ethernet con-name "${IFACE}-static" ifname "$IFACE" \
  ipv4.method manual \
  ipv4.addresses "$STATIC_IP" \
  ipv4.gateway "$GATEWAY" \
  ipv4.dns "$DNS" \
  ipv6.method ignore \
  connection.autoconnect yes

echo "✅ Activando conexión..."
nmcli connection up "${IFACE}-static"

echo "📡 Verificando IP asignada:"
ip a show "$IFACE"

echo "🧭 Verificando tabla de rutas:"
ip route show | grep default

echo "✅ $IFACE configurado correctamente con salida a Internet."
