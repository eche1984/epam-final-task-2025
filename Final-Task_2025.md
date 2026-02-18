================================================================================
DOCUMENTO DE DECISIONES DE DISEÑO - MOVIE ANALYST DEPLOYMENT
================================================================================

Este documento explica las decisiones técnicas tomadas para el despliegue de la
aplicación Movie Analyst en AWS y GCP, incluyendo la infraestructura y las
herramientas de configuración utilizadas.

================================================================================
1. ARQUITECTURA DE RED Y SEGURIDAD
================================================================================

1.1. Diseño de VPC/Red Virtual
--------------------------------
DECISIÓN: Crear una VPC con 3 subnets privadas para las VMs (frontend, backend y
ansible), subnets para el load balancer y subnets privadas para la DB.

RAZONES:
- Separación de responsabilidades: Cada componente tiene su propia subnet con
  reglas de seguridad específicas.
- Seguridad por capas: El backend en subnet privada no tiene acceso directo
  desde internet, reduciendo la superficie de ataque.
- Aislamiento de red: Las subnets permiten control granular del tráfico mediante
  Security Groups/Firewall Rules.
- Cumplimiento de mejores prácticas: Sigue el principio de menor privilegio
  (principle of least privilege).

1.2. Configuración de Rutas y Conectividad
-------------------------------------------
DECISIÓN: 
- Load balancer: Subnets públicas con Internet Gateway (AWS) o acceso
  directo (GCP).
- Frontend, Backend y Ansible: Subnets privadas con NAT Gateway (AWS) o 
  Cloud NAT (GCP) para acceso saliente a internet (descargas de paquetes,
  updates).

RAZONES:
- El load balancer va a ser el responsable de recibir las solicitudes de
  los usuarios y dirigirlas hacia el frontend. Esto nos permite que el frontend
  pueda quedar en una subnet privada, sin la necesidad de quedar expuesto a
  internet.
- Backend solo necesita comunicación con frontend y base de datos, no requiere
  acceso directo del exterior.
- NAT Gateway (AWS) o Cloud NAT (GCP) permite que las subnets privadas accedan a
  internet para actualizaciones sin exponerlas públicamente.

1.3. Reglas de Firewall/Security Groups
----------------------------------------
DECISIÓN: Implementar reglas específicas por tipo de tráfico y origen.

RAZONES:
- Seguridad: Solo permite el tráfico estrictamente necesario.
- Comunicación interna: Se permite la comunicación entre las 3 VMs vía SSH para
  gestión, monitoreo y troubleshooting (en caso de ser necesario).
- Load Balancer: HTTP/HTTPS desde internet.
- Frontend: HTTP/HTTPS desde Load Balancer.
- Backend: Puerto de aplicación solo desde las tres VMs.
- Base de datos: MySQL (3306) desde todas las tres VMs, en caso de ser necesario
  realizar algún tipo de troubleshooting.


================================================================================
2. INFRAESTRUCTURA DE COMPUTO
================================================================================

2.1. Elección de Instancias/VMs
--------------------------------
DECISIÓN: Usar instancias pequeñas (t2.micro en AWS, e2-micro en GCP) para
reducir costos a la mínima expresión.

RAZONES:
- Costo: Bajo presupuesto disponible, debido a circunstancias coyunturales del
  cliente.
- Escalabilidad: Fácilmente escalables a instancias más grandes, en caso de
  requerir mayor capacidad de procesamiento y disponer de un presupuesto
  mayor.
- Suficientes recursos: Para aplicaciones Node.js ligeras como Movie Analyst,
  estas instancias son adecuadas.
- Flexibilidad: Permite cambiar el tipo de instancia mediante variables de
  Terraform sin modificar código.

2.2. Gestión de Aplicaciones con PM2
-------------------------------------
DECISIÓN: Usar PM2 para gestionar los procesos Node.js.

RAZONES:
- Confiabilidad: PM2 reinicia automáticamente las aplicaciones si fallan.
- Gestión de procesos: Facilita el inicio, detención y monitoreo de aplicaciones.
- Logs: PM2 gestiona logs de forma centralizada.
- Startup automático: PM2 puede configurarse para iniciar aplicaciones al
  arrancar el sistema.
- Producción: Es una herramienta estándar en la industria para aplicaciones
  Node.js en producción.

2.3. User Data / Startup Scripts
----------------------------------
DECISIÓN: Instalar Python3 y pip en todas las instancias mediante user data.

