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

### 1. Configurar inventario y variables

Configura el inventario de Ansible con las IPs/hosts de frontend y backend (obtén las IPs con `terraform output` en `terraform/AWS`).

Las variables comunes están en `group_vars/all.yml`. Ajusta según tu entorno:
- `backend_url` / `backend_host`: URL del backend para el frontend
- `db_host`, `db_user`, `db_password`, `db_name`: Conexión a RDS
- `app_source_path`: Ruta donde están las aplicaciones (p. ej. `/tmp/devops-rampup-master`)

### 2. Variables importantes

- `backend_url`: URL del backend (ej: `http://10.0.2.10:3000`)
- `db_host`: Endpoint de la base de datos RDS
- `db_user`: Usuario de la base de datos
- `db_password`: Contraseña de la base de datos
- `db_name`: Nombre de la base de datos (default: `movie_db`)
- `frontend_port`: Puerto del frontend (default: `3030`)
- `backend_port`: Puerto del backend (default: `3000`)

## Uso

### Desplegar solo frontend

```bash
ansible-playbook playbooks/deploy-frontend.yml -i ~/dynamic_inventories/inventory_aws_ec2.yml
```

### Desplegar solo backend

```bash
ansible-playbook playbooks/deploy-backend.yml -i ~/dynamic_inventories/inventory_aws_ec2.yml
```

### Desplegar todo

```bash
ansible-playbook playbooks/deploy-all.yml -i ~/dynamic_inventories/inventory_aws_ec2.yml
```

### Verificar estado

```bash
ansible frontend -m shell -a "pm2 list" -i ~/dynamic_inventories/inventory_aws_ec2.yml
ansible backend -m shell -a "pm2 list" -i ~/dynamic_inventories/inventory_aws_ec2.yml
```

## Notas

- Los playbooks asumen que las aplicaciones están en `../../app/devops-rampup-master/`
- Ajusta `app_source_path` según tu estructura de directorios
- El backend crea automáticamente el esquema de base de datos si no existe
- Los seeds se ejecutan automáticamente durante el despliegue del backend
