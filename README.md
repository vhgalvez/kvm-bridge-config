# 📧 Configuración de Red - Virtualización Server

Este proyecto contiene scripts automatizados para configurar la red de un servidor de virtualización con 4 interfaces físicas, ideal para laboratorios KVM/libvirt.

---

## 🧽 Diseño de Red

| Interfaz | IP del Host     | Función                 | Gateway | Observaciones                 |
| -------- | --------------- | ----------------------- | ------- | ----------------------------- |
| enp3s0f0 | 192.168.0.40/24 | Acceso LAN / Internet   | ✅      | Única interfaz con gateway    |
| enp3s0f1 | 192.168.50.1/24 | Red de Gestión Privada  | ❌      | Aislada, sin puerta de enlace |
| enp4s0f0 | 192.168.60.1/24 | Red de Pruebas / WiFi   | ❌      | Aislada, sin puerta de enlace |
| enp4s0f1 | (sin IP)        | Esclava de br0 (bridge) | ❌      | Conectada al bridge `br0`     |

---

## 📂 Archivos Incluidos

| Archivo                       | Descripción                                                |
| ----------------------------- | ---------------------------------------------------------- |
| `setup-admin-interface.sh`    | Configura `enp3s0f0` con IP fija y gateway.                |
| `setup-management-network.sh` | Configura `enp3s0f1` como red de gestión sin gateway.      |
| `setup-test-network.sh`       | Configura `enp4s0f0` como red de pruebas sin gateway.      |
| `setup-bridge-br0.sh`         | Crea el `bridge br0` y añade `enp4s0f1` como esclava.      |
| `finalize-network.sh`         | Reinicia NetworkManager, recarga nftables y muestra rutas. |
| `network-cleanup.sh`          | Limpia configuraciones previas de red.                     |

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


- **limpiar configuraciones previas de red:**

```bash
sudo bash network-cleanup.sh
```

- **configurar las interfaces de red:**

```bash
sudo bash setup-admin-interface.sh
sudo bash setup-management-network.sh
sudo bash setup-test-network.sh
sudo bash setup-bridge-br0.sh
sudo bash setup_br_vip.sh
sudo bash finalize-network.sh
```

1. **Verifica la red:**

   ```bash
   ip a
   ip route
   nmcli con show
   ```

---

## 🌟 Acceso a la Red de Gestión `192.168.50.0/24` desde tu PC en la red principal `192.168.0.0/24`

Esta red de gestión (asignada a la interfaz `enp3s0f1` con IP `192.168.50.1`) está diseñada para ser segura y aislada del resto del tráfico del servidor. Existen dos formas prácticas de acceder a ella desde tu PC personal.

### ✅ Opcion 1: Conexión Física Directa (Alta Seguridad)

**¿Qué implica?**
Conectas físicamente tu PC a la red de gestión, ya sea directamente al puerto `enp3s0f1` del servidor o a un switch exclusivo para esta red.

**Configuración de red en tu PC (Windows/Linux):**

- **IP:** `192.168.50.10`
- **Máscara de subred:** `255.255.255.0`
- **Gateway:** _(dejar vacío)_

**Ventajas:**

- Aislamiento total entre redes.
- Seguridad reforzada: solo accede quien tenga conexión física.

**Desventajas:**

- Requiere cambiar cableado o configuración IP manualmente.
- Menos cómodo para uso frecuente o automatizado.

### ⚙️ Opcion 2: Ruta Estática desde la Red Principal (Mayor Comodidad)

**¿Qué implica?**
El servidor (IP `192.168.0.40`) actúa como puente entre tu PC (en la red `192.168.0.0/24`) y la red de gestión (`192.168.50.0/24`).

**Configuración en Windows (CMD como Administrador):**

```cmd
route ADD 192.168.50.0 MASK 255.255.255.0 192.168.0.40 METRIC 1 -p
```

> El modificador `-p` hace que la ruta sea persistente tras reiniciar.

**Ventajas:**

- Acceso directo desde tu red habitual.
- No necesitas reconectar cables ni cambiar configuración IP.

**Desventajas:**

- Rompe el aislamiento total entre redes.
- Otros dispositivos en la LAN podrían intentar acceder si conocen la ruta.

---

## 🔐 Propósito de la Red de Gestión `192.168.50.0/24`

Reservada exclusivamente para tareas administrativas y de monitorización del servidor, como:

- ✅ Acceso SSH seguro al host (`192.168.50.1`).
- ✅ Interfaces web administrativas (ej. Cockpit).
- ✅ Transferencia de archivos (scp, sftp, WinSCP).
- ✅ Recolección de métricas con Prometheus, Node Exporter, etc.

---

## 📌 Recomendación de Uso

| Entorno              | Opcion Recomendada                             |
| -------------------- | ---------------------------------------------- |
| Producción / Crítico | 🛡️ Opcion 1 (Conexión Física - Alta Seguridad) |
| Laboratorio / Dev    | ⚙️ Opcion 2 (Ruta Estática - Mayor Comodidad)  |

---

## 🔒 Seguridad General

- Solo `enp3s0f0` tiene salida a Internet mediante gateway (`192.168.0.1`).
- Las otras interfaces están aisladas sin gateway para evitar fugas de tráfico.
- Se recomienda configurar reglas de `nftables` para:

  - Control de acceso.
  - Aplicar NAT para acceso a Internet de VMs.

## ✅ Estado Actual del Host `virtualizacion-server`

| Interfaz   | IP asignada       | Función esperada                       | Estado | Observaciones                                                                 |
|------------|-------------------|----------------------------------------|--------|--------------------------------------------------------------------------------|
| `enp3s0f0` | `192.168.0.40`    | Salida a Internet (LAN principal)      | ✅ UP  | Correcta. Es la única con gateway. No se usa para gestión.                    |
| `enp3s0f1` | `192.168.50.1`    | Red de Gestión Privada                 | ✅ UP  | Correcta. IP estática, sin gateway. Ideal para acceso SSH.                   |
| `enp4s0f0` | `192.168.60.1`    | Red de Pruebas / WiFi                  | ✅ UP  | Correcta. IP estática, sin gateway. Funciona para conectar router Wi-Fi.     |
| `enp4s0f1` | *(sin IP)*        | Esclava del bridge `br0` (para VMs)    | ✅ UP  | Correcto. Forma parte del bridge `br0`, no debe tener IP.                    |
| `br0`      | *(sin IP IPv4)*   | Puente de red para VMs                 | ✅ UP  | OK. Podrías asignarle IP si necesitas acceder al host desde la LAN (opcional). |
| `lo`       | `127.0.0.1`       | Loopback                               | ✅ UP  | Normal.                                                                       |


---

## 📄 Licencia

MIT. Puedes modificar y reutilizar libremente.

---

## ✍️ Autor

**Víctor Hugo Gálvez Sastoque**  
Ingeniero de Sistemas con más de 20 años de experiencia en infraestructura, DevOps y automatización.  
Orientado a la dirección tecnológica con visión de CTO/CEO en entornos de alto impacto.

🌐 **GitHub:** [@vhgalvez](https://github.com/vhgalvez)  
💼 **LinkedIn:** [victor-hugo-galvez-sastoque](https://www.linkedin.com/in/victor-hugo-galvez-sastoque/)
