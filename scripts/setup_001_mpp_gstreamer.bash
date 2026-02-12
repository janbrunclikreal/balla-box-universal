#!/bin/bash
set -e  # Zastavit skript při jakékoliv chybě

echo ">>> Zahajuji instalaci závislostí..."
sudo apt update
sudo apt install -y build-essential cmake meson ninja-build git \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev pkg-config autoconf automake \
    libtool pulseaudio pulseaudio-utils netcat-openbsd ffmpeg

# Příprava adresářů
mkdir -p ~/projects/install
cd ~/projects/install

echo ">>> Kompilace Rockchip MPP..."
if [ ! -d "mpp" ]; then
    git clone https://github.com/HermanChen/mpp
fi
cd mpp
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DLINUX=ON -DARCH=aarch64 ..
make -j$(nproc)
sudo make install
cd ~/projects/install

echo ">>> Kompilace GStreamer Rockchip Pluginu..."
if [ ! -d "gst-rockchip" ]; then
    git clone https://github.com/Meonardo/gst-rockchip.git
fi
cd gst-rockchip
# Fix cesty pro DietPi/Debian aarch64
export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
meson setup build --prefix=/usr --libdir=lib/aarch64-linux-gnu
ninja -C build
sudo ninja -C build install

echo ">>> Nastavení systémových práv a udev pravidel..."
sudo ldconfig
rm -rf ~/.cache/gstreamer-1.0

# Přidání uživatele do skupin
sudo usermod -aG video,render,audio $USER

# Automatické vytvoření udev pravidel
sudo bash -c 'cat << EOF > /etc/udev/rules.d/99-rockchip-mpp.rules
KERNEL=="mpp_service", MODE="0660", GROUP="video"
KERNEL=="system", SUBSYSTEM=="dma_heap", MODE="0660", GROUP="video"
EOF'

sudo udevadm control --reload-rules
sudo udevadm trigger

echo ">>> Instalace dokončena!"
echo ">>> POZOR: Pro uplatnění práv skupin se prosím ODHLAŠTE A PŘIHLASTE."
echo ">>> Poté můžete otestovat funkčnost příkazem: gst-inspect-1.0 mpph264enc"