#!/bin/bash
# config-bridge.sh - Configura el puente br0 y una interfaz física para la máquina virtual.
# Compatible con Rocky Linux, AlmaLinux, RHEL 9+

set -euo pipefail

# =================== Configuración ===================
BRIDGE_NAME="br0"
PHYS_IFACE="enp3s0f0"  # Interfaz física asociada al puente
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# =================== Crear y configurar el puente br0 ===================
echo "[+] Instalando bridge-utils y NetworkManager (si faltan)..."
dnf install -y bridge-utils NetworkManager &>/dev/null

echo "[+] Eliminando conexiones previas del puente (si existen)..."
nmcli connection delete "$BRIDGE_NAME" &>/dev/null || true
nmcli connection delete "$PHYS_IFACE" &>/dev/null || true

echo "[+] Creando el puente $BRIDGE_NAME..."
nmcli connection add type bridge con-name "$BRIDGE_NAME" ifname "$BRIDGE_NAME" autoconnect yes ipv4.method auto ipv6.method ignore

echo "[+] Configurando $PHYS_IFACE como parte del puente $BRIDGE_NAME..."
nmcli connection add type ethernet con-name "$PHYS_IFACE" ifname "$PHYS_IFACE" master "$BRIDGE_NAME" slave-type bridge

# Activar el puente y las interfaces físicas asociadas
echo "[+] Activando el puente $BRIDGE_NAME y la interfaz física $PHYS_IFACE..."
nmcli connection up "$BRIDGE_NAME"
nmcli connection up "$PHYS_IFACE"

# Verificar el estado final
echo "[+] Verificando el estado del puente y la interfaz..."
ip a show "$BRIDGE_NAME"
nmcli device status | grep "$BRIDGE_NAME"

echo "[✔] El puente $BRIDGE_NAME está configurado con éxito, y la interfaz física está configurada con DHCP."