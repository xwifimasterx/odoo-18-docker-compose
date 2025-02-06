#!/bin/bash

# Copia de seguridad de la base de datos especificada
# Creado por Tomas Castro. tomasecastro@gmail.com
# 2023-04-11
# Update 2025-02-06

# Definir valores predeterminados
DEFAULT_USER="odoo"
DEFAULT_PGPASSWORD="8sF2sg9btKalzHM+"
DEFAULT_DB_NAME="tempo"
DEFAULT_BACKUP_PATH="./backup"
DEFAULT_IP_SERVER="172.16.1.103"

# Asignar valores de las variables, utilizando los valores predeterminados si no se proporcionan
export PGPASSWORD="${1:-$DEFAULT_PGPASSWORD}"
USER="${2:-$DEFAULT_USER}"
DB_NAME="${3:-$DEFAULT_DB_NAME}"
BACKUP_PATH="${5:-$DEFAULT_BACKUP_PATH}"
IP_SERVER="${6:-$DEFAULT_IP_SERVER}"

# Definir la fecha y el nombre del archivo de respaldo
DATE=$(date +%Y%m%d_%H%M%S)
FILE="$BACKUP_PATH/postgres_$DATE"
echo $file
# Establecer los permisos predeterminados
umask 0022

# Crear el directorio de respaldo si no existe
mkdir -p "$BACKUP_PATH"
cd $backup_path
# Realizar el respaldo de la base de datos
echo "Realizando respaldo de la base de datos '$DB_NAME'..."
sleep 1
/usr/bin/pg_dump --format custom --blobs -h $IP_SERVER -p "5432" -c -U $USER -d $DB_NAME > $FILE.sql

# Comprimir el archivo de respaldo
echo "Comprimiendo el archivo de respaldo..."
tar czvf "$FILE.tgz" "$FILE.sql"
rm "$FILE.sql"

# Eliminar archivos de más de 30 días
find "$BACKUP_PATH"/* -mtime +30 -exec rm {} \;

echo "Respaldo completado: $FILE.tgz"