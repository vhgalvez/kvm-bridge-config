# 🖧 Configuración de Red - Virtualización Server

Este proyecto contiene scripts automatizados para configurar la red de un servidor de virtualización con 4 interfaces físicas, ideal para laboratorios KVM/libvirt.

---

## 🧭 Diseño de Red

| Interfaz     | IP del Host       | Función                  | Gateway | Observaciones |
|--------------|-------------------|--------------------------|---------|----------------|
| enp3s0f0     | 192.168.0.40/24   | Acceso LAN / Internet    | ✅      | Única interfaz con gateway |
| enp3s0f1     | 192.168.50.1/24   | Red de Gestión Privada   | ❌      | Aislada, sin puerta de enlace |
| enp4s0f0     | 192.168.60.1/24   | Red de Pruebas / WiFi    | ❌      | Aislada, sin puerta de enlace |
| enp4s0f1     | (sin IP)          | Esclava de br0 (bridge)  | ❌      | Conectada al bridge `br0` |

---

## 📂 Archivos Incluidos

| Archivo                        | Descripción |
|-------------------------------|-------------|
| `setup-admin-interface.sh`    | Configura `enp3s0f0` con IP fija y gateway. |
| `setup-management-network.sh` | Configura `enp3s0f1` como red de gestión sin gateway. |
| `setup-test-network.sh`       | Configura `enp4s0f0` como red de pruebas sin gateway. |
| `setup-bridge-br0.sh`         | Crea el `bridge br0` y añade `enp4s0f1` como esclava. |
| `finalize-network.sh`         | Reinicia NetworkManager, recarga nftables y muestra rutas. |

---

## ⚙️ Requisitos

- Rocky Linux 9 / AlmaLinux 9 / RHEL 9+
- NetworkManager instalado y activo
- `nmcli` disponible
- Privilegios `sudo` para aplicar configuraciones
- Reglas de firewall ubicadas en `/etc/sysconfig/nftables.conf` (opcional)

---

## 🚀 Instrucciones de Ejecución

1. **Dar permisos de ejecución a los scripts:**

    ```bash
    chmod +x setup-*.sh finalize-network.sh
    ```

2. **Asegúrate de que no hay configuraciones activas previas que puedan interferir.**

3. **Ejecuta los scripts en el siguiente orden:**

    ```bash
    sudo bash setup-admin-interface.sh
    sudo bash setup-management-network.sh
    sudo bash setup-test-network.sh
    sudo bash setup-bridge-br0.sh
    sudo bash finalize-network.sh
    ```

4. **Verifica la red:**

    ```bash
    ip a
    ip route
    nmcli con show
    ```

---

## 🔐 Seguridad

- La red de gestión (`192.168.50.0/24`) está aislada para acceso seguro (SSH).
- No se definen rutas por defecto en ninguna interfaz excepto `enp3s0f0`, evitando conflictos de enrutamiento.
- Se recomienda configurar reglas de `nftables` para NAT y reenvío de tráfico si usas KVM/libvirt con NAT.

---

## 📄 Licencia

MIT. Puedes modificar y reutilizar libremente.

---

## ✍️ Autor

Víctor Hugo Gálvez Sastoque  
DevOps | Infraestructura | Automatización | Kubernetes  
GitHub: [vhgalvez](https://github.com/vhgalvez)