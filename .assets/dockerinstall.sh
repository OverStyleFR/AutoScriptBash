#!/bin/bash

# Définir les couleurs
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
VIOLET=$(tput setaf 5)
BOLD=$(tput bold)
RESET=$(tput sgr0)
########################################## INITIALISATION ROOT ##########################################

# Vérifier si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "${RED}${BOLD}Ce script doit être exécuté en tant que root${RESET}" 
   # Demander le mot de passe
   sudo "$0" "$@"
   exit 1
fi

# Le reste du script ici

########################### ISSUE DOCKER ############################# [https://copyprogramming.com/howto/error-starting-docker-daemon-on-ubuntu-14-04-devices-cgroup-isn-t-mounted]

# Vérifier si le package est installé
if dpkg -l | grep -q "cgroupfs-mount"; then
    echo "Le package cgroupfs-mount est déjà installé."
else
    # Installer le package s'il n'est pas installé
    echo "Le package cgroupfs-mount n'est pas installé. Installation en cours..."
    apt-get update
    apt-get install -y cgroupfs-mount

    # Vérifier si l'installation a réussi
    if [ $? -eq 0 ]; then
        echo "L'installation du package cgroupfs-mount a réussi."
    else
        echo "Erreur lors de l'installation du package cgroupfs-mount."
        exit 1
    fi
fi

########################### DOCKER INSTALL ########################### [https://docs.docker.com/engine/install/debian/]

# Préparation #
apt-get update -y
apt-get install ca-certificates curl gnupg -y
##

# Ajout de la clé #
echo ""
echo "${GREEN}${BOLD}Ajout de la clé${RESET}"
echo ""

sleep 1

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
##

# Ajout du repository #
echo ""
echo "${GREEN}${BOLD}Ajout du repository${RESET}"
echo ""

sleep 1

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
   tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
##

## INSTALLATION DOCKER | Last Version ##
echo ""
echo "${BLUE}${BOLD}Installation de la dernière version de docker${RESET}"
echo ""

sleep 1

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
### FIN ###

# TEST #
echo ""
echo "${VIOLET}${BOLD}Test de Docker avec l'image "Hello-world"${RESET}"
echo ""

sleep 1

docker run hello-world
### FIN ###

# Suppresion images "Hello-world" #
echo "${GREEN}${BOLD}Suppresion de l'image "Hello-world"${RESET}"

docker rmi hello-world -f


#### CREATION DOSSIER DOCKER ####

echo ""
echo "${BLUE}${BOLD}Création du dossier Docker.${RESET}"
echo ""

cd
mkdir Docker
cd Docker
mkdir applications
touch docker-compose.yml
bash
#####################################################################
