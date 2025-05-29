# 🔧 KVM Bridge Setup Script para Rocky/AlmaLinux

Este repositorio contiene un script automatizado para configurar un puente de red (`br0`) en una máquina con **Rocky Linux 9.x** o **AlmaLinux 9.x**, ideal para entornos con **KVM/libvirt** donde las máquinas virtuales necesitan acceso directo a la red LAN (modo bridge).

---

## 🖥️ Características

- Crea una interfaz bridge (`br0`).
- Puede configurarse en modo **IP estática** o **DHCP**.
- Conecta una interfaz física (`enp3s0f0`) como esclava del bridge.
- Configuración persistente con **NetworkManager**.
- Instalación automática de paquetes necesarios (`bridge-utils`, `NetworkManager`).
- Verificación automática de estado.

---

## ⚙️ Requisitos

- Sistema operativo: **Rocky Linux / AlmaLinux 9.x**.
- Acceso con **sudo**.
- Interfaz de red física libre: `enp3s0f0` *(ajustar si es diferente)*.

---

## 🚀 Ejecución rápida (modo DHCP)

```bash
git clone https://github.com/vhgalvez/kvm-bridge-config.git
cd kvm-bridge-config
sudo bash bridge-setup-dhcp.sh
O para modo IP estática (editar dentro del script):

bash
Copiar
Editar
sudo bash bridge-setup-static.sh
🧪 Resultado esperado
Al finalizar, tendrás:

Una interfaz br0 activa y persistente.

Tu interfaz física enp3s0f0 conectada al bridge.

Máquinas virtuales configuradas con red tipo bridge accediendo a la LAN real.

Puedes verificarlo con:

bash
Copiar
Editar
ip a show br0
nmcli connection show
📝 Comandos manuales equivalentes (DHCP)
bash
Copiar
Editar
sudo dnf install -y bridge-utils NetworkManager
sudo nmcli connection add type bridge autoconnect yes con-name br0 ifname br0
sudo nmcli connection modify br0 ipv4.method auto ipv6.method ignore
sudo nmcli connection add type ethernet slave-type bridge \
  con-name br0-port1 ifname enp3s0f0 master br0
sudo nmcli connection up br0
📂 Configuración persistente manual (NetworkManager)
/etc/NetworkManager/system-connections/br0.nmconnection (modo estático)
ini
Copiar
Editar
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
dns=192.168.0.1;8.8.8.8

[ipv6]
method=ignore
/etc/NetworkManager/system-connections/enp3s0f0.nmconnection
ini
Copiar
Editar
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
🔄 Eliminación del bridge
Si deseas eliminar el bridge:

bash
Copiar
Editar
sudo nmcli connection delete br0
sudo nmcli connection delete br0-port1
🧠 Notas importantes
Si tu interfaz física no se llama enp3s0f0, reemplaza el nombre en el script.

Asegúrate de que tu red local tenga un servidor DHCP activo si eliges modo dinámico.

Este puente es perfecto para máquinas virtuales KVM, clústeres Kubernetes, o entornos de laboratorio con comunicación LAN directa.

📜 Licencia
MIT License — Libre para usar, modificar y distribuir.

🧠 Verificación posterior (opcional)
Después de reiniciar, puedes verificar:

bash
Copiar
Editar
nmcli con show
ip a show br0
Y si necesitas eliminarlo en el futuro:

bash
Copiar
Editar
sudo nmcli con delete br0
sudo nmcli con delete br0-port1