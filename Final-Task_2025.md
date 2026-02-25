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
- Agentless: No requiere agentes instalados en los hosts, solo SSH.
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

6.5. Gestión de Identidad y Acceso (IAM)
---------------------------------------
DECISIÓN: Implementar enfoques específicos por plataforma para gestión de roles y
permisos.

AWS:
- IAM roles y policies estándar para EC2 instances
- Instance profiles para asignación automática de permisos
- Policies personalizadas para acceso granular a recursos

GCP:
- Service accounts dedicados (ansible-sa, compute-sa)
- Rol personalizado "ansibleExecutor" con principio de menor privilegio
- OS Login para gestión centralizada de acceso SSH
- IAP (Identity-Aware Proxy) tunnel para acceso seguro sin IPs públicas

RAZONES:
- **Principio de menor privilegio**: Cada service account tiene solo los permisos
necesarios
- **Seguridad mejorada**: IAP tunnel elimina necesidad de SSH keys estáticas
- **Auditoría**: OS Login proporciona logs detallados de accesos
- **Flexibilidad**: Roles personalizados permiten ajuste fino de permisos

6.6. Gestión de Secretos
------------------------
DECISIÓN: Utilizar servicios nativos de gestión de secretos por plataforma.

AWS:
- Parameter Store (SSM) con tipo SecureString para contraseñas
- Gestión externa de secretos (no almacenados en Terraform state)
- Encriptación automática mediante KMS

GCP:
- Secret Manager para almacenamiento y rotación de secretos
- Integración automática con Terraform para creación/gestión
- Control de acceso IAM granular por secreto

RAZONES:
- **Seguridad**: Secretos nunca almacenados en texto plano o tfvars
- **Rotación**: Capacidades nativas de rotación automática
- **Auditoría**: Logs de acceso a secretos integrados
- **Cumplimiento**: Cumple con estándares de seguridad corporativos

6.7. Backend de Terraform
-------------------------
DECISIÓN: Utilizar backends nativos de cada nube para almacenamiento de estado.

AWS:
- S3 backend con cifrado Server-Side Encryption
- Versioning para protección contra eliminación accidental
- No locking mechanism (entorno de aprendizaje/pruebas)

GCP:
- GCS backend con consistencia fuerte
- Versioning automático para historial de estados
- Integración con IAM para control de acceso

RAZONES:
- **Persistencia**: Estado almacenado de forma durable y segura
- **Colaboración**: Múltiples usuarios pueden trabajar en misma infraestructura
- **Recuperación**: Versioning permite rollback a estados anteriores
- **Seguridad**: Cifrado y control de acceso a nivel de bucket

================================================================================
7. DECISIONES DE SEGURIDAD
================================================================================

7.1. Estrategia de Acceso Remoto
--------------------------------
DECISIÓN: Implementar enfoques diferentes por plataforma para acceso seguro.

AWS:
- SSH keys tradicionales con bastión host para acceso a subnets privadas
- Security Groups específicos para restringir acceso SSH (puerto 22)
- IAM roles para acceso a recursos desde las instancias

GCP:
- IAP (Identity-Aware Proxy) tunnel para acceso SSH sin IPs públicas
- OS Login para gestión centralizada de usuarios y SSH keys
- Service accounts con roles específicos para acceso entre VMs

RAZONES:
- **AWS/GCP**: Enfoque tradicional con seguridad mediante network and traffic
segmentation
- **GCP**: Adicionalmente, se aprovechan los servicios nativos para seguridad
zero-trust
- **Consistencia**: Ambos enfoques logran acceso seguro sin exponer servicios

7.2. Gestión de Credenciales
----------------------------
DECISIÓN: Separar completamente credenciales de configuración.

AWS:
- Database password en Parameter Store (gestión manual)
- SSH keys gestionadas separadamente del Terraform state
- IAM roles asignados via instance profiles

GCP:
- Database password en Secret Manager (gestión manual)
- Service accounts con permisos específicos y limitados
- OS Login elimina necesidad de SSH keys manuales

RAZONES:
- **Seguridad**: Separación de duties entre infraestructura y credenciales
- **Rotación**: Facilita rotación automática de credenciales
- **Auditoría**: Acceso a secretos completamente auditado

7.3. Variables Sensibles y de Configuración
-------------------------------------------
DECISIÓN: Utilizar servicios nativos de secretos por plataforma.

AWS:
- SSM Parameter Store para variables de configuración y contraseñas
- Nomenclatura: /${project_name}/${environment}/service/variable
- SecureString para datos sensibles

GCP:
- Secret Manager para contraseñas de base de datos
- Project Metadata para IPs y puertos (configuración dinámica)
- Variables dinámicas obtenidas via gcloud CLI

