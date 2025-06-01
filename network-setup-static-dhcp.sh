#!/bin/bash
# network-setup-static-dhcp.sh - Configura las interfaces físicas con una IP fija y dos con DHCP.
# Compatible con Rocky Linux 9+, AlmaLinux 9+, RHEL 9+
# 🛠️ Configura 1 interfaz con IP fija y otras 2 con DHCP

set -euo pipefail

IF_STATIC="enp3s0f0"
IF_DHCP1="enp3s0f1"
IF_DHCP2="enp4s0f0"

STATIC_IP="192.168.0.40/24"
GATEWAY="192.168.0.1"
DNS="8.8.8.8,1.1.1.1"

echo "🛠️ Configurando IP fija en $IF_STATIC..."
nmcli connection delete "${IF_STATIC}-static" &>/dev/null || true
nmcli connection add type ethernet con-name "${IF_STATIC}-static" ifname "$IF_STATIC" \
  ipv4.method manual ipv4.addresses "$STATIC_IP" ipv4.gateway "$GATEWAY" \
  ipv4.dns "$DNS" ipv6.method ignore autoconnect yes

echo "🌐 Configurando DHCP en $IF_DHCP1..."
nmcli connection delete "${IF_DHCP1}-dhcp" &>/dev/null || true
nmcli connection add type ethernet con-name "${IF_DHCP1}-dhcp" ifname "$IF_DHCP1" \
  ipv4.method auto ipv6.method ignore autoconnect yes

echo "🌐 Configurando DHCP en $IF_DHCP2..."
nmcli connection delete "${IF_DHCP2}-dhcp" &>/dev/null || true
nmcli connection add type ethernet con-name "${IF_DHCP2}-dhcp" ifname "$IF_DHCP2" \
  ipv4.method auto ipv6.method ignore autoconnect yes

# Verificar estado de las conexiones
echo "🚀 Conexiones configuradas. Ejecuta 'nmcli con show' para verificar."
nmcli con show