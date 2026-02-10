#!/bin/bash
# =================================================================
# Název: build_deb.sh
# Popis: Skript pro automatické sestavení .deb balíčku balla-box
# Autor: Jan Brunclik (janbrunclikreal)
# Verze: 1.0.1
# =================================================================

set -e

PACKAGE_NAME="balla-box-universal"
VERSION="1.0.0"
ARCH="arm64"
BUILD_DIR="build_tmp"
FINAL_NAME="${PACKAGE_NAME}_${VERSION}_${ARCH}"

echo "--- Zahajuji sestavení balíčku $FINAL_NAME ---"

# 1. Vyčištění starého sestavení
rm -rf "$BUILD_DIR"
rm -f "${FINAL_NAME}.deb"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/lib/systemd/user"

# 2. Kopírování řídicích souborů (předpokládá, že je máš v adresáři DEBIAN_src)
# Pokud je máš jinde, uprav cestu níže
if [ -d "DEBIAN" ]; then
    cp -r DEBIAN/* "$BUILD_DIR/DEBIAN/"
else
    echo "CHYBA: Adresář DEBIAN s řídicími soubory nebyl nalezen!"
    exit 1
fi

# 3. Kopírování binárek z tvé pracovní struktury do systémové
echo "Kopíruji binárky..."
cp .local/bin/*.sh "$BUILD_DIR/usr/bin/"

# 4. Kopírování systemd služeb
echo "Kopíruji systemd jednotky..."
cp .config/systemd/user/*.service "$BUILD_DIR/usr/lib/systemd/user/"

# 5. Nastavení práv (Důležité!)
echo "Nastavuji oprávnění..."
chmod -R 755 "$BUILD_DIR/usr/bin/"
chmod 644 "$BUILD_DIR/usr/lib/systemd/user/"*
chmod 755 "$BUILD_DIR/DEBIAN/postinst" "$BUILD_DIR/DEBIAN/prerm" || true

# 6. Samotné sestavení
echo "Sestavuji balíček pomocí dpkg-deb..."
dpkg-deb --build "$BUILD_DIR" "${FINAL_NAME}.deb"

# 7. Úklid
# rm -rf "$BUILD_DIR" # Volitelně můžeš nechat pro kontrolu

echo "--- Hotovo! Balíček najdeš v: ${FINAL_NAME}.deb ---"
