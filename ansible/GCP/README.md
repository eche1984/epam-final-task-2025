# Ansible Playbooks para Movie Analyst

Este directorio contiene los playbooks de Ansible para desplegar y configurar las aplicaciones frontend y backend de Movie Analyst.

## Estructura

```
ansible/
├── ansible.cfg              # Configuración de Ansible
├── group_vars/
│   └── all.yml              # Variables comunes (proyecto, puertos, paths)
├── roles/
│   ├── backend/             # Role para backend
│   │   ├── tasks/           # 01-os.yml, 02-app.yml, 03-db.yml, 04-pm2.yml, main.yml
│   │   ├── handlers/
│   │   └── templates/       # backend.env.j2, schema.sql.j2
│   ├── frontend/            # Role para frontend
│   │   ├── tasks/           # 01-os.yml, 02-app.yml, 03-pm2.yml, main.yml
│   │   ├── handlers/
│   │   └── templates/       # frontend.env.j2
│   └── control_node/        # Role para nodo de control Ansible
└── playbooks/
    ├── deploy-all.yml
    ├── deploy-backend.yml
    ├── deploy-frontend.yml
    ├── 01-backend-os.yml, 01-frontend-os.yml
    ├── 02-backend-app.yml, 02-frontend-app.yml
    ├── 03-backend-db.yml, 03-frontend-pm2.yml
    └── 04-backend-pm2.yml
```

## Requisitos Previos

1. Ansible instalado en la máquina de control (VM de Ansible)
2. Acceso SSH a las VMs de frontend y backend
3. Las aplicaciones deben estar disponibles en la ruta especificada en `app_source_path`

## Configuración

### 1. Configurar inventario

**Inventario Dinámico GCP GCE**

1. No hace falta instalar nada, porque ya viene todo instalado con la creación de la VM de Ansible.
2. Las siguientes variables de entorno tienen que estar configuradas en el .profile:
   - `AWS_ACCESS_KEY_ID` # Crear un usuario en AWS para ejecutar los comandos de CLI y tareas del amazon.aws de Ansible
   - `AWS_SECRET_ACCESS_KEY` # Luego, crear un Access Key para el usuario y almacenar en estas variables de entorno el ID y el Secret
   - `AWS_DEFAULT_REGION` # Region donde estén instanciados los recursos
3. Comando para verificar que el inventario dinámico funciona bien:
```bash
ansible-inventory -i dynamic_inventories/inventory_gcp_gce.yml --graph
```

Este será el inventario que se utilizará para las ejecuciones de los playbooks.

### 2. Configurar variables

Configura el inventario de Ansible con las IPs/hosts de frontend y backend (obtén las IPs con `terraform output` en `terraform/GCP`).

Las variables comunes están en `group_vars/all.yml`. Ajusta según tu entorno:
- `backend_url` / `backend_host`: URL del backend para el frontend
- `db_host`, `db_user`, `db_password`, `db_name`: Conexión a RDS
- `app_source_path`: Ruta donde están las aplicaciones (p. ej. `/tmp/devops-rampup-master`)

### 3. Variables importantes

- `backend_url`: URL del backend (ej: `http://10.0.2.10:3000`)
- `db_host`: Endpoint de la base de datos RDS
- `db_user`: Usuario de la base de datos
- `db_password`: Contraseña de la base de datos
- `db_name`: Nombre de la base de datos (default: `movie_db`)
- `frontend_port`: Puerto del frontend (default: `3030`)
- `backend_port`: Puerto del backend (default: `3000`)

## Uso

**ACLARACION:** Para mantener un orden adecuado dentro del directorio _ansible/_, los playbooks que se desarrollaron para el despliegue del frontend y del backend deben mantenerse en el directorio _ansible/playbooks/_. Para ejecutarlos, debe moverse a la carpeta raíz _ansible/_ y volver a moverlo de regreso al directorio _ansible/playbooks/_. Además, se debe tener presente ejecutar primero el playbook de Ansible (ansible/roles/control_node/tasks/main.yml) para instalar las dependencias necesarias en el Control Node.

### Preparación del Control Node

```bash
cd ansible/
ansible-playbook -vv roles/control_node/tasks/main.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

### Desplegar solo frontend

```bash
ansible-playbook -vv deploy-frontend.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

### Desplegar solo backend

```bash
ansible-playbook -vv deploy-backend.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

### Desplegar todo

```bash
ansible-playbook -vv deploy-all.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

### Ejecuciones individuales

```bash

ansible-playbook -vv 01-frontend-os.yml -i dynamic_inventories/inventory_aws_ec2.yml
ansible-playbook -vv 03-backend-db.yml -i dynamic_inventories/inventory_aws_ec2.yml
```

### Verificar estado

```bash
ansible frontend -m shell -a "pm2 list" -i dynamic_inventories/inventory_aws_ec2.yml
ansible backend -m shell -a "pm2 list" -i dynamic_inventories/inventory_aws_ec2.yml
```

## Notas

- Ajusta `app_source_path` según tu estructura de directorios
- El backend crea automáticamente el esquema de base de datos si no existe
- Los seeds se ejecutan automáticamente durante el despliegue del backend
