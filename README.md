# Movie Analyst - Infrastructure Deployment

Este proyecto contiene la infraestructura como código (IaC) y la automatización con Ansible para desplegar la aplicación Movie Analyst en AWS, como parte de la Final Task presentada en el marco del curso de capacitación Cloud & Automation Tools LatAm Noviembre 2025

## Estructura del Proyecto

```
Final-Task_2025/
├── terraform/
│   ├── AWS/                         # Infraestructura Terraform para AWS
│   │   ├── main.tf                  # Orquestación de módulos
│   │   ├── variables.tf             # Variables del root
│   │   ├── outputs.tf               # Outputs (IPs, RDS, backend_url, monitoring)
│   │   ├── terraform.tfvars.example
│   │   ├── env/                     # Variables por entorno (workspace)
│   │   │   ├── prod.tfvars          # Valores para entorno PROD
│   │   │   └── qa.tfvars            # Valores para entorno QA
│   │   ├── IAM_policies/            # Políticas IAM personalizadas
│   │   └── modules/
│   │       ├── vpc/                 # VPC, subnets, security groups, endpoints
│   │       ├── ec2/                 # Instancias EC2 (frontend, backend, ansible)
│   │       ├── rds/                 # RDS MySQL
│   │       ├── alb/                 # Application Load Balancer (frontend & backend)
│   │       └── monitoring/          # Dashboard de monitoreo y alertas en CloudWatch
│   └── GCP/                         # Infraestructura Terraform para GCP
├── ansible/
│   ├── AWS/                         # Playbooks y roles de Ansible para AWS
│   │   ├── ansible.cfg
│   │   ├── dynamic_inventories/     # Inventarios dinámicos AWS
│   │   ├── group_vars/
│   │   │   └── all.yml              # Variables comunes (proyecto, puertos, paths)
│   │   ├── playbooks/
│   │   │   ├── deploy-all.yml       # Despliegue completo o por roles (backend y frontend)
│   │   │   ├── deploy-backend.yml
│   │   │   ├── deploy-frontend.yml
│   │   │   ├── 01-backend-os.yml    # Playbooks para ejecuciones individuales de las tareas de cada role
│   │   │   ├── 01-frontend-os.yml
│   │   │   ├── 02-backend-app.yml
│   │   │   ├── 02-frontend-app.yml
│   │   │   ├── 03-backend-db.yml
│   │   │   ├── 03-frontend-pm2.yml
│   │   │   └── 04-backend-pm2.yml
│   │   └── roles/
│   │       ├── backend/             # Role backend
│   │       │   ├── tasks/           # 01-os, 02-app, 03-db, 04-pm2, main.yml
│   │       │   ├── handlers/
│   │       │   └── templates/       # backend.env.j2, schema.sql.j2
│   │       ├── frontend/            # Role frontend
│   │       │   ├── tasks/           # 01-os, 02-app, 03-pm2, main.yml
│   │       │   ├── handlers/
│   │       │   └── templates/       # frontend.env.j2
│   │       └── control_node/        # Role para nodo de control Ansible
|   |           └── tasks/           # main.yml
│   └── GCP/                         # Playbooks y roles de Ansible para GCP
└── Final-Task_2025.txt              # Documento de decisiones de diseño
```

## Arquitectura (AWS)

La arquitectura desplegada incluye:

- **VPC y subnets**:
  - Subnets públicas para el ALB externo
  - Subnets privadas para el ALB interno
  - Subnet privada para Frontend (EC2)
  - Subnet privada para Backend (EC2), compartida con el ALB interno
  - Subnet privada para la VM de Ansible (control y gestión)
  - Subnets privadas para RDS (base de datos privada)

- **EC2**:
  - **Frontend**: Sirve la aplicación web (puerto 3030), registrado en el ALB externo. Administrado por ASG
  - **Backend**: API REST (puerto 3000), accesible sólo desde el ALB interno. Administrado por ASG
  - **Ansible**: Nodo de control para ejecutar playbooks

- **Application Load Balancer (ALB)**:
  - Externo: recibe tráfico HTTP hacia el frontend
  - Interno: recibe tráfico HTTP hacia el backend
  - Target group apuntando a las instancias frontend y backend

- **Base de datos**:
  - **RDS MySQL**: Base de datos privada, accesible sólo desde el backend. La contraseña se gestiona con AWS SSM Parameter Store (SecureString), no en tfvars ni en el state.

- **Monitoreo**:
  - **CloudWatch Dashboard**: Centraliza métricas de EC2, RDS y ALB
  - **Alarmas**: CPU, almacenamiento, conexiones, errores 5XX, tiempo de respuesta
  - **Logs Groups**: Centralización de logs de aplicaciones
  - **Notificaciones**: Alertas por email opcionales vía SNS

## Descarga de la carpeta Ansible desde el repositorio auxiliar

