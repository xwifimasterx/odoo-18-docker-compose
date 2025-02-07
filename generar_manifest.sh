#!/bin/bash

# Configuración de PostgreSQL
PGUSER="odoo"
PGPASSWORD="tu_contraseña"
PGDATABASE="nombre_de_tu_bd"
PGHOST="localhost"
BACKUP_DIR="./backup_odoo"
MANIFEST_FILE="$BACKUP_DIR/manifest.json"

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

# Obtener versión de Odoo
ODOO_VERSION=$(psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -t -c "SELECT latest_version FROM ir_module_module WHERE name='base';" | tr -d '[:space:]')

# Obtener lista de módulos instalados
MODULES=$(psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -t -c "SELECT name FROM ir_module_module WHERE state='installed';" | awk '{print "\""$1"\","}' | sed '$s/,$//')

# Obtener archivos en el filestore
FILESTORE_DIR="$HOME/.local/share/Odoo/filestore/$PGDATABASE"
if [ -d "$FILESTORE_DIR" ]; then
    FILES=$(find "$FILESTORE_DIR" -type f | sed 's/^/"/;s/$/",/' | sed '$s/,$//')
else
    FILES="[]"
fi

# Obtener fecha actual
BACKUP_DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Crear el archivo JSON
cat <<EOF > "$MANIFEST_FILE"
{
    "odoo_version": "$ODOO_VERSION",
    "database": "$PGDATABASE",
    "backup_date": "$BACKUP_DATE",
    "modules_installed": [
        $MODULES
    ],
    "filestore_files": [
        $FILES
    ]
}
EOF

echo "Manifest generado en: $MANIFEST_FILE"
