#!/usr/bin/env bash
set -euo pipefail

log(){ printf "\n\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }

pac(){ sudo pacman -S --needed --noconfirm "$@"; }
svc(){ sudo systemctl enable --now "$1" >/dev/null 2>&1 || true; }

append_once(){
  local line="$1" file="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -qxF "$line" "$file" || echo "$line" >> "$file"
}

main(){
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "Não rode como root. Use seu usuário com sudo."
    exit 1
  fi

  log "Atualizando sistema..."
  sudo pacman -Syu --noconfirm

  log "Rede (NetworkManager)..."
  pac networkmanager nm-connection-editor
  svc NetworkManager

  log "Base minimal + ferramentas modernas (leves e úteis)..."
  pac git curl wget unzip zip tar \
      nano vim \
      ca-certificates openssh \
      htop btop fastfetch \
      ripgrep fd bat eza fzf jq tree

  log "Stack gráfica leve (Xorg + i3) + apps (polybar/rofi/dunst/picom/kitty)..."
  pac xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-xset \
      mesa \
      i3-wm i3lock i3status i3blocks \
      polybar rofi dunst picom feh flameshot \
      kitty \
      brightnessctl

  log "Áudio moderno (PipeWire) + controle..."
  pac pipewire pipewire-pulse wireplumber pavucontrol
  svc wireplumber

  log "Fontes/ícones (pra ficar bonito de verdade)..."
  pac ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-font-awesome || true

  log "Yazi (file manager moderno)."
  if pacman -Si yazi >/dev/null 2>&1; then
    pac yazi
  else
    warn "Yazi não apareceu no seu mirror/repos agora. Instalando Ranger como fallback."
    pac ranger
  fi

  log "Shell (Zsh + Starship)..."
  pac zsh starship

  log "Pywal (cores automáticas pelo wallpaper)..."
  if pacman -Si python-pywal >/dev/null 2>&1; then
    pac python-pywal
  else
    warn "python-pywal não encontrado nos repos agora. Você pode instalar depois (AUR) — mas vou deixar os hooks prontos."
  fi

  log "LightDM (tela de login)..."
  pac lightdm lightdm-gtk-greeter
  svc lightdm

  # Pastas
  mkdir -p "$HOME/.config/"{i3,polybar,picom,rofi,dunst,kitty}
  mkdir -p "$HOME/.local/bin" "$HOME/Pictures/Wallpapers"

  # Wallpapers
  log "Baixando wallpapers lofi 4K (aleatórios)..."
  for i in 1 2 3 4 5; do
    curl -L --fail "https://source.unsplash.com/3840x2160/?lofi,anime,room,night" \
      -o "$HOME/Pictures/Wallpapers/lofi_${i}.jpg" >/dev/null 2>&1 || true
  done

  # Kitty
  log "Configurando Kitty..."
  cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
font_family      JetBrainsMono Nerd Font
font_size 12.0

# Transparência (blur vem do Picom)
background_opacity 0.88

enable_audio_bell no
confirm_os_window_close 0
scrollback_lines 8000
wheel_scroll_multiplier 3.0
EOF

  # Picom (blur)
  log "Configurando Picom (blur dual_kawase + sombras)..."
  cat > "$HOME/.config/picom/picom.conf" <<'EOF'
backend = "glx";
vsync = true;

shadow = true;
shadow-radius = 12;
shadow-opacity = 0.35;
shadow-offset-x = -6;
shadow-offset-y = -6;

inactive-opacity = 0.92;
active-opacity = 1.0;

blur-method = "dual_kawase";
blur-strength = 6;

blur-background-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "class_g = 'Rofi'",
  "class_g = 'Polybar'",
  "class_g = 'i3lock'"
];

unredir-if-possible = false;
EOF

  # Rofi (vai usar tema gerado pelo wal, quando existir)
  log "Configurando Rofi (base)..."
  cat > "$HOME/.config/rofi/config.rasi" <<'EOF'
configuration {
  show-icons: true;
  modi: "drun,run,window";
  font: "JetBrainsMono Nerd Font 11";
  theme: "~/.config/rofi/theme.rasi";
}
EOF

  # Tema Rofi default (caso wal ainda não rode)
  cat > "$HOME/.config/rofi/theme.rasi" <<'EOF'
* {
  bg: #111111cc;
  fg: #e6e6e6ff;
  accent: #772638ff;
  font: "JetBrainsMono Nerd Font 11";
}
window { background-color: @bg; border: 2px; border-color: @accent; border-radius: 12px; }
mainbox { padding: 12px; }
listview { lines: 10; }
element selected { background-color: @accent; text-color: #ffffff; border-radius: 10px; }
entry { background-color: #00000000; text-color: @fg; }
EOF

  # Dunst
  log "Configurando Dunst (notificações)..."
  cat > "$HOME/.config/dunst/dunstrc" <<'EOF'
[global]
monitor = 0
follow = mouse
width = 360
height = 300
origin = top-right
offset = 12x40
notification_limit = 5
font = JetBrainsMono Nerd Font 10
frame_width = 2
frame_color = "#772638"
separator_color = frame

[urgency_low]
background = "#111111"
foreground = "#E6E6E6"
timeout = 4

[urgency_normal]
background = "#111111"
foreground = "#E6E6E6"
timeout = 6

[urgency_critical]
background = "#772638"
foreground = "#ffffff"
timeout = 0
EOF

  # Polybar (com include opcional do wal)
  log "Configurando Polybar..."
  cat > "$HOME/.config/polybar/config.ini" <<'EOF'
; Se existir, esse include injeta cores do pywal
include-file = ~/.cache/wal/polybar.ini

[bar/main]
width = 100%
height = 28
radius = 10
fixed-center = true

; fallback (caso wal não exista ainda)
background = ${colors.background:#cc111111}
foreground = ${colors.foreground:#e6e6e6}

line-size = 2
padding-left = 2
padding-right = 2
module-margin = 2

font-0 = JetBrainsMono Nerd Font:size=10;2
font-1 = Font Awesome 6 Free Solid:size=10;2
enable-ipc = true

modules-left = i3
modules-center = date
modules-right = wlan cpu mem volume

[module/i3]
type = internal/i3
label-focused = %name%
label-focused-foreground = #ffffff
label-focused-background = ${colors.accent:#772638}
label-focused-padding = 2
label-unfocused = %name%
label-unfocused-padding = 2

[module/date]
type = internal/date
interval = 1
date = %a, %d/%m
time = %H:%M
label = %date%  %time%

[module/cpu]
type = internal/cpu
interval = 2
label = CPU %percentage%%

[module/mem]
type = internal/memory
interval = 2
label = RAM %percentage_used%%

[module/volume]
type = internal/pulseaudio
label-volume = VOL %percentage%%
label-muted = MUTED

[module/wlan]
type = internal/network
interface-type = wireless
interval = 3
label-connected = WiFi %essid%
label-disconnected = WiFi OFF
EOF

  cat > "$HOME/.config/polybar/launch.sh" <<'EOF'
#!/usr/bin/env bash
set -e
killall -q polybar || true
while pgrep -x polybar >/dev/null; do sleep 0.2; done
polybar main >/tmp/polybar.log 2>&1 &
EOF
  chmod +x "$HOME/.config/polybar/launch.sh"

  # Script: aplicar wallpaper + wal + atualizar rofi/polybar
  log "Criando script de tema (wallpaper -> wal -> rofi/polybar)..."
  cat > "$HOME/.local/bin/apply-theme" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

WALL="${1:-$HOME/Pictures/Wallpapers/lofi_1.jpg}"

# Wallpaper
command -v feh >/dev/null && feh --bg-fill "$WALL"

# pywal (se existir)
if command -v wal >/dev/null; then
  wal -i "$WALL" -n

  # Gera um include pro polybar com cores do wal
  mkdir -p "$HOME/.cache/wal"
  {
    echo "[colors]"
    # carrega cores do wal
    # shellcheck disable=SC1090
    source "$HOME/.cache/wal/colors.sh"
    echo "background = ${color0}cc"
    echo "foreground = ${color7}"
    echo "accent = ${color1}"
  } > "$HOME/.cache/wal/polybar.ini"

  # Gera tema do rofi baseado no wal
  {
    echo "* {"
    echo "  bg: ${color0}cc;"
    echo "  fg: ${color7}ff;"
    echo "  accent: ${color1}ff;"
    echo "  font: \"JetBrainsMono Nerd Font 11\";"
    echo "}"
    echo "window { background-color: @bg; border: 2px; border-color: @accent; border-radius: 12px; }"
    echo "mainbox { padding: 12px; }"
    echo "listview { lines: 10; }"
    echo "element selected { background-color: @accent; text-color: #ffffff; border-radius: 10px; }"
    echo "entry { background-color: #00000000; text-color: @fg; }"
  } > "$HOME/.config/rofi/theme.rasi"
fi

# Reinicia polybar pra pegar cores novas
if command -v "$HOME/.config/polybar/launch.sh" >/dev/null; then
  "$HOME/.config/polybar/launch.sh" || true
fi
EOF
  chmod +x "$HOME/.local/bin/apply-theme"

  # Script: trocar wallpaper rapidamente
  cat > "$HOME/.local/bin/next-wallpaper" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$HOME/Pictures/Wallpapers"
WALL="$(ls -1 "$DIR"/*.jpg 2>/dev/null | shuf -n 1)"
[ -n "${WALL:-}" ] && "$HOME/.local/bin/apply-theme" "$WALL"
EOF
  chmod +x "$HOME/.local/bin/next-wallpaper"

  # i3 config
  log "Configurando i3 (atalhos + autostart + gaps)..."
  cat > "$HOME/.config/i3/config" <<'EOF'
set $mod Mod4
font pango:JetBrainsMono Nerd Font 10

set $term kitty
set $menu rofi -show drun -show-icons

bindsym $mod+Return exec $term
bindsym $mod+d exec $menu
bindsym $mod+Shift+q kill
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Sair do i3?' -b 'Sim' 'i3-msg exit'"

bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

bindsym $mod+f fullscreen toggle
bindsym $mod+space floating toggle

gaps inner 10
gaps outer 4
default_border pixel 2
hide_edge_borders smart
smart_gaps on

bindsym Print exec flameshot gui
bindsym $mod+Shift+x exec "i3lock -c 000000"

# Yazi (file manager)
bindsym $mod+e exec kitty -e yazi

# Trocar wallpaper (e tema) na hora
bindsym $mod+w exec ~/.local/bin/next-wallpaper

# Autostart
exec_always --no-startup-id picom --config ~/.config/picom/picom.conf
exec_always --no-startup-id dunst
exec_always --no-startup-id ~/.local/bin/apply-theme ~/Pictures/Wallpapers/lofi_1.jpg

# Esconde barra padrão do i3 (usamos polybar)
bar { mode invisible }
EOF

  # Zsh + starship
  log "Configurando Zsh + Starship..."
  touch "$HOME/.zshrc"
  append_once 'eval "$(starship init zsh)"' "$HOME/.zshrc"
  append_once 'alias ls="eza --icons --group-directories-first"' "$HOME/.zshrc"
  append_once 'alias ll="eza -lah --icons --group-directories-first"' "$HOME/.zshrc"
  append_once 'alias cat="bat --paging=never"' "$HOME/.zshrc"
  append_once 'alias grep="rg"' "$HOME/.zshrc"
  append_once 'command -v fastfetch >/dev/null && fastfetch' "$HOME/.zshrc"

  mkdir -p "$HOME/.config"
  cat > "$HOME/.config/starship.toml" <<'EOF'
add_newline = false
command_timeout = 800
format = "$directory$git_branch$git_status$character"

[directory]
truncate_to_repo = true
truncation_length = 4
style = "bold cyan"

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold yellow"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
EOF

  log "Definindo zsh como shell padrão..."
  if [[ "${SHELL:-}" != "/bin/zsh" ]]; then
    chsh -s /bin/zsh || warn "Se não mudou automaticamente, rode: chsh -s /bin/zsh"
  fi

  log "Tudo pronto ✅"
  echo
  echo "Reinicie agora:  reboot"
  echo
  echo "Depois do reboot:"
  echo " - LightDM vai abrir. Selecione sessão i3 (se necessário) e faça login."
  echo
  echo "Atalhos:"
  echo "  Super+Enter  -> Kitty"
  echo "  Super+D      -> Rofi"
  echo "  Super+E      -> Yazi (no Kitty)"
  echo "  Super+W      -> Troca wallpaper + cores (pywal)"
  echo "  Print        -> Flameshot"
  echo "  Super+Shift+X -> Lock"
}

main "$@"
