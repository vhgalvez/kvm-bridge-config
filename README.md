# 🔧 KVM Bridge Setup Scripts (DHCP) para Rocky/AlmaLinux

Este repositorio contiene dos scripts automatizados para configurar y eliminar un bridge de red llamado `br0`, útil en entornos con KVM/libvirt cuando se requiere conectividad LAN directa para las máquinas virtuales (modo bridge).

---

## 🖥️ Características

* ✅ Crea un bridge persistente llamado `br0`.
* ✅ Asigna IP mediante DHCP.
* ✅ Añade una interfaz física como esclava (por defecto: `enp3s0f0`).
* ✅ Compatible con `NetworkManager`.
* ✅ Completamente reversible mediante script de limpieza.

---

## ⚙️ Requisitos

* Rocky Linux / AlmaLinux / RHEL 9+.
* Permisos de `sudo` o acceso root.
* Una interfaz física disponible (verificable con `ip link`).
* Red local con servidor DHCP activo.

---

## 🚀 Ejecución rápida

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/kvm-bridge-config.git
cd kvm-bridge-config
```

### 2. Dar permisos de ejecución

```bash
chmod +x bridge-setup.sh bridge-cleanup.sh
```

### 3. Ejecutar el script de configuración

```bash
sudo ./bridge-setup.sh
```

### 4. Para revertir la configuración

```bash
sudo ./bridge-cleanup.sh
sudo systemctl restart NetworkManager
```

---

## 📍 Notas adicionales

* Verifica tus interfaces con `ip link` o `nmcli device status`.
* Puedes cambiar la interfaz física modificando la variable `PHYS_IFACE` en el script `bridge-setup.sh`.
* Este tipo de bridge permite que tus VMs se comporten como si estuvieran directamente conectadas a la red física, ideal para pruebas de laboratorio, Kubernetes bare-metal, etc.

---

## 📜 Licencia

MIT — Libre para usar, modificar y distribuir.



sudo nmcli connection add type bridge con-name br0 ifname br0 autoconnect yes ipv4.method auto ipv6.method ignore
sudo nmcli connection add type ethernet con-name br0-port-enp3s0f0 ifname enp3s0f0 master br0
sudo nmcli connection up br0
sudo nmcli connection up br0-port-enp3s0f0


ip a show br0
sudo brctl show br0
nmcli connection show



# Mostrar interfaces y sus IPs (asegurarse que br0 no tiene IP IPv4)
ip a show br0

# Mostrar interfaces esclavas del bridge
sudo brctl show br0

# (Opcional) Confirmar que NetworkManager tiene las conexiones activas
nmcli connection show



resource "libvirt_domain" "vm" {
  for_each = var.vm_linux_definitions

  name   = each.value.hostname
  memory = each.value.memory
  vcpu   = each.value.cpus

  network_interface {
    #network_id = libvirt_network.br0.id
    bridge     = "br0"
    addresses  = [each.value.ip]
  }