RAZONES:
- **Seguridad**: Evita exponer credenciales en repositorios
- **Flexibilidad**: Permite diferentes credenciales por entorno
- **Automatización**: Facilita configuración dinámica en Ansible

7.4. Encriptación
------------------
DECISIÓN: Habilitar encriptación en reposo para bases de datos y comunicación.

AWS:
- RDS encryption at rest (AES-256)
- SSL/TLS para comunicación con base de datos
- KMS para gestión de claves de encriptación

GCP:
- Cloud SQL encryption at rest (automático)
- SSL/TLS para comunicación con base de datos
- CMEK (Customer Managed Encryption Keys) disponible

RAZONES:
- **Compliance**: Requisito común en regulaciones de seguridad
- **Protección de datos**: Protege datos sensibles incluso si hay acceso físico
- **Mejores prácticas**: Estándar de la industria para datos sensibles

================================================================================
8. MONITOREO Y OBSERVABILIDAD
================================================================================

8.1. Implementación de Monitoreo
--------------------------------
DECISIÓN: Implementar soluciones de monitoreo nativas por plataforma con capacidades
similares.

AWS:
- CloudWatch Logs para centralización de logs
- CloudWatch Metrics para métricas de rendimiento
- SNS para notificaciones y alertas
- CloudWatch Dashboard para visualización

GCP:
- BigQuery como sink de logs para análisis avanzado
- Cloud Monitoring para métricas y alertas
- Email notification channels para alertas
- Ops Agent para recolección de métricas en instancias

RAZONES:
- **Nativo**: Aprovechamiento de servicios integrados dentro del Free Tier de cada
plataforma
- **Análisis**: En el caso de GCP, BigQuery permite consultas SQL avanzadas sobre
logs
- **Costo-optimización**: Uso de tiers gratuitos y servicios económicos
- **Consistencia**: Métricas y alertas equivalentes en ambas plataformas

8.2. Configuración de Logs
---------------------------
DECISIÓN: Centralizar logs por componente con retención diferenciada.

AWS CloudWatch Logs Groups:
- **Frontend Logs**: `/aws/ec2/${project_name}-${environment}-frontend` (14 días)
- **Backend Logs**: `/aws/ec2/${project_name}-${environment}-backend` (14 días)
- **Ansible Logs**: `/aws/ec2/${project_name}-${environment}-ansible` (7 días)

GCP BigQuery Datasets:
- **Frontend Logs**: `${project_name}_frontend_logs_${environment}`
- **Backend Logs**: `${project_name}_backend_logs_${environment}`
- **Ansible Logs**: `${project_name}_ansible_logs_${environment}`

RAZONES:
- **Análisis**: BigQuery permite análisis complejo y queries históricos
- **Retención**: Diferentes períodos según importancia del componente
- **Costo**: Optimización de costos según volumen de logs
- **Cumplimiento**: Retención adecuada para auditorías

8.3. Sistema de Alertas
-----------------------
DECISIÓN: Implementar alertas proactivas por plataforma.

AWS:
- **SNS Topic**: `${project_name}-monitoring-alerts-${environment}`
- **Email Notifications**: Suscripción configurable vía SNS
- **Alarmas Configuradas**: CPU, almacenamiento, conexiones, errores ALB
- **Integración Completa**: Todas las alarmas conectadas al SNS

GCP:
- **Notification Channels**: Email channels configurables
- **Alert Policies**: CPU, memoria, disco, conexiones BD, errores
- **Uptime Checks**: Verificación de disponibilidad de endpoints
- **Dashboard Integración**: Métricas y alertas en dashboard unificado

RAZONES:
- **Proactividad**: Detección temprana de problemas
- **Flexibilidad**: Configuración de umbrales y notificaciones
- **Cobertura**: Monitoreo completo de infraestructura y aplicación
- **Respuesta Rápida**: Notificaciones inmediatas a equipos responsables

8.4. Métricas Específicas Monitoreadas
--------------------------------------
DECISIÓN: Monitorear métricas clave por componente.

AWS:
- **EC2 Instances**: CPU, memoria, disco, red para frontend/backend
- **RDS MySQL**: CPU, almacenamiento disponible, conexiones activas, IOPS
- **ALB Externo**: Request count, latency, error rate, healthy hosts
- **ALB Interno**: Request count, latency, backend response time
- **Auto Scaling Groups**: Métricas de escalabilidad automática

GCP:
- **Compute Engine VMs**: CPU, memoria, disco, red via Ops Agent
- **Cloud SQL MySQL**: CPU, almacenamiento, conexiones, IOPS
- **Application Load Balancer**: Request count, latency, backend response
- **Managed Instance Groups**: Métricas de auto-scaling y health checks
- **BigQuery**: Queries ejecutadas, bytes procesados, costos

