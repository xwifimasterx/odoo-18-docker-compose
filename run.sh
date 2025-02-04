#!/bin/bash

DESTINATION=$1
PORT=$2
CHAT=$3

# Clonar el directorio de Odoo
git clone --depth=1 https://github.com/tomasecastro/odoo-17-docker-compose $DESTINATION
rm -rf $DESTINATION/.git

# Crear el directorio de PostgreSQL
mkdir -p $DESTINATION/postgresql

# Cambiar la propiedad al usuario actual y establecer permisos restrictivos por seguridad
sudo chown -R $USER:$USER $DESTINATION
sudo chmod -R 700 $DESTINATION  # Solo el usuario tiene acceso

# Generar claves de Minio dinámicamente si no están definidas en el archivo .env
if ! grep -q "^POSTGRES_PASSWORD=" $DESTINATION/.env; then
  export POSTGRES_PASSWORD=$(openssl rand -base64 12)  # Generar una clave de acceso aleatoria
  echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> $DESTINATION/.env
else
  # Si ya existe, actualizar el valor
  sed -i "s#^POSTGRES_PASSWORD=.*#POSTGRES_PASSWORD=$(openssl rand -base64 12)#" $DESTINATION/.env
fi

if ! grep -q "^MINIO_ROOT_USER=" $DESTINATION/.env; then
  export MINIO_ROOT_USER=$(openssl rand -base64 12)  # Generar una clave de acceso aleatoria
  echo "MINIO_ROOT_USER=$MINIO_ROOT_USER" >> $DESTINATION/.env
else
  # Si ya existe, actualizar el valor
  sed -i "s#^MINIO_ROOT_USER=.*#MINIO_ROOT_USER=$(openssl rand -base64 12)#" $DESTINATION/.env
fi

if ! grep -q "^MINIO_ROOT_PASSWORD=" $DESTINATION/.env; then
  export MINIO_ROOT_PASSWORD=$(openssl rand -base64 16)  # Generar una contraseña aleatoria
  echo "MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD" >> $DESTINATION/.env
else
  # Si ya existe, actualizar el valor
  sed -i "s#^MINIO_ROOT_PASSWORD=.*#MINIO_ROOT_PASSWORD=$(openssl rand -base64 16)#" $DESTINATION/.env
fi

if ! grep -q "^MINIO_ACCESS_KEY=" $DESTINATION/.env; then
  export MINIO_ACCESS_KEY=$(openssl rand -base64 12)  # Generar una clave de acceso aleatoria
  echo "MINIO_ACCESS_KEY=$MINIO_ACCESS_KEY" >> $DESTINATION/.env
else
  # Si ya existe, actualizar el valor
  sed -i "s#^MINIO_ACCESS_KEY=.*#MINIO_ACCESS_KEY=$(openssl rand -base64 12)#" $DESTINATION/.env
fi

if ! grep -q "^MINIO_SECRET_KEY=" $DESTINATION/.env; then
  export MINIO_SECRET_KEY=$(openssl rand -base64 16)  # Generar una contraseña aleatoria
  echo "MINIO_SECRET_KEY=$MINIO_SECRET_KEY" >> $DESTINATION/.env
else
  # Si ya existe, actualizar el valor
  sed -i "s#^MINIO_SECRET_KEY=.*#MINIO_SECRET_KEY=$(openssl rand -base64 16)#" $DESTINATION/.env
fi

# Actualizar las variables ODOO_PORT y ODOO_LONGPOLLING_PORT en el archivo .env
if ! grep -q "^ODOO_PORT=" $DESTINATION/.env; then
  export ODOO_PORT=$(openssl rand -base64 16)  # Generar una contraseña aleatoria
  echo "ODOO_PORT=$PORT" >> $DESTINATION/.env
else
  # Si ya existe, actualizar el valor
  sed -i "s#^ODOO_PORT=.*#ODOO_PORT=$PORT#" $DESTINATION/.env
fi

if ! grep -q "^ODOO_LONGPOLLING_PORT=" $DESTINATION/.env; then
  export ODOO_LONGPOLLING_PORT=$(openssl rand -base64 16)  # Generar una contraseña aleatoria
  echo "ODOO_LONGPOLLING_PORT=$CHAT" >> $DESTINATION/.env
else
  # Si ya existe, actualizar el valor
  sed -i "s#^ODOO_LONGPOLLING_PORT=.*#ODOO_LONGPOLLING_PORT=$CHAT#" $DESTINATION/.env
fi

# Establecer permisos de archivos y directorios después de la instalación
find $DESTINATION -type f -exec chmod 644 {} \;
find $DESTINATION -type d -exec chmod 755 {} \;

# Establecer permisos 777 para los directorios específicos
chmod -R 777 $DESTINATION/addons $DESTINATION/etc $DESTINATION/postgresql

# Ejecutar Odoo
#docker-compose -f $DESTINATION/docker-compose.yml up -d

# Obtener la dirección IP local
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Mostrar información de acceso
echo "Odoo iniciado en http://$IP_ADDRESS:$PORT | Contraseña maestra: minhng.info | Puerto de chat en vivo: $CHAT"
echo "El minIOiniciado en http://$IP_ADDRESS:9001 | Usuario por defecto: admin, y la contraseña maestra: $MINIO_ROOT_PASSWORD"
