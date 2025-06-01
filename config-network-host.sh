#!/bin/bash
# config-network-host.sh - Configura el puente de red y las interfaces físicas con DHCP y IP fija.
# Compatible con Rocky Linux 9+, AlmaLinux 9+, RHEL 9+
# Este script establece el puente `br0` con DHCP y asigna IP estática a una interfaz específica (`enp3s0f0`).

set -euo pipefail

# =================== Configuración ===================
BRIDGE_NAME="br0"             # Nombre del puente
PRIMARY_PHYS_IFACE="enp3s0f0" # Interfaz física para administración con IP fija

# Configuración IP para el HOST (a través de br0)
HOST_IP_BASE="192.168.0"       # Base de la IP
HOST_IP_SUBNET="/24"           # Subnet Mask
HOST_GATEWAY="192.168.0.1"     # Gateway para el host
HOST_DNS="8.8.8.8,1.1.1.1,10.17.3.11"    # Servidores DNS para el host

# Otras interfaces físicas que se configurarán para usar DHCP
OTHER_PHYS_IFACES=("enp3s0f1" "enp4s0f0" "enp4s0f1")
# =====================================================

echo "[+] Verificando permisos..."
if [[ "$EUID" -ne 0 ]]; then
  echo "[-] Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# Función para verificar si la IP ya está en uso
check_ip_in_use() {
  local ip=$1
  ping -c 1 "$ip" &>/dev/null
  return $?
}

# Función para obtener una IP libre en el rango 192.168.0.16-192.168.0.254
get_free_ip() {
  for ip in {16..254}; do
    local test_ip="192.168.0.$ip"
    if ! check_ip_in_use "$test_ip"; then
      echo "$test_ip"
      return 0
    fi
  done
  echo "[-] No se pudo encontrar una IP libre en el rango especificado." >&2
  exit 1
}

# =================== Configuración inicial ===================
# Determina si la IP base está en uso
HOST_IP_ADDRESS="192.168.0.15"

echo "[+] Verificando si la IP $HOST_IP_ADDRESS ya está en uso..."
check_ip_in_use "$HOST_IP_ADDRESS"
if [[ $? -eq 0 ]]; then
  echo "[!] La IP $HOST_IP_ADDRESS está en uso, se asignará una IP libre."
  HOST_IP_ADDRESS=$(get_free_ip)
  echo "[+] IP asignada: $HOST_IP_ADDRESS"
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

echo "[+] Creando y configurando el puente $BRIDGE_NAME..."
# Configuración del puente con DHCP
nmcli connection add type bridge con-name "$BRIDGE_NAME" ifname "$BRIDGE_NAME" \
    ipv4.method auto \
    ipv4.gateway "$HOST_GATEWAY" \
    ipv4.dns "$HOST_DNS" \
    autoconnect yes

echo "[+] Configurando $PRIMARY_PHYS_IFACE como esclava del puente $BRIDGE_NAME..."
# Crear el perfil esclavo. El 'master' automáticamente levanta al esclavo.
nmcli connection add type ethernet con-name "${PRIMARY_PHYS_IFACE}-slave" ifname "$PRIMARY_PHYS_IFACE" \
  master "$BRIDGE_NAME" slave-type bridge autoconnect yes

# Activar el puente (esto debería levantar al esclavo también)
echo "[+] Activando el puente $BRIDGE_NAME..."
nmcli connection up "$BRIDGE_NAME" || { echo "[-] Falló la activación del puente $BRIDGE_NAME. Abortando." >&2; exit 1; }
# Activar la interfaz esclava explícitamente por si acaso
nmcli connection up "${PRIMARY_PHYS_IFACE}-slave" || { echo "[-] Falló la activación de la interfaz esclava ${PRIMARY_PHYS_IFACE}-slave. Abortando." >&2; exit 1; }

# Configuración de la IP fija para el host
echo "[+] Configurando IP fija $HOST_IP_ADDRESS en la interfaz $PRIMARY_PHYS_IFACE..."
nmcli connection modify "${PRIMARY_PHYS_IFACE}-slave" ipv4.method manual ipv4.addresses "$HOST_IP_ADDRESS"

# Activar la conexión del host
nmcli connection up "${PRIMARY_PHYS_IFACE}-slave" || { echo "[-] Falló la activación de la interfaz $PRIMARY_PHYS_IFACE con IP fija. Abortando." >&2; exit 1; }

echo "[+] Verificando estado final de las interfaces:"
nmcli device status

echo "[+] Estado de IP del puente $BRIDGE_NAME:"
ip a show "$BRIDGE_NAME"

echo "[+] Rutas actuales del host:"
ip route show

echo "[✔] Configuración de red del host completada. '$BRIDGE_NAME' es ahora la interfaz principal con IP $HOST_IP_ADDRESS (o DHCP)."
echo "[!] Si la IP $HOST_IP_ADDRESS ya estaba en uso en la red, podría haber un conflicto."