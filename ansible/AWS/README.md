# Ansible Playbooks para Movie Analyst

Este directorio contiene los playbooks de Ansible para desplegar y configurar las aplicaciones frontend y backend de Movie Analyst.

## Estructura

```
ansible/
└── AWS/                         # Playbooks y roles de Ansible para AWS
    ├── ansible.cfg
    ├── dynamic_inventories/     # Inventarios dinámicos AWS
    ├── group_vars/
    │   └── all.yml              # Variables comunes (proyecto, puertos, paths)
    ├── playbooks/
    │   ├── deploy-all.yml       # Despliegue completo o por roles (backend y frontend)
    │   ├── deploy-backend.yml
    │   ├── deploy-frontend.yml
    │   ├── 01-backend-os.yml    # Playbooks para ejecuciones individuales de las tareas de cada role
    │   ├── 01-frontend-os.yml
    │   ├── 02-backend-app.yml
    │   ├── 02-frontend-app.yml
    │   ├── 03-backend-db.yml
    │   ├── 03-frontend-pm2.yml
    │   └── 04-backend-pm2.yml
    └── roles/
        ├── backend/             # Role backend
        │   ├── tasks/           # 01-os, 02-app, 03-db, 04-pm2, main.yml
        │   ├── handlers/
        │   └── templates/       # backend.env.j2, schema.sql.j2
        ├── frontend/            # Role frontend
        │   ├── tasks/           # 01-os, 02-app, 03-pm2, main.yml
        │   ├── handlers/
        │   └── templates/       # frontend.env.j2
        └── control_node/        # Role para nodo de control Ansible
            └── tasks/           # main.yml
```

## Requisitos Previos

1. **Infraestructura AWS desplegada** con Terraform (ver `terraform/AWS/README.md`)
2. **Ansible instalado** en la máquina de control (VM de Ansible)
3. **Acceso SSH** a las VMs de frontend y backend
4. **Parámetros SSM** creados con la configuración de la aplicación
5. **Repositorio de aplicaciones** accesible desde las VMs
6. **Python3 instalado** en todas las instancias (via user data en Terraform)
7. **PM2 instalado** en las instancias de frontend y backend para gestión de procesos Node.js

## Arquitectura y Decisiones de Diseño

### Gestión de Aplicaciones con PM2

#### ¿Por qué PM2?
- **Confiabilidad**: PM2 reinicia automáticamente las aplicaciones si fallan
- **Gestión de Procesos**: Facilita el inicio, detención y monitoreo de aplicaciones
- **Logs Centralizados**: PM2 gestiona logs de forma centralizada
- **Startup Automático**: PM2 puede configurarse para iniciar aplicaciones al arrancar el sistema
- **Estándar Industrial**: Herramienta estándar para aplicaciones Node.js en producción

#### Configuración de PM2
- **Frontend**: Proceso `movie-ui` en puerto 3030
- **Backend**: Proceso `movie-api` en puerto 3000
- **Reinicio Automático**: Habilitado para ambas aplicaciones
- **Logs**: Configurados para rotación y retención

### Scripts de Inicio (User Data)

#### Instalación Automática de Python
- **Python3 y pip**: Instalados en todas las instancias via user data de Terraform
- **Requisito de Ansible**: Ansible requiere Python en los hosts remotos
- **Automatización**: Permite que Ansible funcione inmediatamente después del despliegue
- **Consistencia**: Asegura que todas las instancias tengan herramientas necesarias desde el inicio

### Nodo de Control Ansible Dedicado

#### ¿Por qué una VM dedicada?
- **Seguridad Centralizada**: Control centralizado de acceso a las otras VMs
- **Entorno Controlado**: Entorno consistente para ejecutar playbooks
- **Herramientas Adicionales**: Puede tener git, AWS CLI, y otras herramientas instaladas
- **Logs Centralizados**: Centraliza los logs de ejecución de playbooks
- **Acceso Completo**: Puede acceder a todas las subnets (pública y privada) para gestión

#### Dependencias Instaladas
- **Paquetes del Sistema**: python3, python3-pip, software-properties-common, awscli
- **Librerías Python**: boto3, botocore para integración con AWS
- **Colección Ansible**: amazon.aws para gestión de recursos AWS

### Repositorio y Gestión de Código

#### Fuente de Aplicaciones
- **Repositorio**: https://github.com/aljoveza/devops-rampup.git
- **Clonación Automática**: Ansible clona el repositorio durante el despliegue
- **Path de Instalación**: `/tmp/devops-rampup-master` para descarga temporal
- **Path Final**: `/opt/movie-ui` y `/opt/movie-api` para producción

