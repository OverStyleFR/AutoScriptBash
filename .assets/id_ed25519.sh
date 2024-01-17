#!/bin/bash

# Définir les couleurs
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
VIOLET=$(tput setaf 5)
YELLOW=$(tput setaf 3)
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

# Ajout de la clé ssh
ssh_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVSyMXB20IMnS0GW35kAqQdXnDBJVNL6b4SFx7X8gzK tomv@Nzxt-Fuck-Win11"

# Vérifier si le dossier .ssh existe, sinon le créer
ssh_dir="$HOME/.ssh"
authorized_keys="$ssh_dir/authorized_keys"

if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    echo "Dossier $ssh_dir créé."
fi

# Vérifier si la clé SSH est déjà présente dans authorized_keys
if grep -qF "$ssh_key" "$authorized_keys"; then
    echo "La clé SSH est déjà présente dans $authorized_keys. Le script est annulé."
    exit 1
fi

# Ajouter la clé SSH publique au fichier authorized_keys
echo "$ssh_key" >> "$authorized_keys"
echo "Clé SSH publique ajoutée à $authorized_keys."

# Donner les bonnes permissions au dossier .ssh et au fichier authorized_keys
chmod 700 "$ssh_dir"
chmod 600 "$authorized_keys"
echo "Permissions mises à jour pour $ssh_dir et $authorized_keys."

echo "La clé SSH publique a été ajoutée avec succès à $authorized_keys."