🧩 Resumen Documentado: Problema y Solución de la Red VIP en Entorno Virtualizado K3s
🛑 Problema Detectado: VIPs en la Red Principal Generaban Conflictos
En el entorno de virtualización KVM/libvirt con Kubernetes K3s y balanceo de carga HAProxy + Keepalived, se intentó asignar dos direcciones IP flotantes (VIPs: 10.17.5.10 y 10.17.5.30) directamente sobre la interfaz principal de red (eth0) de la VM k8s-api-lb, la cual ya estaba conectada a la red física 192.168.0.0/24.

Esto generaba varios problemas:
Rutas conflictivas y no deterministas:
Al tener múltiples rangos IP en la misma interfaz (192.168.0.0/24, 10.17.4.0/24, 10.17.5.0/24), el sistema intentaba enrutar tráfico de 10.17.x.x por interfaces incorrectas, provocando errores como:

Destination Host Unreachable

Respuestas ARP erróneas o perdidas

Interferencia con otros servicios:
Las VIPs compartían la misma interfaz que usaba eth0 para conectividad con Internet o acceso SSH, lo que provocaba problemas al levantar HAProxy y establecer rutas estables.

Fallos en la alta disponibilidad (HA):
Keepalived no podía mantener correctamente las IPs VIP porque no estaban en una interfaz separada. Esto afectaba el failover y la detección de nodos activos.

✅ Solución Implementada: Red Virtual Dedicada para las VIPs
Se diseñó una solución limpia y robusta basada en la separación total del tráfico VIP:

1. Crear una Red Virtual Aislada en el Host
Se creó un nuevo bridge virtual en el host Rocky Linux:
br-vip con IP 10.17.5.1/24

Este bridge no está conectado a ninguna interfaz física, por lo que actúa como una red virtual interna segura.

Es persistente y administrado por nmcli (NetworkManager), ideal para entornos con VMs.

2. Añadir una Nueva Interfaz Virtual en la VM k8s-api-lb
Se apagó la VM y se usó virsh attach-interface para conectar una nueva interfaz (virtio) al bridge br-vip.

Esta interfaz virtual aparece dentro de la VM como eth1 o similar, completamente separada de eth0.

3. Reasignar Direcciones IP
Se limpiaron todas las VIPs de eth0, dejando solo la IP 192.168.0.30.

Se asignaron las VIPs 10.17.5.10 y 10.17.5.30 exclusivamente a la nueva interfaz (eth1).

4. Configuración Persistente
Se usó nmcli dentro de la VM para hacer persistente esta configuración.

Ahora cada interfaz maneja una sola red:

eth0 = red de gestión (LAN, SSH, acceso público)

eth1 = red virtual interna para balanceo de carga (VIPs, HAProxy, K3s API)

🎯 Beneficios de Esta Solución
✅ Aislamiento total del tráfico VIP

✅ Eliminación de rutas conflictivas o no deterministas

✅ Alta disponibilidad estable y sin errores de red

✅ Escalabilidad limpia para añadir más VIPs o nodos

✅ Mantenimiento más sencillo y segura depuración

🛠️ Resumen Técnico de Componentes Involucrados
Componente	Función
br-vip (host)	Bridge virtual aislado para red 10.17.5.0/24
virsh attach-interface	Añade interfaz virtual conectada a br-vip en la VM
nmcli (host y VM)	Herramienta para definir IPs y persistencia en NetworkManager
ip addr flush/add	Limpieza y reconfiguración de interfaces
HAProxy + Keepalived	Se benefician de las VIPs dedicadas para failover y balanceo