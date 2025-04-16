#!/bin/bash

# Variables
GENIEACS_DIR="/opt/genieacs"
GENIEACS_UI_DIR="/opt/genieacs-ui"
NODE_BIN="$(which node)"

# Función para borrar un servicio si existe
limpiar_servicio() {
  local svc=$1
  if systemctl list-unit-files | grep -q "$svc"; then
    echo "==> Limpiando servicio $svc..."
    sudo systemctl stop "$svc" 2>/dev/null
    sudo systemctl disable "$svc" 2>/dev/null
    sudo rm -f "/etc/systemd/system/$svc"
  fi
}

echo "==> Limpiando servicios anteriores (si existen)..."
limpiar_servicio "genieacs-cwmp.service"
limpiar_servicio "genieacs-nbi.service"
limpiar_servicio "genieacs-fs.service"
limpiar_servicio "genieacs-ui.service"

echo "==> Instalando dependencias necesarias..."
sudo apt update
sudo apt install -y git curl build-essential mongodb redis-server

# Verificar Node
if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js no está instalado. Instálalo manualmente (recomendada versión 16)."
  exit 1
fi

# Verificar http-server
if ! command -v http-server &>/dev/null; then
  echo "==> Instalando http-server global..."
  sudo npm install -g http-server
fi

# Clonar GenieACS
echo "==> Clonando y construyendo GenieACS..."
sudo rm -rf "$GENIEACS_DIR"
git clone https://github.com/genieacs/genieacs.git "$GENIEACS_DIR"
cd "$GENIEACS_DIR"
npm install
npm run build

# Clonar GenieACS-UI
echo "==> Clonando y construyendo GenieACS UI..."
sudo rm -rf "$GENIEACS_UI_DIR"
git clone https://github.com/genieacs/genieacs-ui.git "$GENIEACS_UI_DIR"
cd "$GENIEACS_UI_DIR"
npm install
npm run build

# Crear servicios systemd
echo "==> Creando archivos de servicio..."

# CWMP
cat <<EOF | sudo tee /etc/systemd/system/genieacs-cwmp.service > /dev/null
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
Type=simple
WorkingDirectory=$GENIEACS_DIR
ExecStart=$NODE_BIN $GENIEACS_DIR/dist/bin/genieacs-cwmp
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# NBI
cat <<EOF | sudo tee /etc/systemd/system/genieacs-nbi.service > /dev/null
[Unit]
Description=GenieACS NBI
After=network.target

[Service]
Type=simple
WorkingDirectory=$GENIEACS_DIR
ExecStart=$NODE_BIN $GENIEACS_DIR/dist/bin/genieacs-nbi
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# FS
cat <<EOF | sudo tee /etc/systemd/system/genieacs-fs.service > /dev/null
[Unit]
Description=GenieACS File Server
After=network.target

[Service]
Type=simple
WorkingDirectory=$GENIEACS_DIR
ExecStart=$NODE_BIN $GENIEACS_DIR/dist/bin/genieacs-fs
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# UI
cat <<EOF | sudo tee /etc/systemd/system/genieacs-ui.service > /dev/null
[Unit]
Description=GenieACS UI Web Interface
After=network.target

[Service]
ExecStart=/usr/bin/http-server $GENIEACS_UI_DIR/dist -p 3000 -a 0.0.0.0
Restart=always
User=nobody
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Activar servicios
echo "==> Activando servicios..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now genieacs-cwmp
sudo systemctl enable --now genieacs-nbi
sudo systemctl enable --now genieacs-fs
sudo systemctl enable --now genieacs-ui

echo ""
echo "==> Instalación completada:"
echo "    - CWMP: http://<TU-IP>:7547"
echo "    - NBI:  http://<TU-IP>:7557"
echo "    - FS:   http://<TU-IP>:7567"
echo "    - UI:   http://<TU-IP>:3000"
echo ""
