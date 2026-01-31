# Terraform - AWS Deployment

Este directorio contiene los archivos de Terraform para desplegar la infraestructura de Movie Analyst en AWS.

## Estructura

```
AWS/
├── main.tf                    # Archivo principal que orquesta los módulos
├── variables.tf               # Variables del root
├── outputs.tf                 # Outputs (IPs, RDS, backend_url)
├── terraform.tfvars.example   # Ejemplo de archivo de variables
├── env/                       # Variables por entorno (opcional)
│   └── qa.tfvars              # Valores para workspace qa
├── .gitignore
└── modules/
    ├── vpc/                   # VPC, subnets, security groups, endpoints
    ├── ec2/                   # Instancias EC2 (frontend, backend, ansible)
    ├── rds/                   # RDS MySQL (contraseña vía SSM Parameter Store)
    └── alb/                   # Application Load Balancer (frontend)
```

## Requisitos Previos

1. AWS CLI configurado con credenciales válidas
2. Terraform >= 1.0 instalado
3. SSH key pair generado

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

Copia el archivo de ejemplo y edítalo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:
- `ssh_public_key`: Contenido de tu clave pública SSH
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

## Outputs Importantes

Después del despliegue, los outputs incluyen:
- IPs públicas y privadas de las instancias
- Endpoint de RDS
- URLs de conexión

Estos outputs pueden usarse para configurar Ansible.

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
