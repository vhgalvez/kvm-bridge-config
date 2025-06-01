#!/bin/bash
# config-network.sh - Configura las interfaces físicas con una IP fija y dos con DHCP.
# Compatible con Rocky Linux 9+, AlmaLinux 9+, RHEL 9+

set -euo pipefail

# =================== Configuración ===================
PRIMARY_PHYS_IFACE="enp3s0f0" # Interfaz física para administración con IP fija
FIXED_IP="192.168.0.40/24"    # IP fija para la interfaz enp3s0f0
HOST_GATEWAY="192.168.0.1"    # Gateway para el host
HOST_DNS="8.8.8.8,1.1.1.1,10.17.3.11"    # Servidores DNS para el host

# Otras interfaces físicas que se configurarán para usar DHCP
OTHER_PHYS_IFACES=("enp3s0f1" "enp4s0f0")  # Otras interfaces físicas
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# =================== Instalación y configuración ===================

echo "[+] Instalando NetworkManager (si falta)..."
dnf install -y NetworkManager -q || { echo "[-] Falló la instalación de paquetes. Abortando." >&2; exit 1; }

echo "[+] Limpiando conexiones NetworkManager preexistentes para evitar conflictos..."
# Eliminar cualquier conexión existente para las interfaces físicas
nmcli connection delete "${PRIMARY_PHYS_IFACE}-static" &>/dev/null || true
for iface in "${OTHER_PHYS_IFACES[@]}"; do
  nmcli connection delete "${iface}-dhcp" &>/dev/null || true
done

# =================== Configuración de la interfaz con IP fija ===================
echo "[+] Configurando $PRIMARY_PHYS_IFACE con IP fija $FIXED_IP..."
nmcli connection add type ethernet con-name "${PRIMARY_PHYS_IFACE}-static" ifname "$PRIMARY_PHYS_IFACE" \
  ipv4.method manual ipv4.addresses "$FIXED_IP" ipv4.gateway "$HOST_GATEWAY" ipv4.dns "$HOST_DNS" \
  autoconnect yes

# Activar la interfaz con IP fija
nmcli connection up "${PRIMARY_PHYS_IFACE}-static" || { echo "[-] Falló la activación de la interfaz $PRIMARY_PHYS_IFACE con IP fija. Abortando." >&2; exit 1; }

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

echo "[+] Estado de IP de la interfaz $PRIMARY_PHYS_IFACE:"
ip a show "$PRIMARY_PHYS_IFACE"

echo "[+] Estado de IP de las otras interfaces:"
for iface in "${OTHER_PHYS_IFACES[@]}"; do
  ip a show "$iface"
done

echo "[✔] Configuración de red del host completada."