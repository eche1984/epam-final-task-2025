# Terraform - AWS Deployment

Este directorio contiene los archivos de Terraform para desplegar la infraestructura de Movie Analyst en AWS.

## Estructura

```
AWS/
├── main.tf                    # Archivo principal que orquesta los módulos
├── variables.tf               # Variables del root
├── outputs.tf                 # Outputs (IPs, RDS, backend_url, monitoring)
├── terraform.tfvars.example   # Ejemplo de archivo de variables
├── env/                       # Variables por entorno (opcional)
│   └── qa.tfvars              # Valores para workspace qa
├── .gitignore
└── modules/
    ├── vpc/                   # VPC, subnets, security groups, endpoints
    ├── ec2/                   # Instancias EC2 (frontend, backend, ansible)
    ├── rds/                   # RDS MySQL (contraseña vía SSM Parameter Store)
    ├── alb/                   # Application Load Balancer (frontend)
    └── monitoring/            # Dashboard de monitoreo y alertas en CloudWatch
```

## Requisitos Previos

1. AWS CLI configurado con credenciales válidas
2. Terraform >= 1.0 instalado
3. SSH key pair generado
4. **IAM Policies**: Asegúrate de tener las políticas necesarias (ver `IAM_policies/`)

### IAM Policies Requeridas

El proyecto requiere las siguientes políticas IAM (disponibles en `IAM_policies/`):

- **TerraformVPCOperations**: Creación y gestión de VPC, subnets, security groups
- **TerraformEC2Operations**: Gestión de instancias EC2, volúmenes, claves SSH
- **TerraformRDSOperations**: Creación y gestión de bases de datos RDS
- **TerraformELBOperations**: Configuración de Application Load Balancers
- **TerraformIAMServices**: Gestión de roles y perfiles de instancia
- **TerraformSupportingServices**: Servicios de soporte (CloudWatch, SNS, SSM)
- **TerraformEICEOperations**: Operaciones de interfaz de red

Para aplicar las políticas a tu usuario, ir a la consola de administración de AWS para su creación y asignación al usuario correspondiente.

## Configuración Inicial

### 1. Configurar credenciales de AWS

```bash
aws configure
```

O establecer variables de entorno:
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

### 2. Generar SSH key pair (si no tienes uno)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/movie-analyst-key
```

### 3. Configurar variables

Copia el archivo de ejemplo y edítalo, poniéndole el nombre que corresponda según el Terraform Workspace con el que estés trabajando:

```bash
cp terraform.tfvars.example env/qa.tfvars
```

Edita `env/qa.tfvars` con tus valores:
- `ssh_public_key`: Contenido de tu clave pública SSH, **solamente si es estrictamente necesario**.
- **No** incluyas `db_password` en tfvars: la contraseña de RDS se gestiona con AWS SSM Parameter Store (SecureString). Crea el parámetro antes del primer `apply` (nombre según `project_name` y workspace, p. ej. `/movie-analyst/qa/db_password`).
- Para usar valores por entorno: `terraform workspace select qa` y `terraform apply -var-file=env/qa.tfvars`

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

- `aws_region`: Región de AWS (default: us-east-1)
- `project_name`: Nombre del proyecto (default: movie-analyst)
- `environment`: Entorno (dev, staging, prod)
- `ssh_public_key`: **REQUERIDO** - Clave pública SSH
- `db_password`: No se define en Terraform; se usa el parámetro SSM (SecureString) indicado en `main.tf`
- `ami_id`: AMI ID para las instancias (actualiza según tu región)
- `instance_type`: Tipo de instancia EC2 (default: t2.micro)
- `enable_monitoring`: Habilitar monitoreo con CloudWatch (default: true)
- `enable_email_notifications`: Habilitar notificaciones por email (default: false)
- `notification_email`: Email para notificaciones de alertas

## Outputs Importantes

Después del despliegue, los outputs incluyen:
- IPs públicas y privadas de las instancias
- Endpoint de RDS
- URLs de conexión
- Grupos de logs de CloudWatch para monitoreo
- Alarmas de CloudWatch configuradas
- SNS Topic ARN para notificaciones (si está habilitado)

Estos outputs pueden usarse para configurar Ansible.

## Monitoreo con CloudWatch

El módulo de monitoreo incluye:

### Logs Groups
- `/aws/ec2/project-name-env-frontend` - Logs del frontend (14 días retención)
- `/aws/ec2/project-name-env-backend` - Logs del backend (14 días retención)  
- `/aws/ec2/project-name-env-ansible` - Logs de ansible (7 días retención)

### Alarmas Configuradas
- **EC2**: CPU > 80% (frontend, backend)
- **RDS**: CPU > 80%, Storage < 2GB, Conexiones > 50
- **ALB**: Errores 5XX, Response Time > 5s, Unhealthy Hosts

### Notificaciones (Opcional)
Para habilitar notificaciones por email, agregar o editar en el archivo de variables dentro de la carpeta env/:
```hcl
enable_email_notifications = true
notification_email         = "your-email@example.com"
```

### Costos de Monitoreo
Todos los servicios de monitoreo están dentro del AWS Free Tier:
- CloudWatch Logs: 5GB ingestión, 5GB almacenamiento
- CloudWatch Alarms: 10 alarmas métricas
- SNS: 1 millón de publicaciones
- Datos de métricas: 10 métricas personalizadas

## Notas

- Asegúrate de actualizar el `ami_id` según tu región de AWS
- Las instancias t2.micro son elegibles para el free tier
- RDS puede tardar varios minutos en crearse
- Los costos pueden variar según la región y tipo de instancia

## Troubleshooting

### Error: AMI not found
Actualiza el `ami_id` en `variables.tf` o `terraform.tfvars` con un AMI válido para tu región.

### Error: Insufficient permissions
Verifica que tu usuario de AWS tenga permisos para crear VPC, EC2, RDS, etc.

### Error: SSH key already exists
Si la clave SSH ya existe en AWS, elimínala primero o usa un nombre diferente.
