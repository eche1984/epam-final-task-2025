# Terraform - GCP Deployment

Este directorio contiene los archivos de Terraform para desplegar la infraestructura de Movie Analyst en GCP.

## Estructura

```
GCP/
├── main.tf                    # Archivo principal que orquesta los módulos
├── variables.tf               # Variables del módulo raíz
├── outputs.tf                # Outputs del módulo raíz
├── terraform.tfvars.example  # Ejemplo de archivo de variables
├── .gitignore                # Archivos a ignorar en git
└── modules/
    ├── vpc/                  # Módulo de VPC y networking
    ├── compute/              # Módulo de Compute Engine VMs
    └── sql/                  # Módulo de Cloud SQL MySQL
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

### 3. Habilitar APIs necesarias

```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable servicenetworking.googleapis.com
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
- `gcp_project_id`: Tu Project ID de GCP
- `ssh_public_key`: Contenido de tu clave pública SSH
- `db_password`: Contraseña segura para la base de datos
- Ajusta región y zona según prefieras

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
- `region`: Región de GCP (default: us-central1)
- `zone`: Zona de GCP (default: us-central1-a)
- `project_name`: Nombre del proyecto (default: movie-analyst)
- `environment`: Entorno (dev, staging, prod)
- `ssh_public_key`: **REQUERIDO** - Clave pública SSH
- `db_password`: **REQUERIDO** - Contraseña de la base de datos
- `machine_type`: Tipo de máquina (default: e2-micro)
- `image`: Imagen del sistema operativo (default: ubuntu-2204-lts)

## Outputs Importantes

Después del despliegue, los outputs incluyen:
- IPs públicas y privadas de las instancias
- Connection name de Cloud SQL
- IP privada de Cloud SQL
- URLs de conexión

Estos outputs pueden usarse para configurar Ansible.

## Notas

- Las instancias e2-micro son elegibles para el free tier
- Cloud SQL puede tardar varios minutos en crearse
- Los costos pueden variar según la región y tipo de instancia
- Asegúrate de tener cuota suficiente en tu proyecto de GCP

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