#### Gestión de Esquema de Base de Datos
- **Creación Automática**: El backend crea automáticamente el esquema si no existe
- **Idempotencia**: Ansible puede ejecutarse múltiples veces sin problemas
- **Versionado**: El esquema puede versionarse junto con el código de aplicación
- **Consistencia**: Asegura que el esquema sea el mismo en todos los entornos

### Implementación de Seguridad

#### Autenticación SSH Basada en Claves
- **SSH Keys**: Usadas en lugar de passwords para acceso a VMs
- **Seguridad**: Más seguro que passwords tradicionales
- **Automatización**: Facilita la automatización con Ansible
- **Estándar Industrial**: Práctica estándar en la industria

#### Gestión de Variables Sensibles
- **SSM Parameter Store**: Variables críticas almacenadas como SecureString
- **Terraform Sensitive**: Variables marcadas como sensitive en tfstate
- **Exclusión de .tfvars**: Archivos .tfvars excluidos del control de versiones
- **Principio de Menor Privilegio**: Acceso mínimo necesario para cada componente

## Configuración

### 1. Configurar inventario

**Inventario Dinámico AWS EC2**

El inventario dinámico utiliza el plugin `aws_ec2` para descubrir automáticamente las instancias EC2:

### Configuración del Inventario (`dynamic_inventories/inventory_aws_ec2.yml`)
- **Plugin**: aws_ec2
- **Región**: us-east-1
- **Filtros**: `tag:Env: qa` (solo instancias del entorno QA)
- **Grupos por etiquetas**: Basado en `tags['Role']`
- **Grupos adicionales**: `app_servers` incluye frontend y backend
- **Conexión**: Usa `private_ip_address` como `ansible_host`

### Configuración de Credenciales AWS
1. **No requiere instalación adicional** (viene con la VM de Ansible)
2. **No se requiere configuración de credenciales** : El despliegue en Terraform genera los perfiles y roles IAM específicos con permisos EC2 y SSM para que Ansible pueda acceder a la información necesaria.
3. **Verificar inventario dinámico**:
   ```bash
   ansible-inventory -i dynamic_inventories/inventory_aws_ec2.yml --graph
   ```

Este será el inventario utilizado para todas las ejecuciones de playbooks.

### 2. Configurar variables

#### Variables en SSM Parameter Store
Las variables críticas se almacenan en AWS SSM Parameter Store:
- **Backend**: `/${project_name}/${env}/backend/backend_port`
- **Frontend**: `/${project_name}/${env}/frontend/frontend_port`
- **Backend URL**: `/${project_name}/${env}/backend/backend_url`
- **Frontend URL**: `/${project_name}/${env}/frontend/frontend_url`
- **Database Password**: `/${project_name}/${env}/db_password`

#### Variables en `group_vars/all.yml`
Configura las variables comunes según tu entorno:
- **Proyecto**: `project_name: "movie-analyst"`
- **Entorno**: `env: "qa"`
- **Usuarios**: `app_user: "movie_app_user"`, `awscli_user: "ubuntu"`
- **Repositorio**: `repo_url: "https://github.com/aljoveza/devops-rampup.git"`
- **Paths**: `app_source_path: "/tmp/devops-rampup-master"`
- **Base de datos**: `rds_identifier`, `db_name`, `db_user`, `aws_ssm_parameter_name`

### 3. Configuración de Ansible

#### ansible.cfg
El archivo de configuración incluye:
- **Seguridad**: `host_key_checking = False`
- **Salida**: `stdout_callback = yaml` para mejor legibilidad
- **Plugins**: Incluye `aws_ec2` para inventarios dinámicos
- **Escalada de privilegios**: Configurada con `sudo`

#### Dependencias del Control Node
El rol `control_node` instala:
- **Paquetes del sistema**: python3, python3-pip, software-properties-common, awscli
- **Librerías Python**: boto3, botocore
- **Colección Ansible**: amazon.aws

### 4. Variables Importantes

#### Variables de Aplicación
- `backend_url`: URL del backend (ej: `internal-movie-analyst-backend-ilb-qa-<random_int_alb_id>.us-east-1.elb.amazonaws.com`)
- `frontend_url`: URL del frontend (ej: `movie-analyst-alb-qa-<random_ext_alb_id>.us-east-1.elb.amazonaws.com`)
- `backend_port`: Puerto del backend (desde SSM)
- `frontend_port`: Puerto del frontend (desde SSM)

