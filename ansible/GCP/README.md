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

1. Asegúrate de que el Ansible Control Node tenga un service account de GCP configurado con los roles necesarios:
   - Compute Viewer
   - Service Account User
   - IAP-secured Tunnel User
2. El inventario utiliza IAP (Identity-Aware Proxy) para conexiones seguras
3. Comando para verificar que el inventario dinámico funciona bien:
```bash
ansible-inventory -i dynamic_inventories/inventory_gcp.yml --graph
```

Este será el inventario que se utilizará para las ejecuciones de los playbooks.

### 2. Configurar variables

Configura el inventario de Ansible con las IPs/hosts de frontend y backend (obtén las IPs con `terraform output` en `terraform/GCP`).

Las variables comunes están en `group_vars/all.yml`. Ajusta según tu entorno:
- `gcp_project_id`: Project ID de GCP
- `gcp_region`: Región de GCP
- `backend_url` / `backend_host`: URL del backend para el frontend
- `cloudsql_instance_name`: Nombre de la instancia Cloud SQL
- `db_name`, `db_user`: Configuración de base de datos
- `app_source_path`: Ruta donde están las aplicaciones (p. ej. `/tmp/devops-rampup-master`)

### 3. Variables importantes

- `gcp_project_id`: Project ID de GCP (ej: `courseproject-20201117`)
- `gcp_region`: Región de GCP (default: `us-east1`)
- `backend_ip`: IP interna del backend (obtenida de metadata de GCP)
- `frontend_ip`: IP externa del frontend (obtenida de metadata de GCP)
- `backend_port`: Puerto del backend (default: `3000`)
- `frontend_port`: Puerto del frontend (default: `3030`)
- `cloudsql_instance_name`: Nombre de la instancia Cloud SQL
- `db_name`: Nombre de la base de datos (default: `movie_db`)
- `db_user`: Usuario de la base de datos
- `gcp_secret_name`: Nombre del secreto en Secret Manager para la contraseña

## Descarga de la carpeta Ansible desde el repositorio auxiliar

Si necesitas obtener sólo la carpeta `ansible` desde un repositorio auxiliar (por ejemplo, para integrarla en este proyecto), puedes usar *sparse checkout* para clonar únicamente esa carpeta:

```bash
git init
git remote add origin -f git@github.com:eche1984/epam-final-task-2025.git   # Debes registrar una SSH Key en el repo para descargarlo
git sparse-checkout set ansible/GCP   # Puedes ejecutar 'cat .git/info/sparse-checkout' para confirmar que la carpeta se agregó correctamente
git pull origin main
```

Tras el `git pull`, la carpeta `ansible` quedará en el directorio donde ejecutaste los comandos. Si tu proyecto ya tiene una raíz distinta (p. ej. `Final-Task_2025/`), mueve o copia `ansible` al lugar correspondiente.

## Uso

**ACLARACION:** Para mantener un orden adecuado dentro del directorio _ansible/_, los playbooks que se desarrollaron para el despliegue del frontend y del backend deben mantenerse en el directorio _ansible/playbooks/_. Para ejecutarlos, debe moverse a la carpeta raíz _ansible/_ y volver a moverlo de regreso al directorio _ansible/playbooks/_. Además, se debe tener presente ejecutar primero el playbook de Ansible (ansible/roles/control_node/tasks/main.yml) para instalar las dependencias necesarias en el Control Node.

### Preparación del Control Node

```bash
cd ansible/
ansible-playbook -vv roles/control_node/tasks/main.yml -i dynamic_inventories/inventory_gcp.yml
```

### Desplegar solo frontend

```bash
ansible-playbook -vv deploy-frontend.yml -i dynamic_inventories/inventory_gcp.yml
```

### Desplegar solo backend

```bash
ansible-playbook -vv deploy-backend.yml -i dynamic_inventories/inventory_gcp.yml
```

### Desplegar todo

```bash
ansible-playbook -vv deploy-all.yml -i dynamic_inventories/inventory_gcp.yml
```

### Ejecuciones individuales

```bash
ansible-playbook -vv 01-frontend-os.yml -i dynamic_inventories/inventory_gcp.yml
ansible-playbook -vv 03-backend-db.yml -i dynamic_inventories/inventory_gcp.yml
```

### Verificar estado

```bash
ansible frontend -m shell -a "pm2 list" -i dynamic_inventories/inventory_gcp.yml
ansible backend -m shell -a "pm2 list" -i dynamic_inventories/inventory_gcp.yml
```

## Notas

- Ajusta `app_source_path` según tu estructura de directorios
- El backend crea automáticamente el esquema de base de datos si no existe
- Los seeds se ejecutan automáticamente durante el despliegue del backend
- Las conexiones SSH se realizan a través de IAP (Identity-Aware Proxy) para mayor seguridad
- Las variables de red (IPs) se obtienen dinámicamente de los metadatos del proyecto GCP
- La contraseña de la base de datos se almacena en Secret Manager de GCP
