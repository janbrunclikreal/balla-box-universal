# ~/.bash_aliases - Janova osobní kuchařka

# Správa barev pro ls a grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Praktické ls aliasy
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Rychlá navigace a systém
alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo apt update && sudo apt upgrade -y'

# Alert pro dlouho běžící úlohy (např. kompilace)
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias pro hudbu s HW balancem
alias hudba="amixer -c NTUSB sset 'PCM' 10,24 > /dev/null && mpv"

# Alias pro video s HW balancem
alias video="amixer -c NTUSB sset 'PCM' 10,24 > /dev/null && mpv"

alias ytmp3='/usr/local/bin/yt-dlp --js-runtime node --cookies-from-browser chromium -x --audio-format mp3 --audio-quality 0'
alias yt720='/usr/local/bin/yt-dlp --cookies-from-browser chromium -f "bestvideo[height<=720]+bestaudio/best" --merge-output-format mkv'
alias yt4k='/usr/local/bin/yt-dlp --js-runtime node --cookies-from-browser chromium -f "bestvideo[vcodec^=vp9][height<=2160]+bestaudio/best" --merge-output-format mkv'
alias ytfhd='/usr/local/bin/yt-dlp --js-runtime node --cookies-from-browser chromium -f "bestvideo[vcodec^=vp9][height<=1080]+bestaudio/best" --merge-output-format mkv'

alias audio-fix='systemctl --user restart pulseaudio.service && sleep 1 && pactl set-default-sink alsa_output.usb-RODE_Microphones_RODE_NT-USB-00.an>'

alias record='sudo ~/.local/bin/nahravani_rt.sh'

# Spuštění streamu
alias start-stream='systemctl --user start ballabox.service;'

# Zastavení streamu
alias stop-stream='systemctl --user stop ballabox.service;'

# Živý výpis logů služby
alias logy-stream='journalctl -f _SYSTEMD_USER_UNIT=ballabox.service -o cat'

# Skutečný stav služby
alias stav-stream='systemctl --user status ballabox.service --no-pager -n 30'

# Watchdog log
alias watchdog-stream='tail -f /tmp/ballabox_watchdog.log'

alias ps-stream='
echo "=== SYSTEMD SLUŽBA ===";
systemctl --user is-active ballabox.service && systemctl --user status ballabox.service --no-pager -n 3 || echo "ballabox.service: STOPPED";
echo;
echo "=== GSTREAMER (gst-launch) ===";
pgrep -af gst-launch || echo "gst-launch: neběží";
echo;
echo "=== WATCHDOG ===";
pgrep -af ballabox_watchdog.sh || echo "watchdog: neběží";
'

alias ps-stream-mini='systemctl --user is-active ballabox.service >/dev/null && echo "STREAM: ON" || echo "STREAM: OFF"'

alias start-text='sudo systemctl isolate multi-user.target'
alias Start-grafika='sudo systemctl isolate graphical.target'

# Rychlá kontrola zdraví GPU a chyb v dmesg
alias health='dmesg | grep -iE "mali|hdmi|under-voltage|throttling" | tail -n 20'

# Diagnoza 
alias diagnoza-sluzby='systemctl list-units --state=failed'
alias diagnoza-zvukovky='pactl list sources short'