#### Variables de Base de Datos
- `db_host`: Endpoint de RDS (desde Terraform outputs)
- `db_name`: Nombre de la base de datos (`movie_db`)
- `db_user`: Usuario de la base de datos (`movie_db_user`)
- `db_password`: Contraseña (desde SSM Parameter Store)
- `rds_identifier`: Identificador RDS (`movie-analyst-mysql-qa`)

#### Variables de Sistema
- `app_user`: Usuario de la aplicación (`movie_app_user`)
- `awscli_user`: Usuario para AWS CLI (`ubuntu`)
- `aws_region`: Región AWS (`us-east-1`)

## Uso

### Orden de Despliegue

**IMPORTANTE**: Sigue este orden para un despliegue exitoso:

1. **Preparar el Control Node** (instalar dependencias)
2. **Desplegar aplicaciones** (frontend y backend)
3. **Verificar estado** de los procesos

**ACLARACIÓN**: Los playbooks de despliegue están en `playbooks/` pero deben ejecutarse desde el directorio raíz `ansible/AWS/`, copiándolos al directorio raíz o moviéndolos y volviéndolos a su lugar de origen.

### 1. Preparación del Control Node

Instala las dependencias necesarias en la VM de Ansible:

```bash
cd ansible/AWS/
ansible-playbook -vv roles/control_node/tasks/main.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

**Este paso es obligatorio antes de cualquier despliegue**

### 2. Despliegue de Aplicaciones

#### Desplegar Frontend y Backend (Recomendado)
```bash
ansible-playbook -vv deploy-all.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

#### Desplegar solo Backend
```bash
ansible-playbook -vv playbooks/deploy-backend.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

#### Desplegar solo Frontend
```bash
ansible-playbook -vv playbooks/deploy-frontend.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

### 3. Ejecuciones Individuales (Debugging)

Para ejecutar tareas específicas de cada rol:

```bash
# Tareas de sistema operativo
ansible-playbook -vv 01-frontend-os.yml -i dynamic_inventories/inventory_aws_ec2.yml
ansible-playbook -vv 01-backend-os.yml -i dynamic_inventories/inventory_aws_ec2.yml

# Instalación de aplicaciones
ansible-playbook -vv 02-frontend-app.yml -i dynamic_inventories/inventory_aws_ec2.yml
ansible-playbook -vv 02-backend-app.yml -i dynamic_inventories/inventory_aws_ec2.yml

# Base de datos y PM2
ansible-playbook -vv 03-backend-db.yml -i dynamic_inventories/inventory_aws_ec2.yml
ansible-playbook -vv 03-frontend-pm2.yml -i dynamic_inventories/inventory_aws_ec2.yml
ansible-playbook -vv 04-backend-pm2.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

### 4. Verificación y Monitoreo

#### Verificar estado de PM2
```bash
# Estado del frontend
ansible frontend -m shell -a "pm2 list" -i dynamic_inventories/inventory_aws_ec2.yml

# Estado del backend
ansible backend -m shell -a "pm2 list" -i dynamic_inventories/inventory_aws_ec2.yml
```

#### Verificar logs de aplicaciones
```bash
# Logs del frontend
ansible frontend -m shell -a "pm2 logs movie-ui" -i dynamic_inventories/inventory_aws_ec2.yml

# Logs del backend
ansible backend -m shell -a "pm2 logs movie-api" -i dynamic_inventories/inventory_aws_ec2.yml
```

#### Verificar conectividad
```bash
# Verificar que el backend responde
ansible backend -m shell -a "curl -f http://localhost:3000/ || echo 'Backend not responding'" -i dynamic_inventories/inventory_aws_ec2.yml

