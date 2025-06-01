#!/bin/bash
# cleanup-all.sh - Elimina todas las configuraciones de red relacionadas con el puente y las interfaces físicas.
# Compatible con Rocky Linux 9+, AlmaLinux 9+, RHEL 9+

set -euo pipefail

# =================== Configuración ===================
BRIDGE_NAME="br0"             # Nombre del puente
PRIMARY_PHYS_IFACE="enp3s0f0" # Interfaz física para administración
OTHER_PHYS_IFACES=("enp3s0f1" "enp4s0f0" "enp4s0f1")  # Otras interfaces físicas que fueron configuradas
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# =================== Funciones ===================

# Función para eliminar conexiones de red
delete_connection() {
  local conn_name=$1
  echo "[+] Eliminando conexión: $conn_name..."
  nmcli connection delete "$conn_name" &>/dev/null || true
}

# Función para desactivar y desconectar interfaces
disable_interface() {
  local iface=$1
  echo "[+] Desactivando la interfaz: $iface..."
  nmcli device disconnect "$iface" &>/dev/null || true
  nmcli device modify "$iface" autoconnect no &>/dev/null || true
}

# =================== Limpieza de Configuración de Red ===================

echo "[+] Limpiando conexiones NetworkManager preexistentes para evitar conflictos..."

# Eliminar conexiones existentes para el puente y sus interfaces físicas asociadas
delete_connection "$BRIDGE_NAME"
delete_connection "${PRIMARY_PHYS_IFACE}-slave"  # Eliminar el perfil esclavo si existe

# Desactivar y eliminar conexiones para otras interfaces físicas
for iface in "${OTHER_PHYS_IFACES[@]}"; do
  disable_interface "$iface"
  delete_connection "$iface"
done

# Limpiar cualquier conexión residual
echo "[+] Limpiando cualquier conexión residual..."
nmcli connection reload

# =================== Verificación Final ===================

echo "[+] Verificando el estado de las interfaces..."
nmcli device status

echo "[✔] Limpieza completa realizada. Las configuraciones de red han sido eliminadas."