RAZONES:
- Requisito de Ansible: Ansible requiere Python en los hosts remotos.
- Automatización: Permite que Ansible funcione inmediatamente después del
  despliegue de infraestructura.
- Consistencia: Asegura que todas las instancias tengan las herramientas
  necesarias desde el inicio.

================================================================================
3. BASE DE DATOS
================================================================================

3.1. Elección de Base de Datos como Servicio (DBaaS)
-----------------------------------------------------
DECISIÓN: Usar RDS MySQL (AWS) y Cloud SQL for MySQL (GCP) en lugar de instalar
el motor de base de datos en una VM aparte.

RAZONES:
- Gestión simplificada: El proveedor maneja backups y parches.
- Seguridad: Mejores prácticas de seguridad implementadas por el proveedor.
- Mantenimiento: Reduce la carga operativa del equipo de DevOps y de infra.
- Backups automáticos: Configuración de backups automáticos con retención
  configurable.
- Escalabilidad y Alta disponibilidad (HA): Deja abierta la posiblidad a
  habilitar en el futuro el feature de HA y el escalamiento automático (vertical
  u horizontal), si fuera necesario.
- Alta disponibilidad: Opciones de multi-AZ y replicación incluidas.

3.2. Configuración de Red para Base de Datos
---------------------------------------------
DECISIÓN: Base de datos en subnet privada, sin IP pública, accesible desde las
las tres instancias mencionadas.

RAZONES:
- Seguridad: La base de datos no está expuesta a internet.
- Reducción de superficie de ataque: Solo las aplicaciones autorizadas pueden
  acceder.
- Cumplimiento: Mejores prácticas de seguridad para bases de datos sensibles.
- Network isolation: La base de datos está completamente aislada de tráfico
  público.

3.3. Esquema de Base de Datos
-------------------------------
DECISIÓN: Crear el esquema automáticamente mediante Ansible durante el
despliegue del backend.

RAZONES:
- Automatización: Elimina pasos manuales propensos a errores.
- Idempotencia: Ansible puede ejecutarse múltiples veces sin problemas.
- Versionado: El esquema puede versionarse junto con el código de aplicación.
- Consistencia: Asegura que el esquema sea el mismo en todos los entornos.

================================================================================
4. INFRAESTRUCTURA COMO CÓDIGO (IaC)
================================================================================

4.1. Elección de Terraform
---------------------------
DECISIÓN: Usar Terraform para provisionar la infraestructura.

RAZONES:
- Multi-cloud: Terraform soporta múltiples proveedores (AWS, GCP, Azure, etc.)
  con sintaxis consistente.
- Estado: Terraform mantiene estado de la infraestructura, permitiendo cambios
  incrementales.
- Modularidad: Permite crear módulos reutilizables para diferentes componentes.
- Idempotencia: Puede ejecutarse múltiples veces con resultados predecibles.
- Ecosistema: Amplia comunidad y recursos disponibles.
- Versionado: La infraestructura puede versionarse en control de versiones.

4.2. Estructura Modular de Terraform
-------------------------------------
DECISIÓN: Organizar Terraform en módulos separados (VPC, EC2/Compute, RDS/SQL).

RAZONES:
- Reutilización: Los módulos pueden reutilizarse en diferentes proyectos y en
  diferentes entornos.
- Mantenibilidad: Código más fácil de mantener y entender.
- Separación de responsabilidades: Cada módulo tiene una responsabilidad
  específica.
- Testing: Los módulos pueden probarse independientemente.
- Escalabilidad: Fácil agregar nuevos módulos o modificar existentes.

4.3. Variables y Outputs
--------------------------
DECISIÓN: Usar variables extensivamente y definir outputs útiles.

RAZONES:
- Flexibilidad: Permite personalizar el despliegue sin modificar código.
- Reutilización: Los módulos pueden usarse con diferentes configuraciones.
- Seguridad: Variables sensibles pueden manejarse de forma segura.
- Integración: Los outputs facilitan la integración con otras herramientas
  (Ansible, scripts, etc.).
- Documentación: Las variables documentan qué parámetros son configurables.

================================================================================
5. CONFIGURACIÓN Y GESTIÓN (ANSIBLE)
================================================================================

5.1. Elección de Ansible
-------------------------
DECISIÓN: Usar Ansible para la configuración y despliegue de aplicaciones.

