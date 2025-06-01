#!/bin/bash
# config-dhcp-interfaces.sh - Configura las interfaces del host para usar DHCP.
# Compatible con Rocky Linux, AlmaLinux, RHEL 9+

set -euo pipefail

# =================== Configuración ===================
INTERFACES=("enp3s0f1" "enp4s0f0" "enp4s0f1")  # Las interfaces físicas a configurar con DHCP
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

echo "[+] Configurando las interfaces físicas para usar DHCP..."

# Configuración de cada interfaz
for iface in "${INTERFACES[@]}"; do
  # Verificar si la interfaz ya tiene una conexión activa
  ACTIVE_CONN=$(nmcli -t -f NAME,DEVICE connection show | grep "$iface" | cut -d: -f1)

  if [[ -n "$ACTIVE_CONN" ]]; then
    echo "[+] Modificando la conexión $ACTIVE_CONN para usar DHCP..."
    nmcli connection modify "$ACTIVE_CONN" ipv4.method auto ipv6.method ignore
  else
    echo "[+] Creando y configurando la conexión para $iface con DHCP..."
    nmcli connection add type ethernet con-name "$iface" ifname "$iface" ipv4.method auto ipv6.method ignore
  fi

  # Activar la interfaz
  nmcli connection up "$iface"
done

echo "[✔] Las interfaces físicas están configuradas con DHCP y activas."