# Version 0.2 - BETA

# Définir les couleurs
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
VIOLET=$(tput setaf 5)
BOLD=$(tput bold)
RESET=$(tput sgr0)

################################## INITIALISATION PACKAGES ###################

# Mise à jour de la machine

bash <(curl -s https://get.tomv.ovh/new.sh)

# Vérification packages

echo ""
echo "${RED}${BOLD}Chargement du script${RESET}"
sleep 3
echo ""

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

# Afficher le texte en vert et en gras
echo "${GREEN}${BOLD}Vérification de l'installation du package software-properties-common...${RESET}"

# Vérifier si le package software-properties-common est installé
if ! dpkg -s software-properties-common >/dev/null 2>&1; then
    # Afficher le texte en rouge et en gras
    echo "${BOLD}Le package software-properties-common n'est pas installé. Installation en cours...${RESET}"
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y software-properties-common >/dev/null 2>&1
else
    # Afficher le texte en vert et en gras
    echo "${BOLD}Le package software-properties-common est déjà installé.${RESET}"
fi

# Afficher le texte en vert et en gras
echo "${GREEN}${BOLD}Vérification de l'installation du package jq...${RESET}"

# Vérifier si le package jq est installé
if ! dpkg -s jq >/dev/null 2>&1; then
    # Afficher le texte en rouge et en gras
    echo "${BOLD}Le package jq n'est pas installé. Installation en cours...${RESET}"
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y jq >/dev/null 2>&1
else
    # Afficher le texte en vert et en gras
    echo "${BOLD}Le package jq est déjà installé.${RESET}"
fi

# Afficher le texte en vert et en gras
echo "${GREEN}${BOLD}Vérification de l'installation du package unzip...${RESET}"

# Vérifier si le package unzip est installé
if ! dpkg -s unzip >/dev/null 2>&1; then
    # Afficher le texte en rouge et en gras
    echo "${BOLD}Le package unzip n'est pas installé. Installation en cours...${RESET}"
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y unzip >/dev/null 2>&1
else
    # Afficher le texte en vert et en gras
    echo "${BOLD}Le package unzip est déjà installé.${RESET}"
fi

# Sauter une ligne
echo ""

# Afficher le texte en vert et en gras
echo "${GREEN}${BOLD}Ajout du référentiel AdoptOpenJDK...${RESET}"

# Ajouter le référentiel AdoptOpenJDK
if [ ! -f /etc/apt/sources.list.d/adoptopenjdk.list ]; then
    wget -O - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public >/dev/null 2>&1 | sudo apt-key add - >/dev/null 2>&1
    echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/adoptopenjdk.list >/dev/null 2>&1
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8AC3B29174885C03 >/dev/null 2>&1
    sudo apt-get update >/dev/null 2>&1
    # Afficher le texte en vert et en gras
    echo "${BOLD}Le référentiel AdoptOpenJDK a été ajouté.${RESET}"
else
    # Afficher le texte en vert et en gras
    echo "${BOLD}Le référentiel AdoptOpenJDK est déjà ajouté.${RESET}"
fi

################################## FIN #######################################

################################## INITIALISATION JAVA #######################

# Afficher le texte en vert et en gras
echo "${GREEN}${BOLD}Vérification de l'installation de Java...${RESET}"

# Vérifier si Java est installé
if command -v java >/dev/null 2>&1; then
    # Afficher la version de Java installée
    java -version
else
    # Afficher le texte en rouge et en gras
    echo "${BOLD}Java n'est pas installé sur ce système.${RESET}"
fi

################################## FIN #######################################
echo ""
echo ""

################## REPERTOIRE #####################
  echo "${GREEN}${BOLD}Création d'un répertoire pour le serveur...${RESET}"
  # Afficher le texte en gras
  echo "${BOLD}Où souhaitez-vous créer le répertoire ?${RESET}"
  echo "1. Dans la racine de la machine"
  echo "2. Dans la racine de l'utilisateur actuel"

  # Lire l'entrée de l'utilisateur
  read choix
  
  # Traitement de l'entrée de l'utilisateur
  case $choix in
      1)
          # Créer un répertoire dans la racine de la machine
          echo "${BOLD}Entrez le nom du répertoire que vous souhaitez créer :${RESET}"
          read repertoire_nom
          sudo mkdir "/$repertoire_nom"
          dir="/$repertoire_nom"    # <--- assigner la valeur du répertoire cible à la variable $dir
          echo "${BOLD}Le répertoire $repertoire_nom a été créé dans la racine de la machine.${RESET}"
          ;;
      2)
          # Créer un répertoire dans la racine de l'utilisateur actuel
          echo "${BOLD}Entrez le nom du répertoire que vous souhaitez créer :${RESET}"
          read repertoire_nom
          mkdir "$HOME/$repertoire_nom"
          dir="$HOME/$repertoire_nom"    # <--- assigner la valeur du répertoire cible à la variable $dir
          echo "${BOLD}Le répertoire $repertoire_nom a été créé dans la racine de l'utilisateur actuel.${RESET}"
          ;;
      *)
          # Afficher un message d'erreur si l'entrée de l'utilisateur est invalide
          echo "${RED}${BOLD}Choix invalide.${RESET}"
          exit 1
          ;;
  esac
  
  # Afficher un message de réussite
  echo "${GREEN}${BOLD}Opération réussie.${RESET}"

