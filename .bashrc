# ~/.bashrc - Jan Brunclik (v2026.2)

# Pokud neběží interaktivně, nepokračuj
case $- in
    *i*) ;;
      *) return;;
esac

# --- HISTORIE ---
# Ignorovat duplikáty a mezery, přepisovat soubor, kontrolovat velikost okna
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize
# Velkorysá historie pro dlouhodobé projekty
HISTSIZE=10000
HISTFILESIZE=20000
# Formát historie: [DD/MM/YY HH:MM:SS]
HISTTIMEFORMAT="%d/%m/%y %T "

# --- NASTAVENÍ SHELLU ---
# Oprava drobných překlepů v 'cd' a globbing (**)
shopt -s cdspell
shopt -s globstar

# Nastavení chroot identifikace
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Barevný prompt (PS1)
force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# --- LOKALIZACE ---
export LANG=cs_CZ.UTF-8
export LANGUAGE=cs_CZ.UTF-8
# LC_ALL nepoužíváme explicitně, aby bylo možné měnit sub-kategorie

# --- DOPLŇKY A ALIASY ---
# Načtení aliasů ze samostatného souboru
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Povolení doplňování příkazů (bash-completion)
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# méně přátelský k netextovým souborům
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Přidání .local/bin pouze pokud tam není
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Přidání .local/lib pouze pokud tam není
if [[ ":$LD_LIBRARY_PATH:" != *":$HOME/.local/lib:"* ]]; then
    export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
fi
# Cesty pro kompilaci (pokud budeš v budoucnu kompilovat audio moduly)
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"
