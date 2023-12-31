# AutoScriptBash

## Description 

Des petits script automatique pour faciliter la vie des sys-admin.

Crées par moi même il permette d'installer des petit ou gros programme, mais aussi permette de préparer une machine.

> **Script héberger sur le [git](https://git.foryouhost.fr/tomv) mais aussi sur mon [cloud public](https://get.tomv.ovh)**

## Usage

***
```bash
bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/menu.sh)
```
***

***MARCHE UNIQUEMENT SUR LINUX***

* Prend le lien de n'importe quel script (requis `curl`)
* Puis pour l'éxécuter faites : `bash <(curl -s [lien script])`

## Script Crées

### Héberger sur [GitHub](https://github.com/OverStyleFR)

* [new.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/new.sh) | Permet de installer les principaux packages après l'installation d'une **nouvelle machine sous __Linux__**.
* [speedtest.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/speedtest.sh) | Permet d'installer l'utilitaire `speedtest` de Ookla <sub>(qui est buger)</sub> sur Linux. **→** Fait par Martin Oscar et adapté par moi.
* [minecraft.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/minecraft.sh) | Permet d'installer n'importe quel version de Minecraft automatiquement. **(Pour l'instant il ne fait que la 1.16.5)**
* [massgrave.cmd](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/massgrave.cmd) | Permet de crack Windows, change d'édition de Windows, crack la suite Office. **→** Fait par [massgrave](https://github.com/massgravel) lien de [l'original](https://github.com/massgravel/Microsoft-Activation-Scripts).
* [user.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/user.sh) | Permet de crée un nouveau utilisateur **(a éxécuter en root)** avec un mot de passe définie ou pas (si c'est pas le cas, ca désactive l'authentification par mdp) et aussi demande si oui ou non on crée une nouvelle pair de clé SSH pour celui ci. Demande aussi si on dois mettre ma clé SSH publique ou une autre dans le fichier 'authorized_keys' pour se connecter avec celle ci. Demande également si on crée un dossier "gitea" dans le répertoire du nouveau utilisateur ainsi que si on dois mettre par défaut l'éditeur de texte `vim` pour git.
* [startup.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/startup.sh) | Permet de, coupler au 'crontab -e' automatiser le démarrage d'un serveur FiveM a chaque démarrage du VPS. Il crée un screen avec un nom et dedans lance une commande.
* [dockerinstall.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/dockerinstall.sh) | Permet l'installation de Docker dans sa dernière version.
* [yarn_install.sh](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/yarninstall.sh) | Permet l'installation de Yarn dans sa dernière version.
* [Pterodactyl Theme Re-install](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/pterodactylpanelreinstall.sh) | Permet la ré-installation du thème panel Pterodactyl, ceci va revenir a celui par défaut.
* [Pterodactyl Theme Installer](https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/pterodactylthemeinstaller.sh) | Un menu pour pterodactyl qui permet différente choses comme installer Pterodactyl, installer 3 thèmes (Enigma, Billing, Stellar) ainsi que de ré-installer le thème pterodactyl.
```bash
bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/pterodactylthemeinstaller.sh)
```

### Héberger sur [get.tomv.ovh](https://get.tomv.ovh/)

* [new.sh](https://get.tomv.ovh/new.sh) | Permet de installer les principaux packages après l'installation d'une **nouvelle machine sous __Linux__**.
* [speedtest.sh](https://get.tomv.ovh/speedtest.sh) | Permet d'installer l'utilitaire `speedtest` de Ookla <sub>(qui est buger)</sub> sur Linux. **→** Fait par Martin Oscar et adapté par moi.
* [minecraft.sh](https://get.tomv.ovh/minecraft.sh) | Permet d'installer n'importe quel version de Minecraft automatiquement. **(Pour l'instant il ne fait que la 1.16.5)**
* [massgrave.cmd](https://get.tomv.ovh/massgrave.cmd) | Permet de crack Windows, change d'édition de Windows, crack la suite Office. **→** Fait par [massgrave](https://github.com/massgravel) lien de [l'original](https://github.com/massgravel/Microsoft-Activation-Scripts).
* [user.sh](https://get.tomv.ovh/user.sh) | Permet de crée un nouveau utilisateur **(a éxécuter en root)** avec un mot de passe définie ou pas (si c'est pas le cas, ca désactive l'authentification par mdp) et aussi demande si oui ou non on crée une nouvelle pair de clé SSH pour celui ci. Demande aussi si on dois mettre ma clé SSH publique ou une autre dans le fichier 'authorized_keys' pour se connecter avec celle ci. Demande également si on crée un dossier "gitea" dans le répertoire du nouveau utilisateur ainsi que si on dois mettre par défaut l'éditeur de texte `vim` pour git.
* [startup.sh](https://get.tomv.ovh/startup.sh) | Permet de, coupler au 'crontab -e' automatiser le démarrage d'un serveur FiveM a chaque démarrage du VPS. Il crée un screen avec un nom et dedans lance une commande.
* [docker_install.sh](https://get.tomv.ovh/dockerinstall.sh) | Permet l'installation de Docker dans sa dernière version.
* [yarn_install.sh](https://get.tomv.ovh/yarninstall.sh) | Permet l'installation de Yarn dans sa dernière version.
* [pterodactylpanelreinstall.sh](https://get.tomv.ovh/pterodactylpanelreinstall.sh)) | Permet la ré-installation du thème panel Pterodactyl, ceci va revenir a celui par défaut.
* [Pterodactyl Theme Installer](https://get.tomv.ovh/pterodactylthemeinstaller.sh) | Un menu pour pterodactyl qui permet différente choses comme installer Pterodactyl, installer 3 thèmes (Enigma, Billing, Stellar) ainsi que de ré-installer le thème pterodactyl.
```bash
bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/pterodactylthemeinstaller.sh)
```