RAZONES:
- **Visibilidad**: Monitoreo completo de salud del sistema
- **Performance**: Identificación de cuellos de botella
- **Capacity Planning**: Información para escalamiento proactivo
- **Troubleshooting**: Datos detallados para diagnóstico de problemas

================================================================================
9. ARQUITECTURA DE COMUNICACIÓN SEGURA
================================================================================

9.1. Configuración Dinámica de Ansible
---------------------------------------
DECISIÓN: Implementar sistema de configuración dinámica para Ansible.

GCP Implementation:
- **Project Metadata**: Almacenamiento dinámico de IPs y puertos
- **gcloud CLI Integration**: Obtención de variables en tiempo de ejecución
- **Service Account Authentication**: Sin claves estáticas

AWS Implementation:
- **SSM Parameter Store**: Variables de configuración centralizadas
- **Static Configuration**: Variables definidas en group_vars
- **IAM Role Authentication**: Acceso via instance profiles

RAZONES:
- **Flexibilidad**: Configuración adaptativa sin cambios en código
- **Seguridad**: No exponer IPs y puertos en repositorios
- **Consistencia**: Mismo código Ansible funciona en múltiples entornos
- **Mantenimiento**: Cambios en infraestructura no requieren cambios en Ansible

9.2. Acceso Seguro a Instancias
-------------------------------
DECISIÓN: Implementar métodos de acceso específicos por plataforma.

AWS:
- **Bastion Host**: VM dedicada para acceso a subnets privadas
- **SSH Keys**: Claves gestionadas manualmente o via AWS Systems Manager
- **Security Groups**: Reglas específicas para acceso SSH (puerto 22)

GCP:
- **IAP Tunnel**: Acceso SSH sin IPs públicas
- **OS Login**: Gestión centralizada de usuarios y SSH keys
- **Service Accounts**: Autenticación sin claves estáticas
- **ProxyCommand**: Configuración automática de tunneling

RAZONES:
- **Zero Trust**: GCP implementa acceso sin exposición de superficies de ataque
- **Auditoría**: OS Login proporciona logs detallados de accesos
- **Simplicidad**: IAP tunnel elimina necesidad de configuración de red compleja
- **Seguridad**: Autenticación basada en identidad en lugar de redes

================================================================================
10. GESTIÓN DE ESTADOS Y CONFIGURACIÓN
================================================================================

10.1. Terraform State Management
--------------------------------
DECISIÓN: Utilizar backends nativos con características específicas por plataforma.

AWS Backend Configuration:
- **S3 Bucket**: `epam-practicaltask-tfstate-bucket`
- **Key Structure**: `movie-analyst/terraform.tfstate`
- **Encryption**: Server-Side Encryption habilitado
- **Versioning**: Protección contra eliminación accidental
- **No Locking**: Entorno de aprendizaje/pruebas

GCP Backend Configuration:
- **GCS Bucket**: `epam-finaltask-tfstate-bucket`
- **Prefix**: `movie-analyst`
- **Consistency**: Consistencia fuerte garantizada
- **Versioning**: Automático para historial de estados
- **IAM Integration**: Control de acceso granular

RAZONES:
- **Persistencia**: Estado almacenado de forma durable y segura
- **Colaboración**: Múltiples usuarios pueden trabajar en misma infraestructura
- **Recuperación**: Versioning permite rollback a estados anteriores
- **Seguridad**: Cifrado y control de acceso a nivel de bucket

10.2. Configuración de Entornos
--------------------------------
DECISIÓN: Implementar gestión de entornos via Terraform workspaces.

Workspace Strategy:
- **qa**: Entorno de pruebas y validación
- **prod**: Entorno de producción (futuro)
- **Dynamic Naming**: Nombres de recursos incluyen workspace
- **Environment Variables**: Configuración específica por entorno

RAZONES:
- **Aislamiento**: Infraestructura completamente separada por entorno
- **Consistencia**: Mismo código para múltiples entornos
- **Flexibilidad**: Fácil adición de nuevos entornos
- **Seguridad**: Separación de datos y accesos por entorno
- **Centralización**: Todos los logs y métricas en CloudWatch
- **Alertas Proactivas**: Notificación automática de problemas
- **Retención Configurable**: Diferentes períodos por tipo de log
- **Free Tier Optimizado**: Todo dentro de límites gratuitos de AWS

================================================================================
11. ESCALABILIDAD
================================================================================

