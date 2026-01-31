# Movie Analyst - Infrastructure Deployment

Este proyecto contiene la infraestructura como código (IaC) y la automatización con Ansible para desplegar la aplicación Movie Analyst en AWS, como parte de la Final Task presentada en el marco del curso de capacitación Cloud & Automation Tools LatAm Noviembre 2025

## Estructura del Proyecto

```
Final-Task_2025/
├── app/
│   └── devops-rampup-master/    # Código fuente de la aplicación
│       ├── movie-analyst-ui/    # Frontend (Node.js + Express)
│       └── movie-analyst-api/   # Backend (Node.js + Express + MySQL)
├── terraform/
│   └── AWS/                      # Infraestructura Terraform para AWS
│       ├── main.tf               # Orquestación de módulos
│       ├── variables.tf          # Variables del root
│       ├── outputs.tf            # Outputs (IPs, RDS, backend_url)
│       ├── terraform.tfvars.example
│       ├── env/                  # Variables por entorno (workspace)
│       │   └── qa.tfvars         # Valores para entorno QA
│       └── modules/
│           ├── vpc/              # VPC, subnets, security groups, endpoints
│           ├── ec2/              # Instancias EC2 (frontend, backend, ansible)
│           ├── rds/              # RDS MySQL
│           └── alb/              # Application Load Balancer (frontend)
├── ansible/                      # Playbooks y roles de Ansible
│   ├── ansible.cfg
│   ├── group_vars/
│   │   └── all.yml               # Variables comunes (proyecto, puertos, paths)
│   ├── playbooks/
│   │   ├── deploy-all.yml        # Despliega backend y frontend
│   │   ├── deploy-backend.yml
│   │   ├── deploy-frontend.yml
│   │   ├── 01-backend-os.yml     # Playbooks para ejecuciones individuales de las tareas de cada role
│   │   ├── 01-frontend-os.yml
│   │   ├── 02-backend-app.yml
│   │   ├── 02-frontend-app.yml
│   │   ├── 03-backend-db.yml
│   │   ├── 03-frontend-pm2.yml
│   │   └── 04-backend-pm2.yml
│   └── roles/
│       ├── backend/              # Role backend
│       │   ├── tasks/            # 01-os, 02-app, 03-db, 04-pm2, main.yml
│       │   ├── handlers/
│       │   └── templates/        # backend.env.j2, schema.sql.j2
│       ├── frontend/             # Role frontend
│       │   ├── tasks/            # 01-os, 02-app, 03-pm2, main.yml
│       │   ├── handlers/
│       │   └── templates/        # frontend.env.j2
│       └── control_node/         # Role para nodo de control Ansible
└── Final-Task_2025.txt           # Documento de decisiones de diseño
```

## Arquitectura (AWS)

La arquitectura desplegada incluye:

- **VPC y subnets**:
  - Subnets públicas para el ALB (acceso desde internet)
  - Subnet para Frontend (EC2)
  - Subnet para Backend (EC2, sin acceso público directo)
  - Subnet para la VM de Ansible (control y gestión)
  - Subnets para RDS (base de datos privada)

- **EC2**:
  - **Frontend**: Sirve la aplicación web (puerto 3030), registrado en el ALB
  - **Backend**: API REST (puerto 3000), accesible sólo desde frontend/ansible
  - **Ansible**: Nodo de control para ejecutar playbooks

- **Application Load Balancer (ALB)**:
  - Recibe tráfico HTTP hacia el frontend
  - Target group apuntando a las instancias frontend

- **Base de datos**:
  - **RDS MySQL**: Base de datos privada, accesible sólo desde el backend. La contraseña se gestiona con AWS SSM Parameter Store (SecureString), no en tfvars ni en el state.

## Descarga de la carpeta Ansible desde el repositorio auxiliar

Si necesitas obtener sólo la carpeta `ansible` desde un repositorio auxiliar (por ejemplo, para integrarla en este proyecto), puedes usar *sparse checkout* para clonar únicamente esa carpeta:

```bash
git init
git remote add origin -f git@github.com:eche1984/epam-final-task-2025.git   # Debes registrar una SSH Key en el repo para descargarlo
git sparse-checkout set ansible   # Puedes ejecutar 'cat .git/info/sparse-checkout' para confirmar que la carpeta se agregó correctamente
git pull origin main
```

Tras el `git pull`, la carpeta `ansible` quedará en el directorio donde ejecutaste los comandos. Si tu proyecto ya tiene una raíz distinta (p. ej. `Final-Task_2025/`), mueve o copia `ansible` al lugar correspondiente.

## Flujo de Despliegue

### 1. Desplegar Infraestructura con Terraform (AWS)

Configuración de credenciales y contraseña de BD (SSM):

- AWS CLI configurado con credenciales válidas.
- Crear el parámetro SSM con la contraseña de la base de datos (nombre según `project_name` y workspace, p. ej. `/movie-analyst/qa/db_password`).

