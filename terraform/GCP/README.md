# Terraform - GCP Deployment

Este directorio contiene los archivos de Terraform para desplegar la infraestructura de Movie Analyst en GCP.

## Estructura

```
GCP/
├── main.tf                    # Archivo principal que orquesta los módulos
├── variables.tf               # Variables del módulo raíz
├── outputs.tf                # Outputs del módulo raíz
├── locals.tf                 # Variables locales
├── terraform.tfvars.example  # Ejemplo de archivo de variables
├── iam.tf                    # Configuración de Service Accounts
├── .gitignore                # Archivos a ignorar en git
└── modules/
    ├── vpc/                  # Módulo de VPC y networking
    ├── compute/              # Módulo de Compute Engine VMs
    ├── sql/                  # Módulo de Cloud SQL MySQL
    ├── alb/                  # Módulo de Application Load Balancer
    └── monitoring/            # Módulo de Monitoring y alertas
```

## Requisitos Previos

1. GCP Project creado
2. Google Cloud SDK instalado y configurado
3. Terraform >= 1.0 instalado
4. SSH key pair generado
5. APIs habilitadas:
   - Compute Engine API
   - Cloud SQL Admin API
   - Cloud Resource Manager API
   - Identity and Access Management (IAM) API
   - Cloud Storage API (para backend de Terraform)
   - Cloud Monitoring API (si se habilita monitoreo)
   - Secret Manager API (para gestión de secretos)

## Configuración Inicial

### 1. Autenticarse en GCP

```bash
gcloud auth login
gcloud auth application-default login
```

### 2. Configurar proyecto

```bash
gcloud config set project YOUR_PROJECT_ID
```

### 3. Crear bucket para backend de Terraform (si no existe)

```bash
gsutil mb -l us-central1 gs://YOUR_PROJECT_ID-tfstate-bucket
```

### 4. Habilitar APIs necesarias

```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

### 4. Generar SSH key pair (si no tienes uno)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/movie-analyst-key
```

### 5. Configurar variables

Copia el archivo de ejemplo y edítalo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:
- `gcp_project_id`: **REQUERIDO** - Tu Project ID de GCP
- `region`: Región de GCP (default: `us-east1`)
- `zone`: Zona de GCP (default: `us-east1-b`)
- `ssh_public_key`: **REQUERIDO** - Contenido de tu clave pública SSH
- `db_password`: **REQUERIDO** - Contraseña segura para la base de datos
- `project_name`: Nombre del proyecto (default: `movie-analyst`)
- `environment`: Entorno (default: `qa`)
- Ajusta CIDRs y configuración de red según prefieras

## Uso

### Inicializar Terraform

```bash
terraform init
```

### Planificar el despliegue

```bash
terraform plan
```

### Aplicar cambios

```bash
terraform apply
```

Terraform te pedirá confirmación. Revisa el plan antes de confirmar.

### Ver outputs

Después del despliegue, puedes ver los outputs:

```bash
terraform output
```

### Destruir infraestructura

```bash
terraform destroy
```

**ADVERTENCIA**: Esto eliminará toda la infraestructura creada.

## Variables Importantes

- `gcp_project_id`: **REQUERIDO** - Project ID de GCP
- `region`: Región de GCP (default: us-east1)
- `zone`: Zona de GCP (default: us-east1-b)
- `project_name`: Nombre del proyecto (default: movie-analyst)
- `environment`: Entorno (dev, staging, prod)
- `ssh_public_key`: **REQUERIDO** - Clave pública SSH
- `db_password`: **REQUERIDO** - Contraseña de la base de datos
- `machine_type`: Tipo de máquina (default: e2-micro)
- `image`: Imagen del sistema operativo (default: ubuntu-2204-lts)
- `frontend_max_replicas`: Máximo de réplicas frontend (default: 2)
- `backend_max_replicas`: Máximo de réplicas backend (default: 2)
- `enable_monitoring`: Habilitar monitoreo (default: false)
- `enable_email_notifications`: Habilitar notificaciones por email (default: false)

## Configuración de Red

- `vpc_cidr`: CIDR principal de la VPC (QA: 192.168.16.0/20)
- `frontend_subnet_cidr`: Subnet frontend (QA: 192.168.16.0/24)
- `backend_subnet_cidr`: Subnet backend (QA: 192.168.17.0/24)
- `ansible_subnet_cidr`: Subnet Ansible (QA: 192.168.19.0/24)
- `ilb_private_subnet_cidr`: Subnet ILB (QA: 192.168.18.0/24)
- `db_subnet_cidr`: Subnet BD (QA: 192.168.20.0/24)

## Outputs Importantes

Después del despliegue, los outputs incluyen:
- **VPC**: ID y nombre de la VPC y subnets
- **Base de Datos**: ID, nombre, connection name e IP privada de Cloud SQL
- **Compute**: ID y nombre de la instancia Ansible
- **Load Balancer**: IPs externas, servicios de backend, health checks
- **Monitoreo**: Outputs del módulo de monitoreo (si está habilitado)

Estos outputs pueden usarse para configurar Ansible. Los valores de IPs y puertos también se almacenan en metadatos del proyecto para uso dinámico.

## Notas

- Las instancias e2-micro son elegibles para el free tier
- Cloud SQL puede tardar varios minutos en crearse
- Los costos pueden variar según la región y tipo de instancia
- Asegúrate de tener cuota suficiente en tu proyecto de GCP
- El backend de Terraform utiliza GCS para almacenamiento de estado
- Se crean automáticamente service accounts para Ansible y Compute
- Las contraseñas de BD se almacenan en Secret Manager
- Se configura Private Service Connect para conexión segura a Cloud SQL

## Arquitectura Desplegada

La infraestructura crea:
- **VPC** con múltiples subnets para diferentes componentes
- **Load Balancer Externo** para frontend con IP pública
- **Load Balancer Interno** para backend con IP privada
- **Instancias Managed Instance Groups** para alta disponibilidad
- **Cloud SQL MySQL** con alta disponibilidad y backups automáticos
- **VM Ansible** con service account y configuración para despliegues
- **Monitoreo** opcional con alertas y notificaciones

## Troubleshooting

### Error: Project not found
Verifica que el `gcp_project_id` sea correcto y que tengas acceso al proyecto.

### Error: API not enabled
Habilita las APIs necesarias usando `gcloud services enable`.

### Error: Insufficient quota
Verifica las cuotas de tu proyecto en la consola de GCP.

### Error: Permission denied
Asegúrate de tener los roles necesarios:
- Compute Admin
- Cloud SQL Admin
- Service Networking Admin
- Storage Admin (para backend de Terraform)
- IAM Service Account Admin
- Secret Manager Admin

### Error: Backend configuration
Verifica que el bucket de GCS para el backend exista y tengas permisos de acceso.

### Error: Service Account
Los service accounts se crean automáticamente. Asegúrate de tener permisos para crear IAM resources.