Si necesitas obtener sólo la carpeta `ansible` desde un repositorio auxiliar (por ejemplo, para integrarla en este proyecto), puedes usar *sparse checkout* para clonar únicamente esa carpeta. A continuación, se puede ver un ejemplo de cómo hacerlo para AWS:

```bash
git init
git remote add origin -f git@github.com:eche1984/epam-final-task-2025.git   # Debes registrar una SSH Key en el repo para descargarlo
git sparse-checkout set ansible/AWS   # También se puede reemplazar 'AWS' por 'GCP'. Puedes ejecutar 'cat .git/info/sparse-checkout' para confirmar que la carpeta se agregó correctamente
git pull origin main
```

Tras el `git pull`, la carpeta `ansible` quedará en el directorio donde ejecutaste los comandos. Si tu proyecto ya tiene una raíz distinta (p. ej. `Final-Task_2025/`), mueve o copia `ansible` al lugar correspondiente.

## Flujo de Despliegue

### 1. Desplegar Infraestructura con Terraform

- **AWS**
  Configuración de credenciales y contraseña de BD (SSM) desde máquina local:
  - AWS CLI configurado con credenciales válidas
  - Crear el parámetro SSM con la contraseña de la base de datos

**GCP**

Uso de workspaces y archivos por entorno (opcional):

```bash
terraform workspace select qa   # o crear: terraform workspace new qa
terraform plan -var-file=env/qa.tfvars
terraform apply -var-file=env/qa.tfvars
```

### Monitoreo con CloudWatch

El despliegue incluye un dashboard de monitoreo accesible vía:
- **URL del Dashboard**: Disponible en `terraform output monitoring_dashboard_url`
- **Logs Groups**: Centralizados en CloudWatch Logs
- **Alarmas**: Configuradas para métricas críticas
- **Notificaciones**: Opcionalmente habilitadas por email

### 2. Configuración de Ansible

Las variables de entorno que son requeridas para el despliegue de la aplicación vía Ansible son almacenadas en distintas herramientas de cada Cloud Provider:
- **AWS**: SSM Parameter Store
- **GCP**: GCE instance metadata

### 3. Despliegue de Aplicaciones con Ansible

**ACLARACION:** Para mantener un orden adecuado dentro del directorio _ansible/_, los playbooks que se ponen de ejemplo a continuación deben mantenerse en el directorio _ansible/playbooks/_. Para ejecutarlos, debe moverse a la carpeta raíz _ansible/_ y volver a moverlo de regreso al directorio _ansible/playbooks/_. Esto es aplicable tanto para AWS como para GCP.

Desde el nodo de control Ansible o tu máquina local (con acceso SSH a las VMs):

```bash
cd ansible
ansible-playbook -vv deploy-all.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

O desplegar por separado:

```bash
# Solo backend (debe ejecutarse primero)
ansible-playbook -vv deploy-backend.yml -i dynamic_inventories/inventory_aws_ec2.yml

# Solo frontend
ansible-playbook -vv deploy-frontend.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

## Requisitos Previos

### Para Terraform
- Terraform >= 1.0
- AWS CLI configurado
- Credenciales de acceso a AWS
- Backend remoto (S3) configurado en `main.tf` para el state (opcional; se puede cambiar a local)
- Parámetro SSM con la contraseña de la base de datos (SecureString)

### Para Ansible
- Ansible >= 2.9
- Python 3 en todas las VMs
- Acceso SSH a las VMs (clave SSH configurada en Terraform)
- Aplicaciones disponibles en la ruta indicada en `group_vars/all.yml` (`app_source_path`)

## Variables Importantes

### Terraform 
- **AWS**
  - `project_name`: Nombre del proyecto
  - `environment`: Entorno (vía workspace o variable; p. ej. dev, qa, prod)
  - `db_password`: **No** se define en tfvars; se usa el parámetro SSM indicado en `main.tf`
  - `enable_monitoring`: Habilitar monitoreo con CloudWatch (default: true)
  - `enable_email_notifications`: Habilitar notificaciones por email (default: false)
  - `notification_email`: Email para alertas de monitoreo
  - `Configuraciones básicas`: región, CIDRs, tipos de instancia (EC2 y RDS), puertos, etc.

**GCP**

### Ansible (group_vars/all.yml e inventario)
- `backend_url`, `frontend_url`: URL de los ALB (interno y externo)
- `db_host` / RDS (AWS): Endpoint de la base de datos
- `db_user`, `db_password`, `db_name`: Conexión a MySQL
- `app_source_path`, `backend_dir`, `frontend_dir`: Rutas de la aplicación
- `backend_port`, `frontend_port`: Puertos del backend y frontend

## Documentación Adicional

