# Spuštění a zastavení
alias start-stream='systemctl --user start ballabox.service'
# Přidáme výpis, aby uživatel věděl, že se čeká na korektní ukončení (finalizaci souboru)
alias stop-stream='echo "Ukončuji záznam a finalizuji soubor..."; systemctl --user stop ballabox.service && echo "Stream zastaven."'

# Živý výpis logů - jednodušší a univerzálnější verze
alias logy-stream='journalctl --user -u ballabox.service -f -o cat'

# Skutečný stav služby - přidáme zvýraznění barev
alias stav-stream='systemctl --user status ballabox.service --no-pager'

# Watchdog log (pokud používáte externí skript)
alias watchdog-stream='tail -f /tmp/ballabox_watchdog.log'

# Komplexní kontrola - upraveno pro Python implementaci
alias ps-stream='
echo "=== SYSTEMD STATUS ===";
systemctl --user is-active ballabox.service --quiet && echo -e "\033[0;32m● RUNNING\033[0m" || echo -e "\033[0;31m○ STOPPED\033[0m";
echo;
echo "=== PROCESY (Python/GStreamer) ===";
pgrep -af "python3 .*balla_box.py" || echo "Proces balla_box.py neběží.";
echo;
echo "=== HARDWARE ENCODER (MPP) ===";
if lsmod | grep -q "rk_vpu"; then echo "OK: RK VPU ovladač aktivní"; else echo "WARN: RK VPU nenalezen"; fi;
'

# Mini status pro prompt nebo rychlou kontrolu
alias ps-mini='systemctl --user is-active ballabox.service --quiet && echo "🔴 REC" || echo "⚪ IDLE"'
