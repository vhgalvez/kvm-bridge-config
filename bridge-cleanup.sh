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

echo "[+] Limpiando conexiones NetworkManager preexistentes para evitar conflictos..."

# Eliminar conexiones existentes para el puente y sus interfaces físicas asociadas
nmcli connection delete "$BRIDGE_NAME" &>/dev/null || true
nmcli connection delete "${PRIMARY_PHYS_IFACE}-slave" &>/dev/null || true # Eliminar el perfil esclavo si existe

# Desactivar y eliminar conexiones para otras interfaces físicas
for iface in "${OTHER_PHYS_IFACES[@]}"; do
  echo "[+] Desactivando y eliminando conexión para la interfaz $iface..."
  # Eliminar la conexión si existe (usa el nombre del dispositivo como nombre de conexión por defecto)
  nmcli connection delete "$iface" &>/dev/null || true
  # Asegurarse de que el dispositivo esté abajo y no se levante automáticamente
  nmcli device disconnect "$iface" &>/dev/null || true
  nmcli device modify "$iface" autoconnect no &>/dev/null || true
done

# Limpiar cualquier conexión residual
echo "[+] Limpiando cualquier conexión residual..."
nmcli connection reload

echo "[+] Verificando el estado de las interfaces..."
nmcli device status

echo "[✔] Limpieza completa realizada. Las configuraciones de red han sido eliminadas."