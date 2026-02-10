#!/bin/bash
# =====================================================================
# BALLA BOX UNIVERSAL v1.0.0 – Autor: Jan Brunclík (janbrunclik)  
# Platforma: Orange Pi 5 Ultra (6.1.43-rockchip-rk3588)
# email : ulaskyeu@gmail.com 
# =====================================================================

set -e

# Globální parametry pro systemd prostředí
export DISPLAY=${DISPLAY:-:0}
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export PIPEWIRE_LATENCY="8192/48000"
export SHM_RENDER_DEVICE=/dev/dri/renderD128

# ---- CESTY -----------------------------------------------------------
RTMP_IP="192.168.76.12"
RTMP_PORT="9000"
RTMP_URL="rtmp://$RTMP_IP:$RTMP_PORT/live/rtmp"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE_DEST="/home/orangepi/Videa/zaznam_hry_$TIMESTAMP.mkv"

# ---- KONTROLA SÍTĚ (Mentor: Prověřujeme přímo dveře, ne jen plot) ----
echo "Kontroluji dostupnost RTMP portu ($RTMP_IP:$RTMP_PORT)..."

# Kontrola pomocí netcat (nc) - port 9000 musí být otevřen
if ! nc -z -w 5 "$RTMP_IP" "$RTMP_PORT"; then
    echo "CHYBA: RTMP Server na $RTMP_IP:$RTMP_PORT je nedostupný." >&2
    exit 1 # Ukončení s chybou pro systemd
fi

echo "Server naslouchá, startuji GStreamer."

# ---- VIDEO NASTAVENÍ -------------------------------------------------
WIDTH=1360
HEIGHT=768
ENCODER="mpph264enc bps=2800000 rc-mode=cbr gop=60"
VIDEO_CAPS="video/x-raw,format=NV12,width=$WIDTH,height=$HEIGHT"

# ---- NÁZVY AUDIO ZAŘÍZENÍ --------------------------------------------
MIC_SRC="alsa_input.usb-RODE_Microphones_RODE_NT-USB-00.analog-stereo"
DESKTOP_SRC="alsa_output.usb-RODE_Microphones_RODE_NT-USB-00.analog-stereo.monitor"

# ---- CLEANUP ---------------------------------------------------------
cleanup() {
    echo -e "\nUkončuji a fixuji záznam..."
    pkill -P $$ gst-launch-1.0 || true
    sleep 2
    if [ -s "$FILE_DEST" ]; then
        # Oprava hlaviček MKV při nekorektním ukončení
        ffmpeg -loglevel error -i "$FILE_DEST" -c copy -y "${FILE_DEST%.mkv}_fixed.mkv"
        mv "${FILE_DEST%.mkv}_fixed.mkv" "$FILE_DEST"
        echo "Soubor fixován: $FILE_DEST"
    fi
    exit 0
}
trap cleanup SIGINT SIGTERM

# ---- START PIPELINE ---------------------------------------------------
# Přidán parametr 'async=true' a 'blocksize' pro lepší stabilitu při síťových výkyvech
gst-launch-1.0 -e \
    compositor name=comp latency=300000000 \
        sink_0::zorder=0 \
        sink_1::zorder=1 sink_1::xpos=$((WIDTH - 320)) sink_1::ypos=$((HEIGHT - 240)) ! \
    queue max-size-buffers=0 max-size-time=1000000000 ! videoconvert ! $VIDEO_CAPS ! $ENCODER ! h264parse config-interval=-1 ! tee name=vtee \
    audiomixer name=amix latency=200000000 ! queue max-size-buffers=0 max-size-time=1000000000 ! audio/x-raw,rate=48000,channels=2 ! audioconvert ! voaacenc bitrate=128000 ! tee name=atee \
    pulsesrc device=$MIC_SRC do-timestamp=true provide-clock=true buffer-time=200000 latency-time=40000 ! \
        queue max-size-buffers=0 max-size-time=1000000000 ! audioconvert ! audioresample ! audiorate ! audio/x-raw,rate=48000,channels=2 ! volume volume=1.2 ! amix. \
    pulsesrc device=$DESKTOP_SRC do-timestamp=true provide-clock=false buffer-time=200000 latency-time=40000 ! \
        queue max-size-buffers=0 max-size-time=1000000000 ! audioconvert ! audioresample ! audiorate ! audio/x-raw,rate=48000,channels=2 ! volume volume=0.35 ! amix. \
    ximagesrc use-damage=false remote=true do-timestamp=true ! video/x-raw,framerate=30/1 ! \
        queue max-size-buffers=0 max-size-time=1000000000 ! videoconvert ! comp.sink_0 \
    v4l2src device=/dev/video1 do-timestamp=true ! \
        video/x-raw,format=YUY2,width=320,height=240,framerate=30/1 ! \
        queue max-size-buffers=0 max-size-time=1000000000 ! videoconvert ! comp.sink_1 \
    vtee. ! queue max-size-buffers=0 max-size-time=1000000000 ! mux. \
    atee. ! queue max-size-buffers=0 max-size-time=1000000000 ! mux. \
    matroskamux name=mux ! filesink location="$FILE_DEST" async=true \
    vtee. ! queue leaky=downstream max-size-buffers=0 max-size-time=1000000000 ! fmux. \
    atee. ! queue leaky=downstream max-size-buffers=0 max-size-time=1000000000 ! flvmux name=fmux ! rtmpsink location="$RTMP_URL" async=true
