#!/bin/bash
# finalize-network.sh
# 🔄 Reinicia NetworkManager y nftables, y muestra la tabla de rutas del host

set -euo pipefail

echo "🔄 Reiniciando NetworkManager..."
sudo systemctl restart NetworkManager

echo "🔥 Recargando reglas de firewall desde /etc/sysconfig/nftables.conf..."
if [[ -f /etc/sysconfig/nftables.conf ]]; then
    sudo nft -f /etc/sysconfig/nftables.conf
else
    echo "⚠️ Archivo /etc/sysconfig/nftables.conf no encontrado. Saltando recarga de nftables."
fi

echo "📡 Tabla de rutas del sistema:"
ip route show

echo "✅ Red finalizada y verificada."