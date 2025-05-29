#!/bin/bash
# bridge-setup-dhcp.sh - Configura br0 con DHCP persistente en Rocky/AlmaLinux

set -e

echo "[+] Instalando bridge-utils y NetworkManager..."
sudo dnf install -y bridge-utils NetworkManager

echo "[+] Creando el bridge br0 en modo DHCP..."
sudo nmcli connection add type bridge autoconnect yes con-name br0 ifname br0

sudo nmcli connection modify br0 \
  ipv4.method auto \
  ipv6.method ignore

# ⚠️ Ajusta si tu interfaz física no es enp3s0f0
echo "[+] Agregando enp3s0f0 como esclavo de br0..."
sudo nmcli connection add type ethernet slave-type bridge \
  con-name br0-port1 ifname enp3s0f0 master br0

echo "[+] Activando br0..."
sudo nmcli connection reload
sudo nmcli connection up br0

echo "[+] Estado actual de br0:"
ip a show br0

echo "[✔] Bridge br0 en modo DHCP configurado correctamente y persistente tras reinicio."
exit 0
# Fin del script bridge-setup-dhcp.sh