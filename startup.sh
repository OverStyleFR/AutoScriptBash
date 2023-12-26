#!/bin/bash

# Créer un nouveau screen avec le nom 'rl' et exécuter './start.sh' dedans
screen -dmS CUSTOM ./start.sh

echo "Le screen 'CUSTOM' a ete cree et la commande './start.sh' a ete lancee a l'interieur."
