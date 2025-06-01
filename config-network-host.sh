#!/bin/bash
# config-network-host.sh - Configura el puente de red y las interfaces físicas con DHCP y IP fija.
# Compatible con Rocky Linux 9+, AlmaLinux 9+, RHEL 9+
# Este script establece el puente `br0` con DHCP y asigna IP estática a una interfaz específica (`enp3s0f0`), mientras que otras interfaces reciben IP por DHCP.

set -euo pipefail

# =================== Configuración ===================
BRIDGE_NAME="br0"             # Nombre del puente
PRIMARY_PHYS_IFACE="enp3s0f0" # Interfaz física para administración con IP fija
FIXED_IP="192.168.0.40/24"    # IP fija para la interfaz enp3s0f0
HOST_GATEWAY="192.168.0.1"    # Gateway para el host
HOST_DNS="8.8.8.8,1.1.1.1,10.17.3.11"    # Servidores DNS para el host

# Otras interfaces físicas que se configurarán para usar DHCP
OTHER_PHYS_IFACES=("enp3s0f1" "enp4s0f0" "enp4s0f1")  # Otras interfaces físicas
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# =================== Instalación y configuración ===================

echo "[+] Instalando bridge-utils y NetworkManager (si faltan)..."
dnf install -y bridge-utils NetworkManager -q || { echo "[-] Falló la instalación de paquetes. Abortando." >&2; exit 1; }

echo "[+] Limpiando conexiones NetworkManager preexistentes para evitar conflictos..."
# Eliminar cualquier conexión existente para el bridge y su esclavo si usan el mismo nombre
nmcli connection delete "$BRIDGE_NAME" &>/dev/null || true
nmcli connection delete "${PRIMARY_PHYS_IFACE}-slave" &>/dev/null || true # Eliminar perfil esclavo si existe

# Desactivar y eliminar conexiones para otras interfaces físicas
for iface in "${OTHER_PHYS_IFACES[@]}"; do
  echo "[+] Desactivando y eliminando conexión para la interfaz $iface..."
  # Eliminar la conexión si existe (usa el nombre del dispositivo como nombre de conexión por defecto)
  nmcli connection delete "$iface" &>/dev/null || true
  # Asegurarse de que el dispositivo esté abajo y no se levante automáticamente
  nmcli device disconnect "$iface" &>/dev/null || true
  nmcli device modify "$iface" autoconnect no &>/dev/null || true
done

# =================== Configuración del Puente ===================

echo "[+] Creando y configurando el puente $BRIDGE_NAME..."
# Configuración del puente con DHCP
nmcli connection add type bridge con-name "$BRIDGE_NAME" ifname "$BRIDGE_NAME" \
    ipv4.method auto \
    ipv4.gateway "$HOST_GATEWAY" \
    ipv4.dns "$HOST_DNS" \
    autoconnect yes

# Activar el puente para obtener la IP por DHCP
echo "[+] Activando el puente $BRIDGE_NAME para obtener IP por DHCP..."
nmcli connection up "$BRIDGE_NAME" || { echo "[-] Falló la activación del puente $BRIDGE_NAME. Abortando." >&2; exit 1; }

# =================== Configuración de la interfaz con IP fija ===================
echo "[+] Configurando $PRIMARY_PHYS_IFACE con IP fija $FIXED_IP..."
nmcli connection add type ethernet con-name "${PRIMARY_PHYS_IFACE}-slave" ifname "$PRIMARY_PHYS_IFACE" \
  master "$BRIDGE_NAME" ipv4.method manual ipv4.addresses "$FIXED_IP" \
  autoconnect yes

# Activar la interfaz con IP fija
nmcli connection up "${PRIMARY_PHYS_IFACE}-slave" || { echo "[-] Falló la activación de la interfaz con IP fija. Abortando." >&2; exit 1; }

# =================== Configuración de otras interfaces con DHCP ===================
for iface in "${OTHER_PHYS_IFACES[@]}"; do
  echo "[+] Configurando la interfaz $iface para usar DHCP..."
  nmcli connection add type ethernet con-name "${iface}-dhcp" ifname "$iface" \
    ipv4.method auto \
    autoconnect yes

  # Activar la interfaz con DHCP
  nmcli connection up "${iface}-dhcp" || { echo "[-] Falló la activación de la interfaz $iface con DHCP. Abortando." >&2; exit 1; }
done

# =================== Verificación Final ===================

echo "[+] Verificando estado final de las interfaces:"
nmcli device status

echo "[+] Estado de IP del puente $BRIDGE_NAME:"
ip a show "$BRIDGE_NAME"

echo "[+] Rutas actuales del host:"
ip route show

echo "[✔] Configuración de red del host completada. '$BRIDGE_NAME' es ahora la interfaz principal con IP $FIXED_IP."