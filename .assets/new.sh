#!/bin/bash

########################################## INITIALISATION ROOT ##########################################

# Vérifier si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root" 
   # Demander le mot de passe
   sudo "$0" "$@"
   exit 1
fi

# Le reste du script ici

#################################################### FIN ####################################################

apt update -y && apt full-upgrade --autoremove --purge -y

apt install gnupg{,2} lm-sensors curl wget htop nload screen vim git ncdu bpytop rsync man avahi-daemon tree dnsutils net-tools -y

# Installation de 'fastfetch' (remplacement de 'neofetch')
echo "Installation du paquet FastFetch"
bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/fastfetch-install.sh)

# Mettre l'heure de Europe/Paris
sudo timedatectl set-timezone Europe/Paris

# Initialisation IP #
(crontab -l ; echo "@reboot /bin/ping -c 5 1.1") | crontab -

cd
rm .bashrc
curl -O https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/.bashrc
source .bashrc

