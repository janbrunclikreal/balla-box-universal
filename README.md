# **Balla Box Universal v1.1 (Python Edition)**

Profesionální řešení pro streamování a záznam obrazovky, kamery a zvuku na platformě **Orange Pi 5 Ultra**. Systém využívá hardwarovou akceleraci Rockchip MPP (Media Process Platform) pro minimální zátěž CPU.

## **🚀 Hlavní funkce**

* Hardware Encoding: Využití mpph264enc pro plynulé Full HD nahrávání.  
* PiP (Picture-in-Picture): Webkamera v rohu obrazovky s korektním škálováním (320x240).  
* Audio Mixing: Smíchání mikrofonu (Rode NT-USB) a systémového zvuku s nezávislou hlasitostí.  
* Auto-Fix: Automatická oprava metadat MKV souborů po ukončení záznamu pomocí FFmpeg.  
* Network Resilience: RTMP stream větev je oddělena od lokálního záznamu; výpadek sítě neovlivní soubor.

## **🛠 Instalace**

### **1\. Systémové závislosti**

Nejdříve nainstalujte potřebné knihovny a nástroje GStreameru:

sudo apt update && sudo apt install \-y python3-gi gir1.2-gst-plugins-base-1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-tools gstreamer1.0-alsa gstreamer1.0-pulseaudio ffmpeg alsa-utils

### **2\. Příprava adresářů**

Vytvořte složku pro ukládání videí:

mkdir \-p \~/Videa

## **⚙️ Nastavení Systemd (Služba)**

Pro automatické spouštění vytvořte soubor: \~/.config/systemd/user/ballabox.service

\[Unit\]

Description=Balla Box Universal (Python Version)

After=graphical-session.target pipewire.service pipewire-pulse.service

Wants=pipewire-pulse.service

StartLimitIntervalSec=0

StartLimitBurst=100

\[Service\]

Type=simple

ExecStart=/usr/bin/python3 %h/.local/bin/balla\_box.py

KillSignal=SIGINT

Restart=on-failure

RestartSec=5s

Environment=DISPLAY=:0

Environment=XDG\_RUNTIME\_DIR=/run/user/1000

\[Install\]

WantedBy=default.target


Aktivujte službu:

Bash  
systemctl \--user daemon-reload  
systemctl \--user enable ballabox.service 


## **🕹 Ovládání**

| Alias | Příkaz | Popis |
| :---- | :----- |:------|
| start-stream | systemctl --user start ballabox.service | Spustí nahrávání a RTMP stream. |
| stop-stream  | systemctl --user stop ballabox.service |Bezpečně ukončí nahrávání a zfinalizuje soubor. |
| stav-stream  | journalctl -f _SYSTEMD_USER_UNIT=ballabox.service -o cat |Zobrazí aktuální stav služby a vytížení. |
| logy-stream  | systemctl --user status ballabox.service --no-pager -n 30 |Zobrazí výpis z MPP enkodéru v reálném čase. |

## **📂 Umístění souborů**

* Skript: \~/.local/bin/balla\_box.py  
* Záznamy: \~/Videa/zaznam\_YYYYMMDD\_HHMMSS.mkv  
* Logy: journalctl \--user \-u ballabox.service

## **⚠️ Konfigurační poznámky**

* Audio: Optimalizováno pro mikrofon alsa\_input.usb-RODE\_Microphones\_RODE\_NT-USB-00.analog-stereo.  
* Hlasitost: Mikrofon 1.5x, plocha 0.4x.  
* Ukončení: Vždy používejte stop-stream (SIGINT), aby proběhla automatická oprava souboru.
