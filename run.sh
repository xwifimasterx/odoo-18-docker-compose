#!/bin/bash

# Cargar variables desde el archivo .env
export $(grep -v '^#' .env | xargs)

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

# Verificar si se está ejecutando en macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Ejecutando en macOS. Omitiendo configuración de inotify."
else
  # Configuración del sistema
  if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then
    echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf)
  else
    echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
  fi
  sudo sysctl -p
fi

# Establecer puertos en docker-compose.yml
# Actualizar la configuración de docker-compose
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Sintaxis de sed para macOS
  sed -i '' 's/10017/'$PORT'/g' $DESTINATION/docker-compose.yml
  sed -i '' 's/20017/'$CHAT'/g' $DESTINATION/docker-compose.yml
else
  # Sintaxis de sed para Linux
  sed -i 's/10017/'$PORT'/g' $DESTINATION/docker-compose.yml
  sed -i 's/20017/'$CHAT'/g' $DESTINATION/docker-compose.yml
fi

# Establecer permisos de archivos y directorios después de la instalación
find $DESTINATION -type f -exec chmod 644 {} \;
find $DESTINATION -type d -exec chmod 755 {} \;

# Establecer permisos 777 para los directorios específicos
chmod -R 777 $DESTINATION/addons $DESTINATION/etc $DESTINATION/postgresql

# Solicitar confirmación para iniciar los contenedores
docker-compose -f $DESTINATION/docker-compose.yml up -d
# Obtener la dirección IP local
IP_ADDRESS=$(hostname -I | awk '{print $1}')
# Mostrar información de acceso
echo "Odoo iniciado en http://$IP_ADDRESS:$PORT | Contraseña maestra: minhng.info | Puerto de chat en vivo: $CHAT"
