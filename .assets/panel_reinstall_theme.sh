#!/bin/bash

cp .env /var/www/pterodactyl/

cd ~

sudo rm -r /var/www/pterodactyl

sudo mkdir /var/www/pterodactyl

cd /var/www/pterodactyl

curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz

tar -xzvf panel.tar.gz

sudo chmod -R 755 storage/* bootstrap/cache/

cd ~

cp .env /var/www/pterodactyl/

cd /var/www/pterodactyl

composer install --no-dev --optimize-autoloader

sudo chown -R www-data:www-data /var/www/pterodactyl/*
