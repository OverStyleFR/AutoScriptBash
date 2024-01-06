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

apt update
apt install gnupg{,2} -y
echo "deb  https://packagecloud.io/ookla/speedtest-cli/debian/ bullseye main" > /etc/apt/sources.list.d/ookla_speedtest-cli.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8E61C2AB9A6D1557
apt update
apt install speedtest -y
speedtest --accept-license -s 24215