# AutoScriptBash

## Description 

La repositoy `AutoScriptBash` est un endroit opensource ou vous pouvez y trouver différents outils/script a éxécuter pour la plus part sur Linux afin de vous simplifiez la vie et être plus productif.
Crées par moi même il permet d'installer des outils, que se soit des petit ou gros programme.

> **Vous retrouverez le menu principale de la repository sur mon [cloud public](https://get.tomv.ovh) , afin de tout simplement avoir une URL plus simple a mémoriser.**

## Usage

**Menu Principale - [GitHub](https://github.com/overstylefr)**

***
```bash
bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/menu.sh)
```
***

**Menu Principale - [Cloud Public](https://get.tomv.ovh)**

***
```bash
bash <(curl -s https://get.tomv.ovh/menu.sh)
```
***

## Script Crées

* [new.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/new.sh) | Permet de installer les principaux packages après l'installation d'une **nouvelle machine sous __Linux__**.
***
* [speedtest.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/speedtest.sh) | Permet d'installer l'utilitaire `speedtest` de Ookla <sub>(qui est buger)</sub> sur Linux. **→** Fait par Martin Oscar et adapté par moi.
***
* [minecraft.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/minecraft.sh) | Permet d'installer n'importe quel version de Minecraft automatiquement. **(Pour l'instant il ne fait que la 1.16.5)**
***
* [massgrave.cmd](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/massgrave.cmd) | Permet de crack Windows, change d'édition de Windows, crack la suite Office. **→** Fait par [massgrave](https://github.com/massgravel) lien de [l'original](https://github.com/massgravel/Microsoft-Activation-Scripts).
***
* [user.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/user.sh) | Permet de crée un nouveau utilisateur **(a éxécuter en root)** avec un mot de passe définie ou pas (si c'est pas le cas, ca désactive l'authentification par mdp) et aussi demande si oui ou non on crée une nouvelle pair de clé SSH pour celui ci. Demande aussi si on dois mettre ma clé SSH publique ou une autre dans le fichier 'authorized_keys' pour se connecter avec celle ci. Demande également si on crée un dossier "gitea" dans le répertoire du nouveau utilisateur ainsi que si on dois mettre par défaut l'éditeur de texte `vim` pour git.
***
* [startup.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/startup.sh) | Permet de, coupler au 'crontab -e' automatiser le démarrage d'un serveur FiveM a chaque démarrage du VPS. Il crée un screen avec un nom et dedans lance une commande.
***
* [dockerinstall.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/dockerinstall.sh) | Permet l'installation de Docker dans sa dernière version.
***
* [yarn_install.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/yarninstall.sh) | Permet l'installation de Yarn dans sa dernière version.
***
* [Pterodactyl Theme Re-install](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/pterodactylpanelreinstall.sh) | Permet la ré-installation du thème panel Pterodactyl, ceci va revenir a celui par défaut.
***
* [Pterodactyl Theme Installer](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/pterodactylthemeinstaller.sh) | Un menu pour pterodactyl qui permet différente choses comme installer Pterodactyl, installer 3 thèmes (Enigma, Billing, Stellar) ainsi que de ré-installer le thème pterodactyl.
```bash
bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/pterodactylthemeinstaller.sh)
```
***