# Verificar que el frontend responde
ansible frontend -m shell -a "curl -f http://localhost:3030 || echo 'Frontend not responding'" -i dynamic_inventories/inventory_aws_ec2.yml
```

## Estructura de Roles

### Backend Role (`roles/backend/`)
- **01-os.yml**: Configuración del sistema operativo, usuarios y directorios
- **02-app.yml**: Clonación del repositorio, instalación de dependencias Node.js
- **03-db.yml**: Configuración de la base de datos, creación de esquema y seeds
- **04-pm2.yml**: Configuración de PM2 para gestión de procesos
- **Templates**: 
  - `backend.env.j2`: Variables de entorno para la aplicación
  - `schema.sql.j2`: Script de creación de base de datos

#### Tareas Específicas del Backend
- **Creación de Usuario**: `movie_app_user` para ejecutar la aplicación
- **Instalación de Node.js**: Dependencias necesarias para la aplicación
- **Configuración de Base de Datos**: Conexión a RDS y creación de esquema
- **Ejecución de Seeds**: Datos de prueba insertados automáticamente
- **Configuración de PM2**: Proceso `movie-api` con reinicio automático

### Frontend Role (`roles/frontend/`)
- **01-os.yml**: Configuración del sistema operativo y usuarios
- **02-app.yml**: Clonación del repositorio y configuración de la aplicación
- **03-pm2.yml**: Configuración de PM2 para el proceso del frontend
- **Templates**: `frontend.env.j2` con variables de entorno

#### Tareas Específicas del Frontend
- **Creación de Usuario**: `movie_app_user` para ejecutar la aplicación
- **Instalación de Node.js**: Dependencias necesarias para la aplicación
- **Configuración de Variables**: URL del backend y puertos de aplicación
- **Configuración de PM2**: Proceso `movie-ui` con reinicio automático

### Control Node Role (`roles/control_node/`)
- **main.yml**: Instalación de dependencias para Ansible y AWS

#### Tareas Específicas del Control Node
- **Instalación de Python3**: Requisito para Ansible
- **Instalación de AWS CLI**: Para gestión de recursos AWS
- **Instalación de Boto3/Botocore**: Librerías Python para AWS
- **Instalación de Colección amazon.aws**: Módulos Ansible para AWS
- **Configuración de Perfil AWS**: Para acceso a recursos AWS

## Notas Importantes

- **Repositorio**: Las aplicaciones se clonan desde `https://github.com/aljoveza/devops-rampup.git`
- **Base de datos**: El backend crea automáticamente el esquema si no existe
- **Seeds**: Los datos de prueba se ejecutan durante el despliegue del backend
- **PM2**: Ambas aplicaciones usan PM2 para gestión de procesos y reinicio automático
- **Usuarios**: Las aplicaciones corren como `movie_app_user`, las tareas administrativas como `ubuntu`
- **Entorno**: Configurado para entorno QA (cambiar filtros en inventario para otros entornos)
- **Privilegios**: Se usa `become: yes` para tareas que requieren permisos de root
- **Python3**: Pre-instalado via user data en todas las instancias (requisito de Ansible)
- **Idempotencia**: Todos los playbooks pueden ejecutarse múltiples veces sin efectos adversos
- **Templates Jinja2**: Usados para configuraciones dinámicas y variables de entorno
- **Seguridad**: Variables sensibles manejadas via SSM Parameter Store

## Troubleshooting

### Problemas Comunes

#### Error: Acceso a SSM Parameter Store
```bash
# Verificar permisos del usuario IAM
aws ssm get-parameters-by-path --path "/movie-analyst/qa" --recursive --region us-east-1

# Verificar variables específicas
aws ssm get-parameter --name "/movie-analyst/qa/db_password" --with-decryption --region us-east-1
```

#### Error: Inventario dinámico no encuentra instancias
```bash
# Verificar que las instancias tengan las etiquetas correctas
aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Env,Values=qa" "Name=tag:Role,Values=frontend,backend"

# Probar inventario manualmente
ansible-inventory -i dynamic_inventories/inventory_aws_ec2.yml --list
```

#### Error: Conexión SSH fallida
```bash
# Verificar acceso SSH desde el control node
ssh -i ~/.ssh/id_rsa.pub ubuntu@<frontend_private_ip>
ssh -i ~/.ssh/id_rsa.pub ubuntu@<backend_private_ip>
```

#### Error: PM2 no inicia aplicaciones
```bash
# Verificar instalación de Node.js
ansible frontend,backend -m shell -a "node --version && npm --version" -i dynamic_inventories/inventory_aws_ec2.yml

# Verificar archivos de aplicación
ansible frontend -m shell -a "ls -la /opt/movie-ui/" -i dynamic_inventories/inventory_aws_ec2.yml
ansible backend -m shell -a "ls -la /opt/movie-api/" -i dynamic_inventories/inventory_aws_ec2.yml
```

#### Error: Base de datos no accesible
```bash
# Verificar conexión desde backend
ansible backend -m shell -a "mysql -h <rds_endpoint> -u movie_db_user -p movie_db -e 'SHOW TABLES;'" -i dynamic_inventories/inventory_aws_ec2.yml
```

### Comandos Útiles

```bash
# Limpiar caché de Ansible
ansible all -m command -a "rm -rf /tmp/*" -i dynamic_inventories/inventory_aws_ec2.yml

# Reiniciar servicios
ansible frontend -m shell -a "pm2 restart movie-ui" -i dynamic_inventories/inventory_aws_ec2.yml
ansible backend -m shell -a "pm2 restart movie-api" -i dynamic_inventories/inventory_aws_ec2.yml

# Verificar uso de recursos
ansible all -m shell -a "df -h && free -h" -i dynamic_inventories/inventory_aws_ec2.yml
```
