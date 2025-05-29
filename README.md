# 🔧 KVM Bridge Setup Script para Rocky/AlmaLinux

Este repositorio contiene un script automatizado para configurar un puente de red (`br0`) en una máquina con Rocky Linux o AlmaLinux, ideal para entornos KVM/libvirt donde se desea que las máquinas virtuales tengan acceso directo a la red LAN.

---

## 🖥️ Características

- Crea una interfaz bridge (`br0`).
- Asigna una IP estática al bridge.
- Conecta una interfaz física (`enp3s0f0`) como esclava al bridge.
- Habilita el puente de forma persistente.
- Instala automáticamente los paquetes necesarios (`bridge-utils`).
- Verifica que el puente esté activo.

---

## ⚙️ Requisitos

- Sistema operativo: **Rocky Linux 9.x / AlmaLinux 9.x**.
- Privilegios de **sudo**.
- Interfaz física disponible: `enp3s0f0`.

---

## 🚀 Ejecución rápida

```bash
git clone https://github.com/vhgalvez/kvm-bridge-config.git
cd kvm-bridge-config
sudo bash bridge-setup.sh
```

### 🧪 Resultado esperado

Al finalizar, tendrás:

- Una interfaz `br0` con IP: `192.168.0.20`.
- Tu interfaz física `enp3s0f0` conectada como esclava al bridge.
- Máquinas virtuales con acceso LAN completo si usan `br0`.

Puedes verificarlo con:

```bash
ip a | grep br0
```

---

## 📝 Comandos manuales equivalentes

Solo para aprendizaje o depuración, no es necesario ejecutarlos si usas el script.

```bash
sudo dnf install bridge-utils -y
sudo nmcli connection add type bridge autoconnect yes con-name br0 ifname br0
sudo nmcli connection modify br0 \
  ipv4.method manual \
  ipv4.addresses 192.168.0.20/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns "192.168.0.1 8.8.8.8"
sudo nmcli connection add type ethernet slave-type bridge \
  con-name br0-port1 ifname enp3s0f0 master br0
sudo nmcli connection up br0
```

---

## 📂 Archivos persistentes alternativos (NetworkManager)

Si deseas que la configuración sobreviva a cambios más complejos o auditar conexiones manualmente, puedes usar los siguientes archivos de configuración:

### `/etc/NetworkManager/system-connections/br0.nmconnection`

```ini
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
dns=192.168.0.1;

[ipv6]
method=ignore
```

### `/etc/NetworkManager/system-connections/enp3s0f0.nmconnection`

```ini
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
```

---

## 🧠 Notas

- Si tu interfaz no se llama `enp3s0f0`, ajusta el nombre en el script o en los archivos de configuración.
- Este script es ideal para clusters Kubernetes con máquinas virtuales que deben comunicarse con otros dispositivos en la red LAN.

---

## 📜 Licencia

MIT - Puedes usarlo y modificarlo libremente.