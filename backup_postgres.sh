#!/bin/bash

# Copia de seguridad de la base de datos especificada
# Creado por Tomas Castro. tomasecastro@gmail.com
# 2023-04-11
# Update 2025-02-06
# Se puede crear backup de la base de datos Postgrest, y los parametros pueden ser desde dentro del script 
# Como pasarlos por parametros, de esta forma podemos integrarlo en otros script, y ejecutar en cascada.
# Se quiere incluir que lea el archivo .env de la instalacion del odoo y que tome los parametros. 
# El .env debe estar en el mismo directorio que el script

# En el host local debe estar instalalo el cliente de postgres, en este caso dejo la información postgres 15 para Debian 11 y 12
# wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
# sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# sudo apt-get update
# sudo apt-get install postgresql-client-15

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
BACKUP_PATH="${4:-$DEFAULT_BACKUP_PATH}"
IP_SERVER="${5:-$DEFAULT_IP_SERVER}"

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