################ FIN ##############

################################## INSTALLATION SERVEUR ######################

# Fonction pour installer le serveur Forge
install_forge() {
server=minecraft_server_server
  echo "${VIOLET}${BOLD}Installation du serveur Forge...${RESET}"
  # Téléchargement du fichier zip pour la version de Forge spécifiée
  url="https://minecraftversion.net/download/forge/forge.jar-${version}.zip"
  cd "$dir" && wget "$url" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "${BOLD}Le fichier forge.jar-${version}.zip a été téléchargé.${RESET}"
  else
    echo "${RED}${BOLD}Erreur lors du téléchargement de la version de Forge spécifiée.${RESET}"
    exit 1
  fi

  # Extraction du fichier jar du serveur depuis le fichier zip
  cd "$dir" && unzip "forge.jar-${version}.zip" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "${BOLD}Le fichier forge-${version}.jar a été extrait.${RESET}"
    # Renommer le fichier jar du serveur
    mv "minecraft_server.${version}.jar" "$server.jar"
  else
    echo "${RED}${BOLD}Erreur lors de l'extraction du fichier jar du serveur Forge.${RESET}"
    exit 1
  fi
}

# Fonction pour installer le serveur Paper
install_paper() {
server=paper
  echo "${VIOLET}${BOLD}Installation du serveur Paper...${RESET}"
  # Récupérer la liste des builds disponibles pour la version spécifiée
  build_url="https://papermc.io/api/v2/projects/paper/versions/$version"
  build_json=$(curl -s $build_url)
  # Extraire le numéro de build le plus élevé
  latest_build=$(echo $build_json | jq -r '.builds[-1]')

  # Télécharger la dernière version de build disponible
  paper_url="https://papermc.io/api/v2/projects/paper/versions/$version/builds/$latest_build/downloads/paper-$version-$latest_build.jar"
  cd "$dir" && wget -O paper.jar "$paper_url" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
      echo "${BOLD}Le fichier paper.jar a été téléchargé.${RESET}"
  else
      echo "${RED}${BOLD}Erreur lors du téléchargement de la version de Paper spécifiée.${RESET}"
      exit 1
  fi
}


# Fonction pour installer le serveur Vanilla
install_vanilla() {
    server=minecraft_server
    echo "${VIOLET}${BOLD}Installation du serveur Vanilla...${RESET}"
    
    # Récupérer la liste des versions de Minecraft disponibles via l'API de Mojang
    versions_url="https://launchermeta.mojang.com/mc/game/version_manifest.json"
    versions_json=$(curl -s "$versions_url")
    
    # Chercher la version spécifiée dans les versions disponibles
    version_url=$(echo "$versions_json" | jq -r --arg version "$version" '.versions[] | select(.id == $version) | .url')
    
    # Récupérer l'URL de téléchargement pour la version spécifiée de Minecraft
    download_json=$(curl -s "$version_url")
    download_url=$(echo "$download_json" | jq -r '.downloads.server.url')
    
    # Télécharger le fichier jar du serveur Minecraft
    cd "$dir" && wget -O minecraft_server.jar "$download_url" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${BOLD}Le fichier minecraft_server.jar a été téléchargé.${RESET}"
    else
        echo "${RED}${BOLD}Erreur lors du téléchargement de la version de Minecraft spécifiée.${RESET}"
        exit 1
    fi
}

