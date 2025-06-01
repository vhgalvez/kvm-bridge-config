#!/bin/bash
# config-network-host-corrected.sh - Configura el puente de red y las interfaces físicas.
# Compatible con Rocky Linux 9+, AlmaLinux 9+, RHEL 9+
# Este script establece br0 como la interfaz principal del host con IP estática,
# y desactiva otras interfaces físicas para evitar conflictos.

set -euo pipefail

# =================== Configuración ===================
BRIDGE_NAME="br0"             # Nombre del puente
PRIMARY_PHYS_IFACE="enp3s0f0" # Interfaz física que será esclava de br0 (conectada a tu LAN)

# Configuración IP para el HOST (a través de br0)
HOST_IP_METHOD="manual"      # "manual" para IP estática, "auto" para DHCP
HOST_IP_ADDRESS="192.168.0.15/24" # IP del host en br0
HOST_GATEWAY="192.168.0.1"   # Gateway para el host
HOST_DNS="8.8.8.8,1.1.1.1"   # Servidores DNS para el host

# Otras interfaces físicas que se DESACTIVARÁN para evitar conflictos
OTHER_PHYS_IFACES=("enp3s0f1" "enp4s0f0" "enp4s0f1")
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

echo "[+] Instalando bridge-utils y NetworkManager (si faltan)..."
dnf install -y bridge-utils NetworkManager -q || { echo "[-] Falló la instalación de paquetes. Abortando." >&2; exit 1; }

echo "[+] Limpiando conexiones NetworkManager preexistentes para evitar conflictos..."
# Eliminar cualquier conexión existente para el bridge
nmcli connection delete "$BRIDGE_NAME" &>/dev/null || true
# Eliminar cualquier conexión existente para la interfaz física principal
nmcli connection delete "$PRIMARY_PHYS_IFACE" &>/dev/null || true

# Eliminar y desactivar conexiones para otras interfaces físicas
for iface in "${OTHER_PHYS_IFACES[@]}"; do
  echo "[+] Desactivando y eliminando conexión para la interfaz $iface..."
  nmcli connection delete "$iface" &>/dev/null || true # Elimina cualquier conexión con el mismo nombre
  nmcli device disconnect "$iface" &>/dev/null || true # Asegura que la interfaz esté abajo
  nmcli device modify "$iface" autoconnect no &>/dev/null || true # Evita que se levante automáticamente
done

echo "[+] Creando el puente $BRIDGE_NAME..."
nmcli connection add type bridge con-name "$BRIDGE_NAME" ifname "$BRIDGE_NAME" autoconnect yes

# Configurar IP, Gateway y DNS en el puente
nmcli connection modify "$BRIDGE_NAME" ipv4.method "$HOST_IP_METHOD" ipv6.method ignore
if [[ "$HOST_IP_METHOD" == "manual" ]]; then
  nmcli connection modify "$BRIDGE_NAME" ipv4.addresses "$HOST_IP_ADDRESS"
  nmcli connection modify "$BRIDGE_NAME" ipv4.gateway "$HOST_GATEWAY"
fi
nmcli connection modify "$BRIDGE_NAME" ipv4.dns "$HOST_DNS"

echo "[+] Configurando $PRIMARY_PHYS_IFACE como esclava del puente $BRIDGE_NAME..."
# Asegúrate de que la interfaz física esté abajo antes de añadirla al bridge
nmcli device disconnect "$PRIMARY_PHYS_IFACE" &>/dev/null || true
nmcli connection add type ethernet con-name "${PRIMARY_PHYS_IFACE}-slave" ifname "$PRIMARY_PHYS_IFACE" master "$BRIDGE_NAME" slave-type bridge autoconnect yes

# Activar el puente y la interfaz esclava
echo "[+] Activando el puente $BRIDGE_NAME y sus interfaces..."
nmcli connection up "$BRIDGE_NAME" || { echo "[-] Falló la activación del puente. Abortando." >&2; exit 1; }
nmcli connection up "${PRIMARY_PHYS_IFACE}-slave" || { echo "[-] Falló la activación de la interfaz esclava. Abortando." >&2; exit 1; }


echo "[+] Verificando estado final de las interfaces:"
nmcli device status

echo "[+] Estado de IP del puente $BRIDGE_NAME:"
ip a show "$BRIDGE_NAME"

echo "[+] Rutas actuales del host:"
ip route show

echo "[✔] Configuración de red del host completada. '$BRIDGE_NAME' es ahora la interfaz principal con IP $HOST_IP_ADDRESS (o DHCP)."
echo "[!] Si la IP 192.168.0.15 ya estaba en uso, podría haber un conflicto."