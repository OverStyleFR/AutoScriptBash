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

########################################## INITIALISATION PACKAGES ##########################################

# Liste des packages nécessaires à l'exécution du script
required_packages=("git" "curl" "vim")

# Vérifier si chaque package est installé
for package in "${required_packages[@]}"
do
  if ! dpkg-query -W -f='${Status}' "$package" | grep "installed" > /dev/null 2>&1; then
    echo "Le package '$package' n'est pas installé. Installation en cours..."
    sudo apt-get install "$package" -y > /dev/null 2>&1
  else
    echo "Le package '$package' est déjà installé."
  fi
done

########################################## USER.SH ##########################################

# Demander le nom d'utilisateur à créer
read -p "Entrez le nom de l'utilisateur à créer: " username

# Demander le mot de passe de l'utilisateur
read -s -p "Entrez un mot de passe pour l'utilisateur (laissez vide pour aucun mot de passe) : " password
echo

# Créer l'utilisateur
echo "Création de l'utilisateur..."
useradd -m -s /bin/bash $username

# Définir le mot de passe de l'utilisateur ou désactiver l'authentification par mot de passe si aucun mot de passe n'a été saisi
if [ -n "$password" ]; then
  echo "Définition du mot de passe..."
  echo "$username:$password" | chpasswd
else
  echo "Aucun mot de passe défini pour l'utilisateur $username."
  echo "Désactivation de l'authentification par mot de passe..."
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
fi

################# GROUPS #################

# Demande à l'utilisateur s'il souhaite créer un nouveau groupe ou ajouter l'utilisateur à un groupe existant
read -p "Voulez-vous créer un nouveau groupe pour $username (y/n) : " choice_groups

if [ "$choice_groups" == "y" ]; then
  # Si l'utilisateur souhaite créer un nouveau groupe, demande le nom du groupe
  read -p "Entrez le nom du nouveau groupe : " groupname
  
  # Crée le nouveau groupe avec l'utilisateur $username comme membre
  sudo groupadd $groupname
  sudo usermod -a -G $groupname $username
  
  # Demande à l'utilisateur s'il souhaite ajouter d'autres utilisateurs au groupe
  read -p "Voulez-vous ajouter d'autres utilisateurs à ce groupe (y/n) : " add_users_choice
  if [ "$add_users_choice" == "y" ]; then
    # Si l'utilisateur souhaite ajouter d'autres utilisateurs, demande les noms d'utilisateurs séparés par des espaces
    read -p "Entrez les noms d'utilisateurs séparés par des espaces : " users_to_add
    
    # Ajoute les utilisateurs spécifiés au groupe
    for user in $users_to_add; do
      sudo usermod -a -G $groupname $user
    done
    
    echo "Les utilisateurs suivants ont été ajoutés au groupe $groupname : $users_to_add"
  else
    echo "Le groupe $groupname a été créé et l'utilisateur $username a été ajouté."
  fi
else
  # Si l'utilisateur souhaite ajouter l'utilisateur à un groupe existant, demande le nom du groupe
  read -p "Entrez le nom du groupe existant : " groupname
  
  # Ajoute l'utilisateur $username au groupe existant
  sudo usermod -a -G $groupname $username
  echo "L'utilisateur $username a été ajouté au groupe $groupname."
fi


###########################################

# Redémarrer le service SSH pour prendre en compte les modifications de configuration
systemctl restart sshd

# Demander s'il faut créer le dossier 'gitea'
read -p "Voulez-vous créer un dossier 'gitea' dans le répertoire de $username ? (y/n) " create_gitea

# Demande s'il faut mettre par défaut l'éditeur de texte 'vim' pour git
read -p "Voulez-vous mettre par défaut l'éditeur de texte 'vim' pour git ? (y:n) " vim_default

# Créer le dossier 'gitea' si demandé
if [ "$create_gitea" == "y" ]; then
  echo "Création du dossier 'gitea'..."
  mkdir /home/$username/gitea
  chown $username:$username /home/$username/gitea # Ajout de cette ligne pour donner les permissions à l'utilisateur $username
fi

# Demander s'il faut créer une paire de clés SSH
read -p "Voulez-vous créer une nouvelle paire de clés SSH pour $username ? (y/n) " create_ssh

# Vérification de l'existance du fichier ".ssh"
echo "Vérification de l'existance du dossier .ssh dans $username"
if [ ! -d "/home/$username/.ssh" ]; then
  mkdir -m 700 "/home/$username/.ssh"
  echo "Le dossier .ssh a été créé avec succès."
else
  echo "Le dossier .ssh existe déjà."
fi

# Créer une nouvelle paire de clés SSH si demandé
if [ "$create_ssh" == "y" ]; then
  echo "Création d'une nouvelle paire de clés SSH pour $username..."
  read -p "Entrez un nom pour la nouvelle clé: " key_name
  ssh-keygen -t ed25519 -C "$username@$key_name" -f "/home/$username/.ssh/id_ed25519"
fi

# Demander si l'utilisateur veut ajouter une clé SSH publique
read -p "Voulez-vous ajouter une clé SSH publique ? (y/n) " response

# Si l'utilisateur répond "y", ajouter une clé SSH publique
if [[ $response =~ ^[Yy]$ ]]; then
  # Demander à l'utilisateur s'il veut ajouter la clé SSH publique de "tomv"
  read -p "Voulez-vous ajouter la clé SSH publique de tomv ? (y/n) " response_tomv
  if [[ $response_tomv =~ ^[Yy]$ ]]; then
    cat <<EOF > /home/$username/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVSyMXB20IMnS0GW35kAqQdXnDBJVNL6b4SFx7X8gzK tomv@$HOSTNAME
EOF
  else
    read -p "Entrez la clé SSH publique à ajouter ou l'URL pour la récupérer : " ssh_key_pub
    if [[ $ssh_key_pub == "http"* ]] || [[ $ssh_key_pub == "https"* ]]; then
      ssh_key_pub=$(curl $ssh_key_pub)
    fi
    echo $ssh_key_pub >> /home/$username/.ssh/authorized_keys
  fi
else
  read -p "Veuillez saisir la clé publique ou l'URL pour la récupérer: " key_data
  if [[ $key_data == "http"* ]] || [[ $key_data == "https"* ]]; then
    key_data=$(curl $key_data)
  fi
  echo "Ajout de la clé publique..."
  echo $key_data >> /home/$username/.ssh/authorized_keys
fi

# Changer le propriétaire et les permissions des fichiers SSH
echo "Changement des permissions pour les fichiers SSH..."
chown -R $username:$username /home/$username/.ssh
chmod 700 /home/$username/.ssh
chmod 600 /home/$username/.ssh/*

# Ouvrir l'éditeur vim pour configurer Git
if [ "$vim_default" == "y" ]; then
  echo "Configuration de Git..."
  su -c "git config --global core.editor vim" -s /bin/bash $username
fi

echo "Terminé."

# Accéder au compte de l'utilisateur
echo "Ouverture d'un terminale vers le nouveau utilisateur $username"
sudo -u $username bash

########################################## FIN ##########################################