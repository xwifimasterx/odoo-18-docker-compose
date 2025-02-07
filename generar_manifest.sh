#!/bin/bash

# Configuración de PostgreSQL
PGUSER="odoo"
PGPASSWORD="D2NIpV3hjYb0b9Bs"
PGDATABASE="tempo"
PGHOST="172.16.1.103"
BACKUP_DIR="./backup"
MANIFEST_FILE="$BACKUP_DIR/manifest.json"
PATH_ODOO="./odoo/etc"

# Crear el directorio de respaldo si no existe
mkdir -p "$BACKUP_DIR"

# Obtener la versión de Odoo desde el archivo de configuración
ODOO_CONF_PATH="$PATH_ODOO/odoo.conf"
ODOO_VERSION=$(grep -oP '(?<=version = ).*' "$ODOO_CONF_PATH")

# Obtener la versión de PostgreSQL
PG_VERSION=$(psql -U "$PGUSER" -h "$PGHOST" -d "$PGDATABASE" -c "SHOW server_version;" -t | tr -d '[:space:]')

# Obtener la lista de módulos instalados y sus versiones
MODULES=$(psql -U "$PGUSER" -h "$PGHOST" -d "$PGDATABASE" -t -c "
    SELECT
        module.name,
        latest_version.version
    FROM
        ir_module_module AS module
    JOIN
        ir_module_module_version AS latest_version
    ON
        module.id = latest_version.module_id
    WHERE
        module.state = 'installed';
")

# Formatear la lista de módulos en JSON
MODULES_JSON=$(echo "$MODULES" | awk '
BEGIN {
    print "{"
}
{
    printf "    \"%s\": \"%s\",\n", $1, $2
}
END {
    print "}"
}')

# Crear el archivo manifest.json
cat <<EOF > "$MANIFEST_FILE"
{
    "odoo_dump": "1",
    "db_name": "$PGDATABASE",
    "version": "$ODOO_VERSION",
    "version_info": [
        17,
        0,
        0,
        "final",
        0,
        ""
    ],
    "major_version": "17.0",
    "pg_version": "$PG_VERSION",
    "modules": $MODULES_JSON
}
EOF

echo "Archivo manifest.json generado en $MANIFEST_FILE"
