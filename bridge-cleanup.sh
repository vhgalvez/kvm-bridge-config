#!/bin/bash
# bridge-cleanup.sh - Elimina todas las configuraciones de red previas (incluyendo puente, interfaces y otras configuraciones residuales) y deja el sistema limpio para configurar todo desde cero.

set -euo pipefail

# =================== Configuración ===================
BRIDGE_NAME="br0"              # Nombre del puente a eliminar
SLAVE_NAME="br0-port1"         # Nombre de la conexión del esclavo (interfaz física asociada)
ADMIN_IFACE="enp4s0f1"         # Interfaz administrativa con IP fija
INTERFACES=("enp3s0f0" "enp4s0f0" "enp4s0f1") # Interfaces físicas que se configuraron para DHCP
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# =================== Eliminación de conexiones creadas ===================
echo "[+] Eliminando conexiones creadas por el script..."

# Eliminar las conexiones del puente
nmcli connection delete "$BRIDGE_NAME" &>/dev/null || true
nmcli connection delete "$SLAVE_NAME" &>/dev/null || true

# Eliminar las interfaces físicas de las conexiones si existen
for iface in "${INTERFACES[@]}"; do
  ACTIVE_CONN=$(nmcli -t -f NAME,DEVICE connection show | grep "$iface" | cut -d: -f1)
  if [[ -n "$ACTIVE_CONN" ]]; then
    nmcli connection delete "$ACTIVE_CONN" &>/dev/null || true
  fi
done

# Eliminar la conexión de la interfaz administrativa (si existe)
ACTIVE_CONN_ADMIN=$(nmcli -t -f NAME,DEVICE connection show | grep "$ADMIN_IFACE" | cut -d: -f1)
if [[ -n "$ACTIVE_CONN_ADMIN" ]]; then
  nmcli connection delete "$ACTIVE_CONN_ADMIN" &>/dev/null || true
fi

# =================== Limpieza de archivos de configuración de red ===================
echo "[+] Limpiando configuraciones residuales en archivos de red..."
rm -f /etc/sysconfig/network-scripts/ifcfg-*  # Eliminar archivos de configuración de interfaces

# Limpieza de cualquier red manual (si existiera) en NetworkManager
echo "[+] Eliminando redes manuales (si existen)..."
nmcli connection delete id "System eth0" &>/dev/null || true
nmcli connection delete id "System ens192" &>/dev/null || true

# =================== Limpieza de reglas de firewall ===================
echo "[+] Limpiando reglas de firewall y redes virtuales..."
nmcli connection delete "bridge-slave" &>/dev/null || true
firewall-cmd --permanent --delete-zone=trusted &>/dev/null || true
firewall-cmd --permanent --delete-port=80/tcp &>/dev/null || true
firewall-cmd --reload &>/dev/null || true

# =================== Verificación final ===================
echo "[✔] Limpieza completa. El sistema está listo para una nueva configuración."

# Verificar el estado final de las interfaces
nmcli device status