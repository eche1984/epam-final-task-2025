# Terraform - AWS Deployment

Este directorio contiene los archivos de Terraform para desplegar la infraestructura de Movie Analyst en AWS.

## Estructura

```
AWS/
├── main.tf                    # Archivo principal que orquesta los módulos
├── variables.tf               # Variables del root
├── outputs.tf                 # Outputs (IPs, RDS, backend_url, monitoring)
├── terraform.tfvars.example   # Ejemplo de archivo de variables
├── env/                       # Variables por entorno (workspace)
│   ├── prod.tfvars            # Valores para entorno PROD
│   └── qa.tfvars              # Valores para entorno QA
├── .gitignore
├── IAM_policies/              # Políticas IAM personalizadas
└── modules/
    ├── vpc/                   # VPC, subnets, security groups, endpoints
    ├── ec2/                   # Instancias EC2 (frontend, backend, ansible)
    ├── rds/                   # RDS MySQL (contraseña vía SSM Parameter Store)
    ├── alb/                   # Application Load Balancer (frontend & backend)
    └── monitoring/            # Dashboard de monitoreo y alertas en CloudWatch
```

## Requisitos Previos

1. AWS CLI configurado con credenciales válidas
2. Terraform >= 1.0 instalado
3. SSH key pair generado
4. **IAM Policies**: La carpeta `IAM_policies/` contiene todas las polítcas necesarias para que el usuario de Terraform pueda realizar el despliegue de toda la infraestructura en AWS.
5. **S3 Bucket**: El backend requiere un bucket existente. En este caso, se utiliza el bucket llamado `epam-practicaltask-tfstate-bucket`.

### IAM Policies Requeridas

El proyecto requiere las siguientes políticas IAM (disponibles en `IAM_policies/`):

- **TerraformVPCOperations**: Creación y gestión de VPC, subnets, security groups
- **TerraformEC2Operations**: Gestión de instancias EC2, volúmenes, claves SSH
- **TerraformRDSOperations**: Creación y gestión de bases de datos RDS
- **TerraformELBOperations**: Configuración de Application Load Balancers
- **TerraformIAMServices**: Gestión de roles y perfiles de instancia
- **TerraformSupportingServices**: Servicios de soporte (CloudWatch, SNS, SSM)
- **TerraformEICEOperations**: Operaciones de interfaz de red
- **TerraformASGOperations**: Operaciones para gestión Auto Scaling Groups
- **TerraformMonitoringOperations**: Operaciones para gestión de monitoreo y alertas

Para aplicar las políticas a tu usuario, ir a la consola de administración de AWS para su creación y asignación al usuario correspondiente.

### Gestión de Políticas IAM

El directorio `IAM_policies/` incluye:
- **Políticas predefinidas**: Archivos .txt con las políticas IAM necesarias
- **Script de extracción**: `get_aws_iam_policies.sh` para obtener políticas nuevas y/o actualizar las existentes en AWS

Para usar el script de extracción:
```bash
cd IAM_policies
chmod +x get_aws_iam_policies.sh
./get_aws_iam_policies.sh
```

**Nota**: Configura el perfil AWS en el script antes de ejecutarlo.

## Configuración Inicial

### 1. Configurar credenciales de AWS

```bash
aws configure
```

