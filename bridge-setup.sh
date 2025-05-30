#!/bin/bash
# bridge-setup-dhcp.sh - Configura un bridge br0 con DHCP persistente
# Compatible con Rocky Linux, AlmaLinux, RHEL 9+

set -euo pipefail

# =================== Configuración ===================
BRIDGE_NAME="br0"
SLAVE_NAME="br0-port1"
PHYS_IFACE="enp3s0f0"
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

echo "[+] Instalando bridge-utils y NetworkManager (si faltan)..."
dnf install -y bridge-utils NetworkManager &>/dev/null

echo "[+] Eliminando conexiones anteriores del script (si existen)..."
nmcli connection delete "$BRIDGE_NAME" &>/dev/null || true
nmcli connection delete "$SLAVE_NAME" &>/dev/null || true

echo "[+] Creando el bridge $BRIDGE_NAME..."
nmcli connection add type bridge con-name "$BRIDGE_NAME" ifname "$BRIDGE_NAME" autoconnect yes
nmcli connection modify "$BRIDGE_NAME" ipv4.method auto ipv6.method ignore

echo "[+] Agregando $PHYS_IFACE como esclavo del bridge..."
nmcli connection add type ethernet con-name "$SLAVE_NAME" ifname "$PHYS_IFACE" master "$BRIDGE_NAME" slave-type bridge

echo "[+] Activando bridge y esclavo..."
nmcli connection up "$BRIDGE_NAME"
nmcli connection up "$SLAVE_NAME"

echo "[+] Estado final del bridge:"
ip a show "$BRIDGE_NAME"
nmcli device status | grep "$BRIDGE_NAME"

echo "[✔] Bridge $BRIDGE_NAME activo, con DHCP y persistente tras reinicio."
