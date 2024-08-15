#!/bin/bash

# Fonction pour afficher des messages en couleur
function echo_color() {
  local color_code=$1
  shift
  echo -e "\e[${color_code}m$@\e[0m"
}

# Nom du dépôt GitHub
REPO="fastfetch-cli/fastfetch"

# Détecter l'architecture de la machine
ARCH=$(dpkg --print-architecture)
echo_color "32" "Architecture détectée : $ARCH"

# Récupération de la dernière version du dépôt
echo_color "34" "Récupération de la dernière version du dépôt $REPO..."
LATEST_RELEASE=$(curl --silent https://api.github.com/repos/$REPO/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo_color "32" "Dernière version trouvée : $LATEST_RELEASE"

# Recherche du fichier correspondant à l'architecture
echo_color "34" "Recherche du fichier correspondant à l'architecture $ARCH..."
ASSET_URL=$(curl --silent https://api.github.com/repos/$REPO/releases/latest | grep "browser_download_url.*$ARCH.deb" | cut -d '"' -f 4)

# Vérification si l'URL a été trouvée
if [ -z "$ASSET_URL" ]; then
  echo_color "31" "Aucun fichier correspondant à l'architecture $ARCH trouvé."
  exit 1
fi

# Extraction du nom du fichier à partir de l'URL
FILENAME=$(basename "$ASSET_URL")
echo_color "32" "Fichier trouvé : $FILENAME"

# Téléchargement du paquet Debian
echo_color "34" "Téléchargement du fichier $FILENAME..."
curl -sL "$ASSET_URL" -o "$FILENAME"
echo_color "32" "Téléchargement terminé : $FILENAME"

# Vérification et installation de sudo si nécessaire
if ! command -v sudo &> /dev/null; then
  echo_color "33" "La commande 'sudo' n'est pas installée. Installation de 'sudo'..."
  apt-get update -qq && apt-get install -y -qq sudo
fi

# Installation du paquet Debian
echo_color "34" "Installation du paquet $FILENAME..."
sudo dpkg -i "$FILENAME" &> /dev/null