RAZONES:
- Agent-less: No requiere agentes instalados en los hosts, solo SSH.
- Idempotencia: Puede ejecutarse múltiples veces con resultados consistentes.
- Simplicidad: Sintaxis YAML fácil de leer y escribir.
- Módulos: Amplia biblioteca de módulos para diferentes tareas.
- Multi-cloud: Funciona igual independientemente del proveedor de cloud.
- Orquestación: Puede coordinar tareas complejas en múltiples hosts.

5.2. Estructura con Roles
--------------------------
DECISIÓN: Organizar Ansible usando roles separados para frontend y backend.

RAZONES:
- Modularidad: Cada role encapsula la configuración de un componente.
- Reutilización: Los roles pueden reutilizarse en diferentes playbooks.
- Organización: Estructura clara y fácil de navegar.
- Mantenibilidad: Cambios en un componente no afectan a otros.
- Testing: Los roles pueden probarse independientemente.
- Best practices: Sigue las mejores prácticas de Ansible.

5.3. Templates y Variables
---------------------------
DECISIÓN: Usar templates Jinja2 para archivos de configuración y variables
para parámetros.

RAZONES:
- Flexibilidad: Los templates permiten generar configuraciones dinámicas.
- Separación: Separación entre código y configuración.
- Reutilización: Los mismos roles pueden usarse con diferentes configuraciones.
- Mantenibilidad: Cambios en configuración no requieren modificar código.
- Seguridad: Variables sensibles pueden manejarse mediante vaults o variables
  de entorno.

Runtime Configuration:
- Ansible Lookup: Variables leídas dinámicamente via `aws_ssm` lookup
- Application Startup: Configuración cargada al iniciar aplicaciones
- Environment Separation: Configuración aislada por entorno

5.4. VM de Ansible Dedicada
-----------------------------
DECISIÓN: Crear una VM dedicada para ejecutar Ansible.

RAZONES:
- Seguridad: Control centralizado de acceso a las otras VMs.
- Consistencia: Entorno controlado para ejecutar playbooks.
- Herramientas: Puede tener herramientas adicionales instaladas (git, etc.).
- Logs: Centraliza los logs de ejecución de playbooks.
- Acceso: Puede acceder a todas las subnets (pública y privada) para gestionar
  todos los componentes.

================================================================================
6. DIFERENCIAS ENTRE AWS Y GCP
================================================================================

6.1. Nomenclatura y Conceptos
-------------------------------
AWS usa "Security Groups" mientras GCP usa "Firewall Rules". Ambos cumplen la
misma función pero con implementaciones diferentes. Terraform abstrae estas
diferencias mediante providers específicos.

6.2. Networking
----------------
- AWS: Internet Gateway + NAT Gateway para conectividad.
- GCP: Cloud NAT integrado con Cloud Router para conectividad privada.

Ambos enfoques logran el mismo resultado: permitir que subnets privadas accedan
a internet sin exposición pública.

6.3. Base de Datos
-------------------
- AWS: RDS MySQL con subnet groups y security groups.
- GCP: Cloud SQL for MySQL con private IP y firewall rules.

Ambos servicios ofrecen características similares (backups automáticos, alta
disponibilidad, escalamiento), pero con APIs y configuraciones ligeramente
diferentes.

6.4. Compute
-------------
- AWS: EC2 instances con AMIs específicas, gestionadas por ASG (AutoScaling Group).
- GCP: Compute Engine VMs con imágenes de sistema operativo, gestionadas por
MIG (Managed Instance Group).

La diferencia principal está en cómo se referencian las imágenes, pero la
funcionalidad es equivalente.

================================================================================
7. DECISIONES DE SEGURIDAD
================================================================================

7.1. SSH Keys
-------------
DECISIÓN: Usar SSH keys en lugar de passwords para acceso manual entre VMs.

RAZONES:
- Seguridad: Más seguro que passwords.
- Automatización: Facilita la automatización con herramientas como Ansible.
- Mejores prácticas: Estándar de la industria.

7.2. GCP OS Login & AWS IAM Instance Profile
--------------------------------------------
DECISIÓN: Facilitar el acceso a los secrets almacenados en los Cloud Providers
desde la VM de Ansible.

RAZONES:
- Seguridad: No es necesario almacenar las credenciales o algunas variables
provenientes de Terraform en el código.
- Automatización: Facilita la automatización con herramientas como Ansible.
- Mejores prácticas: Estándar de la industria.

