#!/bin/bash
# bridge-setup.sh - Automatiza la creación de un puente (bridge) br0 para KVM/QEMU en Rocky/AlmaLinux

set -e

# 1. Instalar herramientas necesarias
echo "[+] Instalando bridge-utils..."
sudo dnf install -y bridge-utils NetworkManager

# 2. Crear conexión bridge br0 y asignar IP estática
echo "[+] Creando el bridge br0 con IP 192.168.0.20..."
sudo nmcli connection add type bridge autoconnect yes con-name br0 ifname br0
sudo nmcli connection modify br0 \
  ipv4.method manual \
  ipv4.addresses 192.168.0.20/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns "192.168.0.1 8.8.8.8"

# 3. Agregar interfaz física como esclava del bridge
echo "[+] Agregando enp3s0f0 como esclavo de br0..."
sudo nmcli connection add type ethernet slave-type bridge \
  con-name br0-port1 ifname enp3s0f0 master br0

# 4. Activar el bridge
echo "[+] Activando el bridge..."
sudo nmcli connection up br0

# 5. Verificar
echo "[+] Estado de la interfaz br0:"
ip a show br0

# Alternativa persistente (archivos NetworkManager)
CONFIG_DIR="/etc/NetworkManager/system-connections"
echo "[+] Escribiendo configuración persistente en $CONFIG_DIR..."

sudo tee $CONFIG_DIR/br0.nmconnection > /dev/null <<EOF
[connection]
id=br0
type=bridge
interface-name=br0
autoconnect=true

[bridge]
stp=false

[ipv4]
method=manual
address1=192.168.0.20/24,192.168.0.1
dns=192.168.0.11;
dns-search=

[ipv6]
method=ignore
EOF

sudo tee $CONFIG_DIR/enp3s0f0.nmconnection > /dev/null <<EOF
[connection]
id=enp3s0f0
type=ethernet
interface-name=enp3s0f0
master=br0
slave-type=bridge
autoconnect=true

[ipv4]
method=disabled

[ipv6]
method=ignore
EOF

# 6. Reiniciar NetworkManager para aplicar
sudo nmcli connection reload
sudo nmcli connection up br0

echo "[✔] Bridge br0 configurado correctamente."
exit 0
# Fin del script