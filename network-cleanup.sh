#!/bin/bash
# network-cleanup.sh - Elimina todas las configuraciones de red relacionadas con el puente y las interfaces físicas.
# 🧹 Elimina TODAS las conexiones existentes en NetworkManager

set -euo pipefail

echo "🧨 Eliminando todas las conexiones configuradas..."

# Obtener todas las conexiones activas y eliminarlas
nmcli -t -f NAME connection show | while read -r name; do
  echo "❌ Eliminando conexión: $name"
  nmcli connection delete "$name" || true
done

# Reiniciar el NetworkManager
echo "🔄 Reiniciando NetworkManager..."
sudo systemctl restart NetworkManager

echo "✅ Limpieza completada. Puedes verificar las conexiones con 'nmcli connection show'."