11.1. Escalabilidad Horizontal
-----------------------------
DECISIÓN: Implementar escalabilidad horizontal mediante grupos de instancias
gestionadas, de acuerdo a las particularidades de cada Provider.

AWS Implementation:
- **Auto Scaling Groups**: `${project_name}-frontend-asg-${environment}`,
  `${project_name}-backend-asg-${environment}`
- **Target Groups**: Conectados a ALBs para distribución de carga automática
- **Capacity**: desired_capacity=1, max_size configurable, min_size=1
- **Health Checks**: Integración con ALB health checks

GCP Implementation:
- **Managed Instance Groups**: Frontend y backend MIGs
- **Load Balancers**: External ALB para frontend, Internal ALB para backend
- **Autoscaling**: Basado en métricas de CPU y carga
- **Health Checks**: Integración con Cloud Monitoring

RAZONES:
- **Alta Disponibilidad**: Distribución de carga across múltiples instancias
- **Flexibilidad**: Configuración vía variables Terraform
- **Costo-optimización**: Escalamiento automático basado en demanda
- **Resiliencia**: Recuperación automática de instancias no saludables

11.2. Load Balancer Architecture
---------------------------------
DECISIÓN: Implementar arquitectura dual load balancer para aislamiento y seguridad.

AWS:
- **External ALB**: Recibe tráfico de internet (HTTP/HTTPS desde 0.0.0.0/0)
- **Internal ALB**: Gestiona tráfico entre frontend y backend
- **Target Groups**: Separados para frontend y backend
- **High Availability**: Despliegue across múltiples subnets/AZs

GCP:
- **External Application Load Balancer**: Para frontend con IP pública
- **Internal Application Load Balancer**: Para comunicación backend-frontend
- **Proxy-only Subnet**: Subnet dedicada para ILB
- **Health Checks**: Configuración específica por servicio

RAZONES:
- **Seguridad**: Aislamiento de tráfico entre frontend y backend
- **Performance**: Distribución eficiente de carga
- **Flexibilidad**: Configuración independiente por capa
- **Escalabilidad**: Soporte para escalado horizontal automático

================================================================================
12. OPTIMIZACIONES Y MEJORAS FUTURAS
================================================================================

12.1. Alta Disponibilidad
-------------------------
- **Multi-AZ/Multi-Region**: Despliegue across múltiples zonas de disponibilidad
- **Database HA**: Configuración de alta disponibilidad para base de datos
- **Cross-Region Load Balancing**: Global load balancer para disaster recovery
- **Automated Failover**: Configuración automática de failover

12.2. CI/CD Integration
------------------------
- **Automated Testing**: Testing automatizado antes del despliegue
- **Blue/Green Deployments**: Despliegues sin downtime
- **Canary Releases**: Lanzamientos graduales con monitoreo
- **Rollback Automation**: Rollback automático basado en métricas

12.3. Security Enhancements
---------------------------
- **WAF Implementation**: Web Application Firewall para protección
- **DDoS Protection**: Protección contra ataques de denegación de servicio
- **Certificate Management**: Rotación automática de certificados SSL/TLS
- **VPC Flow Logs**: Análisis detallado de tráfico de red

12.4. Cost Optimization
------------------------
- **Reserved Instances**: Compra de instancias reservadas para descuentos
- **Spot Instances**: Uso de spot instances para workloads no críticos
- **Auto-scaling Policies**: Políticas más agresivas de escalado
- **Resource Scheduling**: Apagado programado de recursos no utilizados

12.5. Monitoring Enhancements
-----------------------------
- **APM Integration**: Application Performance Monitoring
- **Distributed Tracing**: Seguimiento de requests a través de microservicios
- **Custom Metrics**: Métricas de negocio específicas
- **ML-based Anomaly Detection**: Detección de anomalías con machine learning

================================================================================
CONCLUSIÓN
================================================================================

Las decisiones tomadas en este diseño priorizan:

1. **Seguridad**: Arquitectura de red segura con principio de menor privilegio,
IAM avanzado, y acceso zero-trust en GCP
2. **Multi-Cloud Strategy**: Implementación equivalente en AWS y GCP con servicios
nativos de cada plataforma
3. **Automatización**: Infraestructura como código con Terraform y configuración
con Ansible
4. **Observabilidad**: Monitoreo comprehensivo con logs, métricas y alertas proactivas
5. **Escalabilidad**: Arquitectura horizontal con load balancers duales y auto-scaling
6. **Costo-optimización**: Uso eficiente de recursos y tiers gratuitos

La infraestructura actual está lista para evolucionar hacia soluciones de mayor
complejidad, manteniendo las mejores prácticas de seguridad y operabilidad en ambos
proveedores de nube.

================================================================================
