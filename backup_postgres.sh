#!/bin/bash

# Copia de seguridad de la base de datos especificada
# Creado por Tomas Castro. tomasecastro@gmail.com
# 2023-04-11
# Update 2025-02-06
# Se puede crear backup de la base de datos PostgreSQL, y los parámetros pueden ser desde dentro del script
# Como pasarlos por parámetros, de esta forma podemos integrarlo en otros script, y ejecutar en cascada.
# El archivo .env debe estar en el mismo directorio que el script.

# Se debe tener instalado el cliente de PostgreSQL. Ejemplo de instalación en Debian 11 y 12:
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

# Establecer los permisos predeterminados
umask 0022

# Función de respaldo
backup() {
    echo "Realizando respaldo de la base de datos '$DB_NAME'..."
    sleep 1
    /usr/bin/pg_dump -h $IP_SERVER -p "5432" -c -U $USER -d $DB_NAME > "$FILE.sql"

    echo "Comprimiendo el archivo de respaldo..."
    tar czvf "$FILE.tgz" "$FILE.sql"
    rm "$FILE.sql"

    # Eliminar archivos de más de 30 días
    find "$BACKUP_PATH"/* -mtime +30 -exec rm {} \;

    echo "Respaldo completado: $FILE.tgz"
}

# Función de restauración
restaurar() {
    echo "Restaurando base de datos..."

    # Solicitar confirmación para proceder con la restauración
    read -p "¿Está seguro de que desea restaurar la base de datos? (Y/N): " confirm
    if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
        echo "Restauración cancelada."
        exit 1
    fi

    # Solicitar la fecha del backup
    read -p "Introduzca la fecha y hora del backup que desea restaurar (ejemplo: 20250206_051504): " fecha
    RESTORE_FILE="$BACKUP_PATH/postgres_$fecha.tgz"

    # Verificar si el archivo de respaldo existe
    if [[ ! -f "$RESTORE_FILE" ]]; then
        echo "Archivo de respaldo no encontrado: $RESTORE_FILE"
        exit 1
    fi

    # Descomprimir el archivo de respaldo
    echo "Descomprimiendo el archivo de respaldo..."
    TAR_OUTPUT=$(tar xzvf "$RESTORE_FILE" --strip-components=1 -C "$BACKUP_PATH" 2>&1)

    # Mostrar la salida de la descompresión para depuración
    echo "Salida de la descompresión:"
    echo "$TAR_OUTPUT"

    # Limpiar el primer espacio o barra extra si es necesario
    TAR_OUTPUT=$(echo "$TAR_OUTPUT" | sed 's|^/||')

    # Limpiar el prefijo "./" si existe
    TAR_OUTPUT=$(echo "$TAR_OUTPUT" | sed 's|^\./||')

    # Extraer el nombre del archivo SQL desde la salida de tar
    SQL_FILENAME=$(echo "$TAR_OUTPUT" | grep -o '[^/]*\.sql')

    # Concatenar el directorio de backup con el nombre del archivo
    RESTORE_SQL_FILE="$BACKUP_PATH/$TAR_OUTPUT"
    RESTORE_SQL_FILE=$(echo "$RESTORE_SQL_FILE" | tr -d '[:space:]')
    echo "Ruta del archivo a restaurar: $RESTORE_SQL_FILE"

    # Verificar si el archivo extraído realmente existe
    if [ -f "$RESTORE_SQL_FILE" ]; then
        echo "Archivo a restaurar encontrado: $RESTORE_SQL_FILE"
    else
        echo "Error: el archivo SQL no se ha encontrado en $RESTORE_SQL_FILE"
        exit 1
    fi

    # Solicitar la clave de la base de datos para la restauración
    read -s -p "Introduzca la clave de la base de datos para la restauración: " db_password
    export PGPASSWORD="$db_password"

    # Restaurar la base de datos
    echo "Restaurando la base de datos '$DB_NAME' desde el archivo $RESTORE_SQL_FILE..."
    psql -h $IP_SERVER -U $USER -d $DB_NAME < "$RESTORE_SQL_FILE" > /dev/null 2>&1

    # Eliminar archivo temporal descomprimido
    rm "$RESTORE_SQL_FILE"

    echo "Restauración completada."
}

# Validar parámetros de entrada y ejecutar la acción correspondiente
if [[ "$1" == "restaurar" ]]; then
    restaurar
elif [[ -z "$1" ]]; then
    backup
else
    echo "Uso: $0 [restaurar]"
    echo "  Sin parámetros: realiza un backup."
    echo "  Con 'restaurar': restaura un backup previamente realizado."
    echo "  Si se quiere utilizar parametros al realizar el backup se deben indicar"
    exit 1
fi
