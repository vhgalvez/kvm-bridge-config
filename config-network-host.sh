#!/bin/bash
# config-network-host.sh - Configura el puente de red y las interfaces físicas con una IP fija y DHCP.
# Compatible con Rocky Linux, AlmaLinux, RHEL 9+

set -euo pipefail

# =================== Configuración ===================
BRIDGE_NAME="br0"                # Nombre del puente
BRIDGE_IFACE="enp3s0f0"          # Interfaz conectada al puente (DHCP)
INTERFACES=("enp3s0f0" "enp4s0f0" "enp4s0f1") # Interfaces físicas a configurar con DHCP
ADMIN_IFACE="enp4s0f1"           # Interfaz para acceso administrativo con IP estática
ADMIN_IP="192.168.0.15"          # IP fija para la interfaz administrativa
ADMIN_GATEWAY="192.168.0.1"     # Gateway para la IP estática
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# =================== Configuración de interfaces con DHCP ===================
echo "[+] Configurando interfaces físicas para usar DHCP..."
for iface in "${INTERFACES[@]}"; do
  # Para la interfaz conectada al puente
  if [[ "$iface" == "$BRIDGE_IFACE" ]]; then
    echo "[+] Configurando $iface para usar DHCP..."
    # Modificar la conexión existente para habilitar DHCP
    ACTIVE_CONN=$(nmcli -t -f NAME,DEVICE connection show | grep "$iface" | cut -d: -f1)

    if [[ -n "$ACTIVE_CONN" ]]; then
      nmcli connection modify "$ACTIVE_CONN" ipv4.method auto ipv6.method ignore
    else
      nmcli connection add type ethernet con-name "$iface" ifname "$iface" ipv4.method auto ipv6.method ignore
    fi
    # Activar la interfaz
    nmcli connection up "$iface"
  else
    # Para las otras interfaces con DHCP
    echo "[+] Configurando $iface para usar DHCP..."
    ACTIVE_CONN=$(nmcli -t -f NAME,DEVICE connection show | grep "$iface" | cut -d: -f1)

    if [[ -n "$ACTIVE_CONN" ]]; then
      nmcli connection modify "$ACTIVE_CONN" ipv4.method auto ipv6.method ignore
    else
      nmcli connection add type ethernet con-name "$iface" ifname "$iface" ipv4.method auto ipv6.method ignore
    fi

    nmcli connection up "$iface"
  fi
done

# =================== Crear y configurar el puente br0 ===================
echo "[+] Instalando bridge-utils y NetworkManager (si faltan)..."
dnf install -y bridge-utils NetworkManager &>/dev/null

echo "[+] Eliminando conexiones previas del puente (si existen)..."
nmcli connection delete "$BRIDGE_NAME" &>/dev/null || true

echo "[+] Creando el puente $BRIDGE_NAME..."
nmcli connection add type bridge con-name "$BRIDGE_NAME" ifname "$BRIDGE_NAME" autoconnect yes ipv4.method auto ipv6.method ignore

# =================== Configuración de la interfaz administrativa con IP fija ===================
echo "[+] Configurando $ADMIN_IFACE con IP fija $ADMIN_IP..."

# Verificar si la conexión para la interfaz administrativa existe
ACTIVE_CONN_ADMIN=$(nmcli -t -f NAME,DEVICE connection show | grep "$ADMIN_IFACE" | cut -d: -f1)

if [[ -n "$ACTIVE_CONN_ADMIN" ]]; then
  # Modificar la conexión existente para configurar una IP estática
  echo "[+] Modificando la conexión $ACTIVE_CONN_ADMIN para usar IP estática..."
  nmcli connection modify "$ACTIVE_CONN_ADMIN" ipv4.method manual ipv4.addresses "$ADMIN_IP/24" ipv4.gateway "$ADMIN_GATEWAY" ipv6.method ignore
else
  # Crear una nueva conexión para la interfaz administrativa con IP estática
  echo "[+] Creando una nueva conexión para $ADMIN_IFACE con IP estática $ADMIN_IP..."
  nmcli connection add type ethernet con-name "$ADMIN_IFACE" ifname "$ADMIN_IFACE" ipv4.method manual ipv4.addresses "$ADMIN_IP/24" ipv4.gateway "$ADMIN_GATEWAY" ipv6.method ignore
fi

# Activar la interfaz administrativa
nmcli connection up "$ADMIN_IFACE"

# =================== Activar el puente y las interfaces físicas asociadas ===================
echo "[+] Activando el puente $BRIDGE_NAME..."
nmcli connection up "$BRIDGE_NAME"

# Verificar el estado final
echo "[+] Verificando el estado del puente y las interfaces..."
ip a show "$BRIDGE_NAME"
nmcli device status | grep "$BRIDGE_NAME"

echo "[✔] El puente $BRIDGE_NAME está configurado con éxito, la interfaz administrativa tiene IP fija, y las interfaces físicas están configuradas con DHCP."
