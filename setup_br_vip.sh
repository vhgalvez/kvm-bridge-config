#!/bin/bash
# setup_br_vip.sh - Configura el bridge virtual br-vip con IP 10.17.5.1/24 en Rocky Linux

set -euo pipefail

# Variables
BR_NAME="br-vip"
BR_IP="10.17.5.1/24"

echo "🔧 Creando bridge $BR_NAME..."
sudo nmcli connection add type bridge con-name "$BR_NAME" ifname "$BR_NAME" stp no

echo "🌐 Asignando IP $BR_IP al bridge $BR_NAME..."
sudo nmcli connection modify "$BR_NAME" ipv4.method manual ipv4.addresses "$BR_IP"
sudo nmcli connection modify "$BR_NAME" ipv4.gateway ""
sudo nmcli connection modify "$BR_NAME" connection.autoconnect yes

echo "🚀 Levantando bridge $BR_NAME..."
sudo nmcli connection up "$BR_NAME"

echo "🔍 Verificando configuración..."
ip a show "$BR_NAME"
nmcli connection show "$BR_NAME"