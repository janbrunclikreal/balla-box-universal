#!/bin/bash
set -e

# Barvy pro výstup
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}>>> Zahajuji PORTABLE instalaci Balla Box v1.2...${NC}"

# 1. Instalace systémových runtime závislostí (to, co apt musí stáhnout)
echo ">>> Instaluji nezbytné systémové balíčky..."
sudo apt update
sudo apt install -y python3-gi gir1.2-gst-plugins-base-1.0 \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio ffmpeg pulseaudio pulseaudio-utils

# 2. Nasazení předkompilovaných knihoven a GStreamer pluginů
echo ">>> Kopíruji předkompilované knihovny (MPP & GStreamer plugin)..."
if [ -d "./usr/lib/aarch64-linux-gnu" ]; then
    # Kopírování MPP knihoven (včetně symlinků díky -d)
    sudo cp -rd ./usr/lib/aarch64-linux-gnu/librockchip_* /usr/lib/aarch64-linux-gnu/
    
    # Kopírování GStreamer pluginů
    sudo mkdir -p /usr/lib/aarch64-linux-gnu/gstreamer-1.0
    sudo cp -rd ./usr/lib/aarch64-linux-gnu/gstreamer-1.0/libgstrockchip* /usr/lib/aarch64-linux-gnu/gstreamer-1.0/
    
    sudo ldconfig
    echo -e "${GREEN}>>> Knihovny úspěšně nasazeny.${NC}"
else
    echo "Chyba: Složka usr/lib/aarch64-linux-gnu nenalezena!"
    exit 1
fi

# 3. Instalace Python skriptu a Systemd služeb
echo ">>> Instaluji aplikaci a konfigurace do uživatelského profilu..."
mkdir -p ~/.local/bin
cp -rd .local/bin/* ~/.local/bin/

mkdir -p ~/.config/systemd/user
cp -rd .config/systemd/user/* ~/.config/systemd/user/

# 4. Nastavení udev pravidel pro HW akceleraci
echo ">>> Nastavuji udev pravidla pro VPU..."
sudo bash -c 'cat << EOF > /etc/udev/rules.d/99-rockchip-mpp.rules
KERNEL=="mpp_service", MODE="0660", GROUP="video"
KERNEL=="system", SUBSYSTEM=="dma_heap", MODE="0660", GROUP="video"
EOF'
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG video,render,audio $USER

# 5. Aktivace služeb
echo ">>> Aktivuji Systemd služby..."
systemctl --user daemon-reload
systemctl --user enable pulseaudio.service
systemctl --user start pulseaudio.service
#systemctl --user enable ballabox.service

echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}INSTALACE DOKONČENA!${NC}"
echo -e "Nyní se prosím ODHLAŠTE a PŘIHLASTE (kvůli právům ke skupině video)."
echo -e "Poté ověřte funkčnost příkazem: gst-inspect-1.0 mpph264enc"
