# **Balla Box Universal v1.2 (Python Edition) - Pulseaudio (DietPi) na Orange Pi 5 Ultra**

Profesionální řešení pro streamování a záznam obrazovky, kamery a zvuku na platformě **Orange Pi 5 Ultra**.
Systém využívá hardwarovou akceleraci Rockchip MPP (Media Process Platform) pro minimální zátěž CPU a zvukový systém PulseAudio.

## ** Hlavní funkce**

** Hardware Encoding:** Využití `mpph264enc` pro plynulé Full HD nahrávání.  
** PiP (Picture-in-Picture):** Webkamera v rohu obrazovky s korektním škálováním (320x240).  
** Audio Mixing:** Smíchání mikrofonu (`Rode NT-USB`) a systémového zvuku s nezávislou hlasitostí. 
** Audio system :** PulseAudio.
** Auto-Fix:** Automatická oprava metadat MKV souborů po ukončení záznamu pomocí `FFmpeg`.  
** Network Resilience**: RTMP stream větev je oddělena od lokálního záznamu; výpadek sítě neovlivní soubor.

## ** Hlavní změny a opravy:**
Hlavní změny a opravy:
1. Implementace `mpph264enc`:
   - Nahrazení softwarového enkodéru za `Rockchip MPP` (`VPU`).
   - Nastavení `header-mode=1` pro vkládání `SPS/PPS` hlaviček (nutné pro RTMP).
   - Vynucení formátu **NV12**, který je nativní pro `Rockchip ISP/VPU`.

2. Oprava synchronizace audia (PulseAudio):
   - Přechod na vzorkovací frekvenci **44100 Hz** (nativní pro DietPi PulseAudio).
   - Přidání `slave-method=resample` do `pulsesrc` pro eliminaci praskání a zahazování vzorků (Dropped samples).
   - Nastavení `alignment-threshold` v `audiomixeru` pro vyhlazení jitteru.

3. Stabilizace RTMP streamu:
   - Přidání prvku `clocksync` pro srovnání časových značek (DTS/PTS).
   - Vynucení `stream-format=avc`, což opravuje chybu "Got backwards dts!".
   - Implementace `leaky front (queue)` pro ochranu lokálního záznamu při výpadku sítě.

4. Systémové úpravy:
   - Oprava přístupových práv k `/dev/mpp_service` a `/dev/dma_heap/system` přes udev.
   - Automatická finalizace MKV souborů pomocí `FFmpeg` po ukončení nahrávání.

## ** Ovládání**

| Alias | Příkaz | Popis |
| :---- | :----- |:------|
| start-stream | systemctl --user start ballabox.service | Spustí nahrávání a RTMP stream. |
| stop-stream  | systemctl --user stop ballabox.service |Bezpečně ukončí nahrávání a zfinalizuje soubor. |
| stav-stream  | journalctl -f _SYSTEMD_USER_UNIT=ballabox.service -o cat |Zobrazí aktuální stav služby a vytížení. |
| logy-stream  | systemctl --user status ballabox.service --no-pager -n 30 |Zobrazí výpis z MPP enkodéru v reálném čase. |

## ** Umístění souborů**

* Skript: ~/.local/bin/balla_box.py  
* Záznamy: ~/Videa/zaznam_YYYYMMDD_HHMMSS.mkv  
* Logy: journalctl --user -u ballabox.service

## ** Konfigurační poznámky**

* Audio: Optimalizováno pro mikrofon `alsa_input.usb-RODE_Microphones_RODE_NT-USB-00.analog-stereo`.  
* Hlasitost: Mikrofon 1.5x, plocha 0.4x.  
* Ukončení: Vždy používejte `stop-stream` (SIGINT), aby proběhla automatická oprava souboru.

## ** Instalace**

### ** 1. Systémové závislosti**
Nejdříve nainstalujte potřebné knihovny a nástroje `GStreameru`:
```bash
sudo apt update && sudo apt install -y \
python3-gi gir1.2-gst-plugins-base-1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-tools gstreamer1.0-alsa gstreamer1.0-pulseaudio ffmpeg alsa-utils
```

### ** 2. Příprava adresářů**
Vytvořte složku pro ukládání videí:
```bash
mkdir -p ~/Videa
```

## Instalace GStreamer pluginů a Rockchip MPP