```bash
cd terraform/AWS
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores (no incluir db_password; se usa SSM)
# Si se va a trabajar con varios entornos, se sugiere la creación de una carpeta env/,
# donde se puedan ubicar los archivos de variables por entorno
```

Uso de workspaces y archivos por entorno (opcional):

```bash
terraform workspace select qa   # o crear: terraform workspace new qa
terraform plan -var-file=env/qa.tfvars
terraform apply -var-file=env/qa.tfvars
```

O sin workspaces:

```bash
terraform init
terraform plan
terraform apply
```

### 2. Configurar Ansible

Después del despliegue de Terraform, obtén las IPs de las instancias:

```bash
cd terraform/AWS
terraform output
```

Configura el inventario de Ansible con las IPs (o nombres) de frontend, backend y, si aplica, del nodo de control. Las variables comunes están en `ansible/group_vars/all.yml`; ajusta `backend_url`, rutas de aplicación y datos de RDS según los outputs de Terraform.

### 3. Desplegar Aplicaciones con Ansible

Desde el nodo de control Ansible o tu máquina local (con acceso SSH a las VMs):

```bash
cd ansible
ansible-playbook playbooks/deploy-all.yml
```

O desplegar por separado:

```bash
# Solo backend (debe ejecutarse primero)
ansible-playbook playbooks/deploy-backend.yml

# Solo frontend
ansible-playbook playbooks/deploy-frontend.yml
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

### Terraform (AWS)
- `ssh_public_key`: Clave pública SSH para acceso a las EC2
- `project_name`: Nombre del proyecto
- `environment`: Entorno (vía workspace o variable; p. ej. dev, qa, prod)
- `db_password`: **No** se define en tfvars; se usa el parámetro SSM indicado en `main.tf`
- En `env/qa.tfvars`: región, CIDRs, tipos de instancia, RDS, puertos, etc.

### Ansible (group_vars/all.yml e inventario)
- `backend_url`: URL del backend (p. ej. `http://<backend_host>:3000`)
- `db_host` / RDS: Endpoint de la base de datos (desde `terraform output rds_address`)
- `db_user`, `db_password`, `db_name`: Conexión a MySQL
- `app_source_path`, `backend_dir`, `frontend_dir`: Rutas de la aplicación
- `backend_port`, `frontend_port`: Puertos del backend y frontend

## Documentación Adicional

- [Documento de Decisiones de Diseño](Final-Task_2025.txt) - Decisiones técnicas
- [README Terraform AWS](terraform/AWS/README.md) - Guía específica para AWS
- [README Ansible](ansible/README.md) - Guía de uso de Ansible

## Notas Importantes

1. **Orden de Despliegue**: Primero deben desplegarse los módulos de VPC, EC2 y RDS de AWS con Terraform. A continuación, el backend y el frontend con Ansible (el frontend necesita el backend en marcha). Por úlitmo, se debe desplegar el módulo ALB de AWS con Terraform. Este último paso es importante para que la creación del ALB resulte prolija.

2. **Base de Datos**: La base de datos se crea junto con la instancia RDS. El schema se crea y carga automáticamente durante el despliegue del backend (tareas/templates en el role backend).

3. **Seeds**: Los datos iniciales se ejecutan automáticamente en el despliegue del backend.

4. **PM2**: Las aplicaciones se gestionan con PM2 para reinicio automático en caso de fallo.

5. **Costos**: Tipos como t2.micro/t3.micro son elegibles para free tier; revisa límites por región.

6. **Seguridad**:
   - No incluir claves SSH ni contraseñas en el repositorio.
   - Usar archivos `.tfvars` locales (y/o `env/*.tfvars`) y mantenerlos en `.gitignore`.
   - La contraseña de RDS se gestiona con SSM Parameter Store (SecureString), no en tfvars ni en el state.

## Troubleshooting

### Terraform no puede conectarse al provider
- Comprueba credenciales de AWS (`aws sts get-caller-identity`).
- Si usas backend S3, verifica que el bucket exista y que la clave de state sea correcta.

### Ansible no puede conectarse a las VMs
- Verifica que las IPs/hosts en el inventario coincidan con `terraform output`.
- Verifica que la clave SSH sea la correcta.
- Verifica que los Security Groups permitan SSH desde tu IP o desde la subnet de Ansible.

### La aplicación no inicia
- Revisa logs con `pm2 logs <app_name>` en las VMs.
- Comprueba variables de entorno y plantillas (backend.env.j2, frontend.env.j2).
- Comprueba conectividad frontend ↔ backend y backend ↔ RDS.

## Próximos Pasos

Para producción, considera:
- Alta disponibilidad del ALB y múltiples AZ
- Auto Scaling Groups para frontend/backend
- Monitoreo y alertas (CloudWatch)
- Pipeline CI/CD
- Contenedores (Docker/Kubernetes)
- Certificados SSL/TLS (HTTPS en el ALB)
- Backups automatizados de RDS

## Soporte

Para más información:
- [Documento de Decisiones](Final-Task_2025.txt)
- READMEs en `terraform/AWS` y `ansible`
- Documentación oficial de Terraform, Ansible y AWS