7.3. Variables Sensibles
-------------------------
DECISIÓN: En lugar de almacenarlas en archivos .tfvars, se usan las distintas
implementaciones de secrets que ofrecen los Cloud Providers (AWS SSM Parameters
Store y GCP Secret Manager). Adicionalmente, en el caso de GCP se utiliza la
metadata de la VM y del GCE template para facilitar la automatización del seteo
de variables de entorno.

Variables definidas en AWS SSM Parameters Store:
- **Backend Port**: `/${project_name}/${environment}/backend/backend_port`
- **Frontend Port**: `/${project_name}/${environment}/frontend/frontend_port`
- **Database Password**: `/${project_name}/${environment}/db_password` (SecureString)

RAZONES:
- Seguridad: Evita exponer credenciales en repositorios.
- Flexibilidad: Permite diferentes credenciales por entorno.
- Mejores prácticas: Sigue estándares de seguridad.

7.4. Encriptación
------------------
DECISIÓN: Habilitar encriptación en reposo para bases de datos.

RAZONES:
- Compliance: Requisito común en regulaciones de seguridad.
- Protección de datos: Protege datos sensibles incluso si hay acceso físico.
- Mejores prácticas: Estándar de la industria para datos sensibles.

================================================================================
8. MONITOREO Y OBSERVABILIDAD
================================================================================

8.1. CloudWatch Dashboard
-------------------------
DECISIÓN: Implementar dashboard centralizado para métricas en tiempo real.

RAZONES:
- Visibilidad unificada de EC2, RDS y ALB
- Detección temprana de problemas mediante alarmas configuradas
- Logs centralizados para troubleshooting y auditoría
- Interfaz gráfica accesible vía URL desde terraform output

8.2. Alarmas Configuradas
-------------------------
DECISIÓN: Configurar alarmas críticas dentro del AWS Free Tier.

MÉTRICAS MONITORIZADAS:
- EC2: CPU > 80% (frontend, backend)
- RDS: CPU > 80%, Storage < 1GB, Conexiones > 50  
- ALB: Errores 5XX, Response Time > 2s, Unhealthy Hosts

8.3. Notificaciones por Email
-----------------------------
DECISIÓN: Habilitar alertas opcionales vía SNS.

IMPLEMENTACIÓN:
- SNS Topic para notificaciones
- Suscripción por email configurable
- Integración con todas las alarmas de CloudWatch

8.4. Arquitectura
-----------------
La arquitectura actual implementa monitoreo comprehensivo mediante:

#### CloudWatch Logs Groups (AWS)
- **Frontend Logs**: `/aws/ec2/${project_name}-${environment}-frontend` (14 días retención)
- **Backend Logs**: `/aws/ec2/${project_name}-${environment}-backend` (14 días retención)
- **Ansible Logs**: `/aws/ec2/${project_name}-${environment}-ansible` (7 días retención)

#### Sistema de Alertas (AWS)
- **SNS Topic**: `${project_name}-monitoring-alerts-${environment}`
- **Email Notifications**: Suscripción configurable vía SNS
- **Alarmas Configuradas**: CPU, almacenamiento, conexiones, errores ALB
- **Integración Completa**: Todas las alarmas conectadas al SNS

#### Métricas Específicas Monitoreadas (AWS)
- **EC2 Instances**: CPU, memoria, disco, red para frontend/backend
- **RDS MySQL**: CPU, almacenamiento disponible, conexiones activas, IOPS
- **ALB Externo**: Request count, latency, error rate, healthy hosts
- **ALB Interno**: Request count, latency, backend response time
- **Auto Scaling Groups**: Métricas de escalabilidad automática

#### Beneficios de la Implementación
- **Centralización**: Todos los logs y métricas en CloudWatch
- **Alertas Proactivas**: Notificación automática de problemas
- **Retención Configurable**: Diferentes períodos por tipo de log
- **Free Tier Optimizado**: Todo dentro de límites gratuitos de AWS

================================================================================
9. ESCALABILIDAD
================================================================================

9.1. Escalabilidad Horizontal
-----------------------------
La arquitectura actual implementa escalabilidad horizontal mediante:

#### Auto Scaling Groups (AWS)
- **Frontend ASG**: `${project_name}-frontend-asg-${environment}`
- **Backend ASG**: `${project_name}-backend-asg-${environment}`
- **Capacidad**: desired_capacity=1, max_size configurable, min_size=1
- **Target Groups**: Conectados a ALBs para distribución de carga automática