Pro správnou funkci hardwarové akcelerace (`VPU`) je nutné zkompilovat knihovny přímo ze zdrojových kódů.

### ** 3. Příprava prostředí**
Nainstalujte nástroje pro kompilaci a vývojové hlavičky GStreameru:
```bash
sudo apt update
sudo apt install -y \
build-essential cmake meson ninja-build git \
libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
libgstreamer-plugins-bad1.0-dev pkg-config autoconf automake \
libtool ffmpeg
```
### ** 4. Kompilace Rockchip MPP (Media Process Platform)**
Knihovna MPP umožňuje GStreameru přístup k hardwarovému enkodéru.
```bash
mkdir -p ~/projects/install && cd ~/projects/install
git clone https://github.com/HermanChen/mpp
cd mpp && mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DLINUX=ON -DARCH=aarch64 ..
make -j$(nproc)
sudo make install
```
### ** 5. Kompilace GStreamer Rockchip Pluginu**
Tento plugin implementuje prvky jako mpph264enc.
```bash
cd ~/projects/install
git clone https://github.com/Meonardo/gst-rockchip.git
cd gst-rockchip
export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
meson setup build --prefix=/usr --libdir=lib/aarch64-linux-gnu
ninja -C build
sudo ninja -C build install
sudo ldconfig
rm -rf ~/.cache/gstreamer-1.0
```
### ** 6. Nastavení hardwarových oprávnění (`udev`)**
Vytvořte pravidla pro přístup k enkodéru pod běžným uživatelem:
```bash
sudo bash -c 'cat << EOF > /etc/udev/rules.d/99-rockchip-mpp.rules
KERNEL=="mpp_service", MODE="0660", GROUP="video"
KERNEL=="system", SUBSYSTEM=="dma_heap", MODE="0660", GROUP="video"
EOF'

sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG video,render,audio $USER
```
## Nastavení Audio Serveru (`PulseAudio`)
DietPi vyžaduje instalaci `PulseAudio` pro současné nahrávání mikrofonu a zvuku systému.

### ** 7. Instalace a konfigurace**
```bash
sudo apt install -y pulseaudio pulseaudio-utils
```
V sudo dietpi-config v sekci Audio Options vyberte svou zvukovou kartu (Rode NT-USB) pro inicializaci ovladačů v kernelu.

### ** 8. Automatické spuštění (`Systemd User Service`)**
Vytvořte službu, aby audio server běžel na pozadí:
```bash
mkdir -p ~/.config/systemd/user/
cat << EOF > ~/.config/systemd/user/pulseaudio.service
[Unit]
Description=PulseAudio Sound Server
[Service]
ExecStart=/usr/bin/pulseaudio --daemonize=no
Restart=always
[Install]
WantedBy=default.target
EOF

systemctl --user enable pulseaudio
systemctl --user start pulseaudio
```
### ** 9. Identifikace zařízení**
```bash
pactl list sources short
```

## ** 10. Nastavení Systemd (Služba)**
Pro automatické spouštění vytvořte soubor: ~/.config/systemd/user/ballabox.service
```bash
[Unit]

Description=Balla Box Universal (Python Version)

After=graphical-session.target pulseaudio.service
Wants=pulseaudio.service

StartLimitIntervalSec=0

StartLimitBurst=100

[Service]

Type=simple

ExecStart=/usr/bin/python3 %h/.local/bin/balla_box.py

KillSignal=SIGINT

Restart=on-failure

RestartSec=5s

Environment=DISPLAY=:0

Environment=XDG_RUNTIME_DIR=/run/user/%U

[Install]

WantedBy=default.target
```

Aktivujte službu:

```bash  
systemctl --user daemon-reload  
systemctl --user enable ballabox.service 
```

## ** 11. Spuštění aplikace**
Před prvním spuštěním ověřte, že systém vidí HW enkodér:
```bash
gst-inspect-1.0 mpph264enc
```
Spuštění nahrávání:
```bash
python3 balla_box.py
```
## ** 12. Troubleshooting**
** Backwards DTS**: Opraveno pomocí clocksync a vynucením stream-format=avc v RTMP větvi.
** Dropped Samples**: Vyřešeno nastavením frekvence na 44100 Hz a synchronizací slave-method=resample.
** Permissions**: Pokud plugin "neexistuje", zkontrolujte členství ve skupině video a udev pravidla.
