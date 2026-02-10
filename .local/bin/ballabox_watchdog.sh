#!/usr/bin/env bash
# =====================================================================
# BALLA BOX UNIVERSAL v1.0.0 – Autor: Jan Brunclík (janbrunclik)  
# Platforma: Orange Pi 5 Ultra (6.1.43-rockchip-rk3588)
# email : ulaskyeu@gmail.com 
# =====================================================================

set -euo pipefail

UNIT="ballabox.service"

# jen tvrdé audio problémy
PATTERN='Dropped [0-9]+ samples|Zvuk nelze nahrávat dostatečnou rychlostí'

GRACE=20        # prvních 20s po startu nereaguj
COOLDOWN=30     # max 1 restart za 30s
HIT_WINDOW=10   # 2 zásahy do 10s = restart
HIT_COUNT=2

started=$(date +%s)
last_restart=0
hits=0
first_hit=0

while IFS= read -r line; do
  # služba musí běžet
  systemctl --user -q is-active "$UNIT" || continue

  now=$(date +%s)

  # grace period po startu watchdogu
  if (( now - started < GRACE )); then
    continue
  fi

  if echo "$line" | grep -Eiq "$PATTERN"; then
    # počítej zásahy v okně
    if (( hits == 0 )); then
      first_hit=$now
      hits=1
    else
      if (( now - first_hit <= HIT_WINDOW )); then
        ((hits++))
      else
        # okno vypršelo -> začni znovu
        first_hit=$now
        hits=1
      fi
    fi

    # teprve když jsou 2 zásahy rychle po sobě
    if (( hits >= HIT_COUNT )); then
      # cooldown mezi restarty
      if (( now - last_restart >= COOLDOWN )); then
        last_restart=$now
        hits=0
        echo "[WATCHDOG] Audio problém (2x v ${HIT_WINDOW}s) → restart služby (cooldown ${COOLDOWN}s)"
        systemctl --user restart "$UNIT" || true
        sleep 5
      fi
    fi
  fi
done < <(journalctl -f _SYSTEMD_USER_UNIT="$UNIT" -o cat)