#### Load Balancers Duales
- **ALB Externo**: Recibe tráfico de internet (HTTP/HTTPS desde 0.0.0.0/0)
- **ALB Interno**: Gestiona tráfico entre frontend y backend
- **Target Groups (AWS)**: Separados para frontend y backend
- **High Availability**: Despliegue across múltiples subnets

#### Beneficios de la Implementación
- **Distribución de Carga**: ALBs distribuyen tráfico eficientemente
- **Aislamiento de Red**: ALB interno para comunicación backend-frontend
- **Flexibilidad**: Configuración vía variables Terraform

9.2. Arquitectura de IAM
------------------------
#### Roles y Políticas Específicas
- **Instance Roles**: Roles separados para frontend, backend, ansible
- **SSM Access**: Políticas granulares para acceso a parámetros
- **Tag Management**: EC2 instances pueden modificar sus propias etiquetas
- **Instance Profiles**: Perfiles dedicados por tipo de instancia

#### Configuración de Seguridad
- **Principio de Menor Privilegio**: Acceso mínimo necesario por rol
- **Segregación de Responsabilidades**: Cada rol con permisos específicos
- **Dynamic Access**: Configuración basada en etiquetas y roles
- **Auditoría**: Todos los accesos registrados via CloudTrail

#### Beneficios de la Implementación
- **Seguridad Avanzada**: Múltiples capas de control de acceso
- **Gestión Centralizada**: Políticas IAM versionadas y reutilizables
- **Flexibilidad Operativa**: Cambios sin afectar otros componentes
- **Cumplimiento**: Mejores prácticas de seguridad de AWS

================================================================================
10. OPTIMIZACIONES Y MEJORAS FUTURAS
================================================================================

10.1. Alta disponibilidad
-------------------------
- Aumentar la capacidad: actualizando los valores *desired_capacity*, *max_size* y
*min_size* los ASGs ajustarán la capacidad automáticamente
- Desarrollar la automatización de la ejecución de los playbooks de Ansible en las
nuevas instancias que se levanten a partir del cambio de los parámetros de gestión
de los ASGs
- Tipos de instancia: si la demanda lo requiere, se pueden cambiar los tipos de
instancia en el archivo de variables

10.2. Contenedores y microservicios
-----------------------------------
Para mayor portabilidad y consistencia, se podría migrar a:
- Docker containers para las aplicaciones.
- Kubernetes (EKS en AWS, GKE en GCP) para orquestación.
- Container Registry (ECR en AWS, Container Registry en GCP) para imágenes.

10.3. Monitoreo
----------------
A futuro, se podría expandir el monitoreo actual con:
- Definición e implementación de métricas personalizadas
- Dashboards adicionales para diferentes equipos
- Integración con sistemas de alertas externos (PagerDuty, Slack)
- Tracing distribuido para microservicios
- Monitoreo de memoria en AWS, instalando el agente de CloudWatch en instancias EC2

10.4. CI/CD
-----------
Para automatización completa, se podría integrar:
- Pipeline CI/CD (GitHub Actions, Jenkins, etc.) para ejecutar Terraform
  y Ansible automáticamente.
- Testing automatizado antes del despliegue.
- Blue/Green o Canary deployments para despliegues sin downtime.

================================================================================
CONCLUSIÓN
================================================================================

Las decisiones tomadas en este diseño priorizan:
1. **Seguridad**: Arquitectura de red segura con principio de menor privilegio e IAM avanzado.
2. **Automatización**: Infraestructura como código y configuración automatizada con gestión dinámica.
3. **Modularidad**: Componentes reutilizables y mantenibles con escalabilidad horizontal implementada.
4. **Flexibilidad**: Soporte multi-cloud con configuración adaptable y centralizada.
5. **Monitoreo**: Sistema comprehensivo con alertas proactivas y logs centralizados.
6. **Mejores Prácticas**: Siguiendo estándares de la industria y optimización de costos.

Esta arquitectura proporciona una base sólida y escalable para el despliegue de
la aplicación Movie Analyst, con capacidades de producción implementadas incluyendo
Auto Scaling Groups, monitoreo avanzado, gestión dinámica de configuración, y
seguridad multicapa. La infraestructura actual está lista para evolucionar hacia
soluciones de mayor complejidad.

================================================================================