- [Documento de Decisiones de Diseño](Final-Task_2025.txt) - Decisiones técnicas
- [README Terraform AWS](terraform/AWS/README.md) - Guía específica para despliegue de AWS en Terraform
- [README Terraform GCP](terraform/GCP/README.md) - Guía específica para despliegue de GCP en Terraform
- [README Ansible AWS](ansible/AWS/README.md) - Guía de uso de Ansible para despliegue de aplicaciones en AWS
- [README Ansible GCP](ansible/GCP/README.md) - Guía de uso de Ansible para despliegue de aplicaciones en GCP

## Notas Importantes

1. **Orden de Despliegue**: Primero deben desplegarse los módulos de VPC, EC2, RDS y ALB de AWS con Terraform. Tener en cuenta que es mandatorio que la VM del frontend debe estar arriba para que el despliegue del módulo de ALB finalice OK. Una vez que se hayan desplegado todos los recursos en AWS con Terraform, se deben ejecutar los playbooks del *control_node*, del *backend* y del *frontend* con Ansible, en ese orden (el frontend necesita el backend en marcha).

2. **Base de Datos**: La base de datos se crea junto con la instancia RDS. El schema se crea y carga automáticamente durante el despliegue del backend (tareas/templates en el role backend).

3. **Seeds**: Los datos iniciales se ejecutan automáticamente en el despliegue del backend.

4. **PM2**: Las aplicaciones se gestionan con PM2 para reinicio automático en caso de fallo.

5. **Costos**
  - AWS: Tipos como t2.micro/t3.micro/t3.small/db.t3.micro son elegibles para free tier; revisa límites por región.
  - GCP: La opciones elegibles para el free tier son e2-micro (GCE) y db-f1-micro (Cloud SQL).

6. **Seguridad**
   - No incluir claves SSH ni contraseñas en el repositorio.
   - Es recomendable agregar en el ~/.ssh/authorized_hosts de todas las VMs (incluida la de ansible) la clave pública del usuario de SO con el que se vayan a ejecutar los playbooks desde el Control Node. En el caso de AWS, se utiliza el mismo Key Pair para todas las instancias.
   - Usar archivos `.tfvars` locales (y/o `env/*.tfvars`) y mantenerlos en `.gitignore`.
   - La contraseña de base de datos se almacena encriptada como secret de acuerdo a cómo esté implementado en cada Provider (AWS SSM Parameter Store y GCP Secret Manager), no en tfvars ni en el state.

## Troubleshooting

### Terraform no puede conectarse al provider
- **AWS**
  - Comprueba que AWS CLI esté configurado correctamente (`aws sts get-caller-identity`).
  - Si usas backend S3, verifica que el bucket exista y que la clave de state sea correcta.

### Ansible no puede conectarse a las VMs
- Verifica que las IPs/hosts en el inventario coincidan con `terraform output`.
- Verifica que la clave SSH sea la correcta.
- Verifica que los Security Groups permitan SSH desde tu IP o desde la subnet de Ansible.

### La aplicación no inicia
- Revisa logs con `pm2 logs <app_name>` en las VMs.
- Comprueba variables de entorno y plantillas (backend.env.j2, frontend.env.j2).
- Comprueba conectividad frontend ↔ backend y backend ↔ RDS.


## Monitoreo y Observabilidad

**Monitoreo desplegado dentro del AWS Free Tier**

  1. CloudWatch Dashboard
  - **Métricas en tiempo real** de EC2, RDS y ALB
  - **Visualización centralizada** del rendimiento del sistema
  - **Acceso directo** vía URL desde `terraform output`

  2. Alarmas Configuradas
  - **EC2**: CPU > 80% (frontend, backend)
  - **RDS**: CPU > 80%, Storage < 1GB, Conexiones > 50
  - **ALB**: Errores 5XX, Response Time > 2s, Unhealthy Hosts

  3. Logs Centralizados
  - **Frontend**: `/aws/ec2/project-env-frontend` (14 días)
  - **Backend**: `/aws/ec2/project-env-backend` (14 días)
  - **Ansible**: `/aws/ec2/project-env-ansible` (7 días)

**Monitoreo desplegado dentro del GCP Free Tier**

### Notificaciones (Opcional)
```hcl
enable_email_notifications = true
notification_email         = "your-email@example.com"
```

## Próximos Pasos

Para producción, considera:
- Alta disponibilidad del ALB y múltiples AZ
- Auto Scaling Groups para frontend/backend
- **Monitoreo avanzado**: Métricas personalizadas, dashboards adicionales
- Pipeline CI/CD: Jenkins/GitHub Actions
- Contenedores (Docker/Kubernetes)
- Certificados SSL/TLS (HTTPS en el ALB)
- Backups automatizados de DB

## Soporte

Para más información:
- [Documento de Decisiones](Final-Task_2025.txt)
- READMEs en `terraform/AWS`, `ansible/AWS`, `terraform/GCP` y `ansible/GCP`
- Documentación oficial de Terraform, Ansible y AWS
