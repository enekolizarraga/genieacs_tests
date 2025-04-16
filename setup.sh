#!/bin/bash

# Este script automatiza la instalación de GenieACS siguiendo la guía oficial de instalación,
# sin instalar Node.js ya que se asume que está previamente instalado.

# Variables de configuración
GENIEACS_DIR="$HOME/genieacs"
MONGO_URL="mongodb://localhost:27017/genieacs"
REDIS_URL="redis://localhost:6379/0"

# Actualizar sistema y dependencias
echo "Actualizando el sistema y las dependencias..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl wget git build-essential libssl-dev libncurses5-dev \
    libgnomecanvas2-dev libpcap-dev libnet-dev pkg-config

# Instalación de MongoDB
echo "Instalando MongoDB..."
sudo apt-get install -y mongodb

# Verificar estado de MongoDB
sudo systemctl start mongodb
sudo systemctl enable mongodb
sudo systemctl status mongodb

# Instalación de Redis
echo "Instalando Redis..."
sudo apt-get install -y redis-server

# Verificar estado de Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
sudo systemctl status redis-server

# Clonando el repositorio de GenieACS
echo "Clonando el repositorio de GenieACS..."
git clone https://github.com/GenieACS/genieacs.git $GENIEACS_DIR

# Entrar al directorio de GenieACS
cd $GENIEACS_DIR

# Instalación de dependencias de GenieACS (sin instalar Node.js)
echo "Instalando las dependencias de GenieACS..."
npm install

# Configuración de GenieACS (modificar archivo de configuración si es necesario)
echo "Configurando GenieACS..."
cp $GENIEACS_DIR/config/default.env $GENIEACS_DIR/.env

# Modificar archivo de configuración .env (si se requiere)
# Se puede modificar automáticamente o dejarse para la configuración manual:
# sed -i 's/^MONGO_URI=.*$/MONGO_URI=$MONGO_URL/' $GENIEACS_DIR/.env
# sed -i 's/^REDIS_URI=.*$/REDIS_URI=$REDIS_URL/' $GENIEACS_DIR/.env

# Iniciar GenieACS
echo "Iniciando GenieACS..."
npm start

# Iniciar el servicio de GenieACS (si se requiere como servicio)
# sudo systemctl enable genieacs
# sudo systemctl start genieacs

echo "Instalación completada con éxito."
echo "Acceda a la interfaz de usuario en http://localhost:3000"