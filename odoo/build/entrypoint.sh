#!/bin/bash

set -e

# Configuración de la base de datos
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo17@2023'}}}

# Instalar paquetes de Python necesarios
pip3 install --upgrade pip
pip3 install -r /etc/odoo/requirements.txt

# Montar el bucket de MinIO utilizando s3fs
if [ -z "$MINIO_ACCESS_KEY" ] || [ -z "$MINIO_SECRET_KEY" ] || [ -z "$MINIO_URL" ] || [ -z "$MINIO_BUCKET" ]; then
    echo "Las variables de entorno MINIO_ACCESS_KEY, MINIO_SECRET_KEY, MINIO_URL y MINIO_BUCKET deben estar definidas."
    exit 1
fi

# Crear el archivo de contraseñas para s3fs
echo "$MINIO_ACCESS_KEY:$MINIO_SECRET_KEY" > /etc/odoo/.passwd-s3fs
chmod 600 /etc/odoo/.passwd-s3fs

# Crear el punto de montaje si no existe
#mkdir -p /mnt/minio
chown odoo:odoo /mnt/minio

# Montar el bucket de MinIO
#s3fs $MINIO_BUCKET /mnt/minio -o passwd_file=/root/.passwd-s3fs -o url=$MINIO_URL -o use_path_request_style -o allow_other

# Verificar si el montaje fue exitoso
#if mountpoint -q /mnt/minio; then
#    echo "El bucket de MinIO se montó correctamente en /mnt/minio."
#else
#    echo "Error al montar el bucket de MinIO."
#    exit 1
#fi

# Configuración de Odoo
DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" | cut -d " " -f3 | sed 's/["\n\r]//g')
    fi
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