################################## FIN #######################################

# Menu pour choisir le type de serveur
echo "Choisissez le type de serveur à installer :"
echo "1. Forge"
echo "2. Paper"
echo "3. Vanilla"
read choice

case $choice in
  1)
    install_func=install_forge
    ;;
  2)
    install_func=install_paper
    ;;
  3)
    install_func=install_vanilla
    ;;
  *)
    echo "Choix invalide"
    exit 1
    ;;
esac

# Demander la version de Minecraft
echo "Quelle version de Minecraft souhaitez-vous installer ?"
read version

################################## INSTALLATION JAVA #########################

# Vérifier la version de Minecraft et installer la bonne version de Java
case $version in
  1.16.5 | 1.16.4 | 1.16.3 | 1.16.2 | 1.16.1 | 1.15.2 | 1.15.1 | 1.14.4 | 1.13.2 | 1.12.2 | 1.11.2 | 1.10.2 | 1.9.4 | 1.8.8 | 1.7.5)
    java_version=8
    ;;
  1.17 | 1.17.1)
    java_version=16
    ;;
  1.18 | 1.18.1 | 1.18.2 | 1.19 | 1.19.1 | 1.19.2)
    java_version=17
    ;;
  *)
    echo "Version invalide"
    exit 1
    ;;
esac

# Installer la bonne version de Java
echo "${GREEN}${BOLD}Installation de Java $java_version...${RESET}"
if [ "$java_version" = "8" ] || [ "$java_version" = "16" ]; then
  # Si java_version est égal à 8 ou 16 installe Java
  echo "${BOLD}Installation java $java_version...${RESET}"
  apt install adoptopenjdk-$java_version-hotspot -y >/dev/null 2>&1
else
  # Si java_version est différent de 8 et 16, faire autre chose
  if [ "$java_version" = "17" ]; then
    echo "${BOLD}Installation Java OpenJDK-17-jre-headless...${RESET}"
    sudo apt install -y openjdk-17-jre-headless >/dev/null 2>&1
  else
    echo "Java version inconnue"
  fi
fi

################################## FIN #######################################

# Appeler la fonction pour installer le serveur
$install_func

echo "${VIOLET}${BOLD}Le serveur minecraft $version a été installé.${RESET}"

# Script start.sh

touch start.sh
if [ $java_version -eq 8 ]; then
  java_cmd="/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64/bin/java"
elif [ $java_version -eq 16 ]; then
  java_cmd="/usr/lib/jvm/adoptopenjdk-16-hotspot-amd64/bin/java"
elif [ $java_version -eq 17 ]; then
  java_cmd="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
fi

# # Démarrer le serveur Minecraft
# $java_cmd -Xmx4G -Xms2G -jar minecraft_server.jar nogui

cd "$dir" && echo "$java_cmd -Xmx4096M -Xms2048M -jar $server.jar" > start.sh
echo "${GREEN}${BOLD}Le script start.sh a été créé.${RESET}"

# Donner les permissions au script 'start.sh'

cd "$dir" && chmod +x start.sh

# Lancement serveur pour création des fichiers de base

echo "${BLUE}${BOLD}Lancement du serveur pour crée les fichiers de base...${RESET}"
sleep 2
cd "$dir" && ./start.sh >/dev/null 2>&1

# Accepter les EULA (Condition générale de Mojang)

echo "${BLUE}${BOLD}Acceptation des Conditions générale de Mojang...${RESET}"
sleep 1
cd "$dir" && sed -i '/eula=/ s/false/true/' eula.txt

# Lancement du serveur FINAL

echo "${BLUE}${BOLD}Lancement du serveur...${RESET}"
sleep 2
cd "$dir" && ./start.sh