O establecer variables de entorno:
```bash
export AWS_ACCESS_KEY_ID=your_access_key # Access Key del usuario para Terraform
export AWS_SECRET_ACCESS_KEY=your_secret_key # Secrete Access Key del usuario para Terraform
export AWS_DEFAULT_REGION=us-east-1 # Region de AWS
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

**Importante**: El archivo `terraform.tfvars.example` contiene información de ejemplo. el archivo definitivo no debe incluir ni `ssh_public_key` ni `db_password`.

Edita `env/qa.tfvars` con tus valores teniendo en cuenta que:
- **No** debes incluir `db_password`, ya que la contraseña de RDS se gestiona con AWS SSM Parameter Store (SecureString). Crea el parámetro antes del primer `apply` con el nombre: `/${project_name}/${workspace}/db_password` (p. ej. `/movie-analyst/qa/db_password`)
- **Tampoco** se debe incluir ninguna `ssh_public_key`, ya que la misma se gestiona con EC2 Key Pairs.
- Para usar valores por entorno: `terraform workspace select qa` y `terraform apply -var-file=env/qa.tfvars`

Ejemplo de comando para crear el parámetro SSM para la clave de base de datos:

```
bash
aws ssm put-parameter --name "/movie-analyst/qa/db_password" --type "SecureString" --value '<password>' --overwrite --region us-east-1
```

## Configuración de Terraform

### Backend S3

El proyecto utiliza S3 como backend para el estado de Terraform:
- **Bucket**: `epam-practicaltask-tfstate-bucket`
- **Key**: `movie-analyst/terraform.tfstate`
- **Región**: `us-east-1`
- **Encriptación**: Habilitada
- **Bloqueo**: No está configurado en esta etapa del proyecto. Se puede habilitar en el futuro para dar más robustez a la gestión del tfstate

**Nota**: Asegúrate de que el bucket exista antes de ejecutar `terraform init`.

### Versiones Requeridas

- **Terraform**: >= 1.0
- **Provider AWS**: ~> 6.0

## Uso

### Inicializar Terraform

```bash
terraform init
terraform workspace select qa # En el caso de Producción, el workspace será 'prod'
```

### Planificar el despliegue

```bash
terraform plan -var-file=env/qa.tfvars # En el caso de Producción, el tfvars será 'prod'
```

### Aplicar cambios

```bash
terraform apply -var-file=env/qa.tfvars # En el caso de Producción, el tfvars será 'prod'
```

Terraform te pedirá confirmación. Revisa el plan antes de confirmar.

### Ver outputs

Después del despliegue, puedes ver los outputs:

```bash
terraform output
```

### Destruir infraestructura

```bash
terraform destroy -var-file=env/qa.tfvars # En el caso de Producción, el tfvars será 'prod'
```

**ADVERTENCIA**: Esto eliminará toda la infraestructura creada.

## Variables Importantes

- `aws_region`: Región de AWS (default: us-east-1)
- `project_name`: Nombre del proyecto (default: movie-analyst)
- `environment`: Entorno (dev, staging, prod) - se obtiene del workspace
- `ssh_public_key`: se gestiona a través del EC2 Key Pairs
- `db_password`: No se define en Terraform; se usa el parámetro SSM con nombre: `/${project_name}/${workspace}/db_password`
- `ami_id`: AMI ID para las instancias (actualiza según tu región)
- `instance_type`: Tipo de instancia EC2 (default: t2.micro)
- `enable_monitoring`: Habilitar monitoreo con CloudWatch (default: true)
- `enable_email_notifications`: Habilitar notificaciones por email (default: false)
- `notification_email`: Email para notificaciones de alertas

### Variables de Red
- `vpc_cidr`: CIDR para la VPC
- `alb_public_subnet_cidr_1`, `alb_public_subnet_cidr_2`: Subnets públicas para ALB externo
- `frontend_subnet_cidr`: Subnet privada para frontend
- `backend_subnet_cidr_1`, `backend_subnet_cidr_2`: Subnets privadas para backend y ALB interno
- `ansible_subnet_cidr`: Subnet privada para nodo Ansible
- `db_subnet_group_cidr_1`, `db_subnet_group_cidr_2`: Subnets para RDS

## Arquitectura de Red

### Diseño de VPC

La arquitectura implementa una VPC con diseño seguro y segmentado:

#### Componentes de Red
- **VPC Principal**: Red virtual aislada con CIDR configurable
- **Subnets Públicas** (2): Para Load Balancer externo con Internet Gateway
- **Subnets Privadas** (4):
  - 1 subnet para Frontend (sin acceso público directo)
  - 2 subnets para Backend y ALB interno
  - 1 subnet para nodo Ansible (gestión)
- **Subnets de Base de Datos** (2): Para RDS en configuración Multi-AZ

#### Conectividad y Rutas
- **Internet Gateway**: Para subnets públicas (ALB externo)
- **NAT Gateway**: Para subnets privadas (acceso saliente a internet)
  - Permite descargas de paquetes y actualizaciones
  - Sin exposición pública de las instancias
- **Route Tables**: Configuradas para dirigir tráfico adecuadamente

### Reglas de Seguridad (Security Groups)

#### Load Balancer Externo
- **Entrada**: HTTP (80) y HTTPS (443) desde internet (0.0.0.0/0)
- **Salida**: Todo el tráfico hacia subnets privadas

#### Load Balancer Interno
- **Entrada**: HTTP desde frontend y backend
- **Salida**: HTTP hacia backend

#### Frontend EC2
- **Entrada**: HTTP desde ALB externo e interno
- **Entrada**: SSH desde las tres VMs (gestión)
- **Salida**: HTTP hacia backend, HTTPS hacia internet

#### Backend EC2
- **Entrada**: HTTP desde ALB interno y frontend
- **Entrada**: SSH desde las tres VMs (gestión)
- **Entrada**: MySQL (3306) desde las tres VMs (troubleshooting)
- **Salida**: MySQL hacia RDS, HTTPS hacia internet

#### Ansible EC2
- **Entrada**: SSH desde las tres VMs (gestión)
- **Salida**: SSH hacia frontend/backend, HTTPS hacia internet

#### RDS MySQL
- **Entrada**: MySQL (3306) solo desde backend EC2
- **Entrada**: MySQL (3306) desde frontend y ansible (troubleshooting)
- **Salida**: No aplica

### Principios de Seguridad

#### Principio de Menor Privilegio
- Cada componente tiene acceso mínimo necesario
- Base de datos sin acceso público directo
- Comunicación interna restringida a puertos específicos

#### Reducción de Superficie de Ataque
- Backend en subnet privada sin exposición directa
- Base de datos completamente aislada de internet
- Solo ALB externo expuesto al público

#### Aislamiento por Capas
- Frontend: Capa de presentación accesible públicamente
- Backend: Capa de lógica de negocio aislada
- Datos: Capa de persistencia completamente protegida

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
- **RDS**: CPU > 80%, Storage < 1GB, Conexiones > 50
- **ALB**: Errores 5XX, Response Time > 2s, Unhealthy Hosts

#### Métricas Específicas Monitoreadas
- **Frontend EC2**: Utilización CPU, memoria, disco, red
- **Backend EC2**: Utilización CPU, memoria, disco, red, conexiones
- **RDS MySQL**: CPU, memoria, almacenamiento disponible, conexiones activas, IOPS
- **ALB Externo**: Request count, latency, error rate 2XX/4XX/5XX, healthy hosts
- **ALB Interno**: Request count, latency, error rate, backend response time

#### Umbrales Configurados (Dentro de Free Tier)
- **CPU Utilization**: > 80% durante 5 minutos consecutivos
- **Storage Space**: < 1GB disponible en RDS
- **Database Connections**: > 50 conexiones simultáneas
- **Response Time**: > 2000ms para ALB
- **Error Rate**: > 5% de errores 5XX en ALB
- **Unhealthy Hosts**: Cualquier host unhealthy en ALB

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
- **SSM Parameter Store**: La contraseña de BD nunca se almacena en tfvars ni en el estado de Terraform
- **Workspaces**: Usa `terraform workspace new <nombre>` para crear entornos adicionales

### Decisiones de Diseño de Instancias

#### Selección de Instancias
- **Tipo**: t2.micro para todas las instancias (frontend, backend, ansible)
- **Razón**: Optimización de costos dentro del presupuesto disponible
- **Capacidad**: Suficiente para aplicaciones Node.js ligeras como Movie Analyst
- **Escalabilidad**: Fácilmente actualizable a instancias más grandes vía variables

#### Instancia de Base de Datos
- **Tipo**: db.t3.micro (MySQL)
- **Razón**: Cumple con requisitos dentro del Free Tier
- **Almacenamiento**: 20GB SSD (configurable)
- **Multi-AZ**: Configurado para alta disponibilidad

### Decisiones de Base de Datos como Servicio (DBaaS)

#### Ventajas de RDS MySQL
- **Gestión Simplificada**: AWS maneja backups, parches y mantenimiento
- **Seguridad**: Mejores prácticas implementadas por el proveedor
- **Mantenimiento Reducido**: Menor carga operativa para el equipo
- **Backups Automáticos**: Configuración con retención configurable
- **Alta Disponibilidad**: Opciones de Multi-AZ y replicación
- **Escalabilidad**: Posibilidad de escalamiento vertical y horizontal

#### Configuración de Seguridad
- **Encriptación en Reposo**: Habilitada por defecto
- **Red Privada**: Sin IP pública, accesible solo desde VPC
- **Grupos de Seguridad**: Restricción de acceso a instancias autorizadas
- **Autenticación**: IAM authentication disponible (opcional)

## Gestión de Archivos

### .gitignore

El archivo `.gitignore` está configurado para:
- Excluir todos los archivos `.tfvars` (excepto los de `env/`)
- Ignorar directorios `.terraform/`
- Ignorar archivos de estado `*.tfstate*
- Prevenir commits de información sensible e irrelevante para proyecto

### Estructura de Módulos

Cada módulo en `modules/` contiene:
- `main.tf`: Recursos principales
- `variables.tf`: Variables específicas del módulo
- `outputs.tf`: Salidas del módulo

## Troubleshooting

### Error: AMI not found
Actualiza el `ami_id` en `variables.tf` o `terraform.tfvars` con un AMI válido para tu región.

### Error: Insufficient permissions
Verifica que tu usuario de AWS tenga permisos para crear VPC, EC2, RDS, etc.

### Error: SSH key already exists
Si la clave SSH ya existe en AWS, elimínala primero o usa un nombre diferente.
