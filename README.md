# BALLA BOX UNIVERSAL v1.0.0
Autor: Jan Brunclík (janbrunclik)  
Platforma/testováno: Orange Pi 5 Ultra (RK3588), kernel 6.1.43-rockchip-rk3588  
Kontakt: ulaskyeu@gmail.com

## Co to dělá
BALLA BOX UNIVERSAL je uživatelská (systemd --user) služba pro:
- capture obrazovky + kamera (v4l2)
- mix mikrofonu + desktop audia (PipeWire/PulseAudio)
- stream přes RTMP (GStreamer)
- současně ukládá lokální záznam do MKV (Matroska)

Součástí je watchdog, který umí restartovat službu při opakovaných audio drop chybách.

## Obsah repozitáře
- `.local/bin/balla_box_stable.sh` – hlavní GStreamer pipeline (stream + záznam)
- `.local/bin/ballabox_watchdog.sh` – watchdog nad journalctl a systemctl --user
- `.local/bin/fix_freq_rk3588.sh` – fix frekvencí CPU/GPU/NPU/DDR (vyžaduje root)
- `.config/systemd/user/ballabox.service` – user systemd unit

## Požadavky (runtime)
- systemd (user units)
- GStreamer 1.0 (`gst-launch-1.0`) a pluginy pro video/audio (včetně encoderu pro RK3588 dle distribuce)
- PipeWire/PulseAudio kompatibilní vrstva (používá `pulsesrc`)
- `ffmpeg` (pro opravu MKV po nekorektním ukončení)
- `nc` (netcat) pro test dostupnosti RTMP portu
- v4l2 kamera zařízení (`/dev/video1`)
- X11 (používá `ximagesrc` + DISPLAY)

Pozn.: audio device stringy jsou přímo konkrétní (PipeWire/PulseAudio názvy zařízení).

## Instalace (manuální, user-local)
1) Zkopíruj skripty:
```bash
install -Dm755 .local/bin/balla_box_stable.sh ~/.local/bin/balla_box_stable.sh
install -Dm755 .local/bin/ballabox_watchdog.sh ~/.local/bin/ballabox_watchdog.sh
install -Dm755 .local/bin/fix_freq_rk3588.sh ~/.local/bin/fix_freq_rk3588.sh
