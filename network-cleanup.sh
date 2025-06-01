#!/bin/bash
# network-cleanup.sh - Elimina todas las configuraciones de red relacionadas con el puente y las interfaces físicas.
# 🧹 Elimina TODAS las conexiones existentes en NetworkManager

set -euo pipefail

echo "🧨 Eliminando todas las conexiones configuradas..."

nmcli connection show | awk 'NR>1 {print $1}' | while read -r name; do
  echo "❌ Eliminando conexión: $name"
  nmcli connection delete "$name" || true
done

echo "✅ Limpieza completada. Puedes reiniciar NetworkManager si deseas."
