#!/bin/bash

# -- Manual Function
man () {
  echo " To use this script u need SUDO permission and follows flag:

  wb-install.sh \$1 \$2

  \$1 :
  man     -> To open manual 
  install -> To install all customization
  backup  -> To make backup all confgs 

  \$2 :
  all     -> All defaults customizations
  select  -> To select customizations you want
  
  "
}

# -- Check if last output code ($?) is 0 [ OK ] or > [ Fail ]  
check () {
#  if [ $1 -eq 0 ]; then echo -e "[  Ok  ]" ; else echo -e "[ Fail ]" ; exit 1 ; fi
  if [ $1 -eq 0 ]; then echo -e "[  Ok  ]" ; else echo -e "[ Fail ]" ; fi
}

# -- Update and setup mirror function
setup () {
  printf "%-80s" "Set fast mirror and update system"
  sudo pacman-mirrors --geoip &>/dev/null && sudo pacman -Syyu --noconfirm &>/dev/null
  check $?
}

# -- Install Function
install () {
  declare -a APPS=(
    alacritty
    arandr
    i3-gaps
    brave
    firefox
    ttf-fira-code
    blueman
    arc-gtk-theme
    cmatrix
    cowsay
    feh
    git
    zsh
  )

  for APP in ${APPS[@]}; do
    if [[ $(pacman -Qs $APP | grep Nome | wc -l) -eq 0 ]]; then
      printf "%-80s" "Install - $APP"
      pacman -S $APP --noconfirm &>/dev/null
      check $?
    fi
  done

  declare -a YAY_PACKAGES=(
    #nerd-fonts-complete
    visual-studio-code-bin
    alacritty-themes
  )

    for YAY_PACKAGE in ${YAY_PACKAGES[@]}; do
        yay -S $YAY_PACKAGE --noconfirm &>/dev/null
    done

}

# -- Create folder tree function
folder () {
    echo " ~ * Create folder Stage :"

    printf "%-80s" "Create folder tree in home"
    mkdir -p ~/{cloud/{aws,azure},iac/{ansible,terraform},jenkins,kubernetes/{scripts,examples,helm},monitoring/{elk,zabbix,prometheus,splunk},scripts,hashcorp,python,docker} &>/dev/null
    check $?
}

# -- Configurate applications function
config () {
    echo " ~ * Config Stage :"

    printf "%-80s" "Create - aliasrc    config"
      cp ./config/aliasrc ~/.config/aliasrc &>/dev/null
      check $?

    printf "%-80s" "Create - i3         config"
      yes | cp ./config/i3 ~/.i3/config &>/dev/null
      check $?

    printf "%-80s" "Create - picom      config" 
      yes | cp ./config/picom ~/.config/picom.conf &>/dev/null
      check $?

#    printf "%-80s" "Create - rofi       config"

#    printf "%-80s" "Create - Xresource  config"

#    printf "%-80s" "Create - zsh        config"

    printf "%-80s" "Move wallpapers"
      cp -r ./wallpapers ~ &>/dev/null
      check $?

}

plugins () {
    echo "
     ~ * Plugin installing Stage :
     "
    echo "Not have plugins to install"
}

clear_f () {
    echo "
     ~ * Clearing Stage :
     "

    declare -a REMOVES=(
        conky
        gufw
        hexchat
        hplip
        avahi
        gimp
        vlc
    )

    for REMOVE in ${REMOVES[@]}; do
        printf "%-80s" "Unistall - $REMOVE"
        pacman -Rsc $REMOVE --noconfirm &>/dev/null
        check $?
    done

}

# -- Init default script
wb-init () {
  # - Step 0 - Update and Set mirror
  setup

  # - Step 1 - Install all dependencies
  install 

  # - Step 2 - Create all folder to setup all applications and configurate S.O.
  folder

  # - Step 3 - Configurate all application in ~/.config
  config

  # - Step 4 - Install plugins in zsh, vim, kubectl, aws-cli, azure-cli
  # plugins

  # - Step 5 - Clear local temp files and folders
  # clear_f 
}

clear

echo "
* ~ Dotfile Initializing
= = = = = = = = = = = = =
* ~ Wallace Bruno Gentil 

Some processes may take a few minutes please waiting...

"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root 'sudo'"
  exit
fi

wb-init

#printf "%-80s" "Install picom-jonaburg-git"
#  yay -S picom-jonaburg-git 2>/dev/null