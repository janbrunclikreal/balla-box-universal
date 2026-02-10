# BALLA BOX UNIVERSAL – streaming service for Orange Pi (RK3588)

Univerzální nástroje a konfigurace pro stabilní streamování na **Orange Pi 5 Ultra (RK3588)**. Tento repozitář slouží jako otevřený deník mého projektu a zároveň jako instalační sada pro komunitu.

## Klíčové vlastnosti
- **Capture**: Snímání obrazovky, kamery a mix audia přes PipeWire/GStreamer.
- **Automatizace**: Systemd služby pro automatický start a watchdog.
- **Optimalizace**: Fixace frekvencí RK3588 pro stabilní výkon bez dropů.
- **Distribuce**: Možnost snadného sestavení vlastního `.deb` balíčku pro čistou a bezpečnou instalaci.

## Instalace a sestavení balíčku
Pro maximální bezpečnost a čistotu systému doporučuji sestavit si balíček lokálně přímo na vašem zařízení. Tím máte plnou kontrolu nad tím, co se do vašeho systému instaluje.

### 1. Klonování repozitáře
```bash
git clone https://github.com/janbrunclikreal/balla-box-universal.git
cd balla-box-universal
