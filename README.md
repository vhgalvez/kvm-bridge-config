# 🔧 KVM Bridge Setup Scripts (DHCP) para Rocky/AlmaLinux

Este repositorio contiene tres scripts automatizados para configurar y eliminar un bridge de red llamado `br0`, útil en entornos con KVM/libvirt cuando se requiere conectividad LAN directa para las máquinas virtuales (modo bridge).

---

## 🖥️ Características

- ✅ Crea un bridge persistente llamado `br0` sin IP, permitiendo que las máquinas virtuales obtengan una IP.
- ✅ Configura una interfaz física con IP fija (`192.168.0.40`).
- ✅ Configura dos interfaces físicas con DHCP.
- ✅ Compatible con NetworkManager.
- ✅ Completamente reversible mediante el script de limpieza.
- ✅ Ideal para entornos de pruebas y Kubernetes bare-metal.

---

## ⚙️ Requisitos

- **Sistema operativo:** Rocky Linux / AlmaLinux / RHEL 9+.
- **Permisos:** Acceso como sudo o root.
- **Hardware:** Una interfaz física disponible (verificable con `ip link`).
- **Red:** Red local con servidor DHCP activo.

---

## 🚀 Ejecución rápida

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/kvm-bridge-config.git
cd kvm-bridge-config
```

### Paso 2: Dar permisos de ejecución

Antes de ejecutar los scripts, asegúrate de otorgarles permisos de ejecución:

```bash
sudo chmod +x network-cleanup.sh network-setup-static-dhcp.sh network-setup-bridge.sh
```

### Paso 3: Ejecutar los scripts en el siguiente orden

#### 1. Limpiar configuraciones previas de red

Este script eliminará todas las configuraciones de red previas.

```bash
sudo bash network-cleanup.sh
```

#### 2. Configurar interfaces físicas con IP fija y DHCP

Este script configurará:

- Una interfaz (`enp3s0f0`) con IP fija `192.168.0.40/24`.
- Dos interfaces (`enp3s0f1` y `enp4s0f0`) con DHCP.

```bash
sudo bash network-setup-static-dhcp.sh
```

#### 3. Crear el puente `br0` sin IP

Este script creará un puente `br0` sin IP y añadirá una interfaz física como esclava para permitir que las máquinas virtuales obtengan IPs automáticamente.

```bash
sudo bash network-setup-bridge.sh
```

### Paso 4: Revertir la configuración

Si necesitas eliminar la configuración de red creada por los scripts, puedes ejecutar:

```bash
sudo bash network-cleanup.sh
sudo systemctl restart NetworkManager
```

---

## 📍 Notas adicionales

- Verifica tus interfaces con `ip link` o `nmcli device status`.
- Puedes cambiar la interfaz física modificando las variables en los scripts `network-setup-static-dhcp.sh` y `network-setup-bridge.sh`.
- Este tipo de bridge permite que tus VMs se comporten como si estuvieran directamente conectadas a la red física, ideal para:
  - Pruebas de laboratorio.
  - Kubernetes bare-metal.
  - Entornos de desarrollo.

---

## 📜 Licencia

MIT — Libre para usar, modificar y distribuir.

---

Este archivo README.md ahora incluye la información sobre los tres scripts, su orden de ejecución, cómo otorgar permisos de ejecución y cómo verificar su estado.