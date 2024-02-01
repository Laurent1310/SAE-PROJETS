#!/bin/bash

# Création de volumes des conteneurs

docker volume create mysqldb

docker volume create dolibarr

docker network create SAE51

# Création du conteneur base de donnée

docker run --name Base_mysql \
	-p 3306:3306 \
	-v mysqldb:/var/lib/mysql \
	--env MYSQL_ROOT_PASSWORD=trap \
	--env MYSQL_USER=dolibarr \
	--env MYSQL_PASSWORD=dolibarr \
	--env MYSQL_DATABASE=dolibarr \  # Est ajouter pour créer la base lors de la création du conteneur	 
	--env character_set_client=utf8 \
	--env character-set-serveur=utf8mb4 \
	--env collation-serveur=utf8mb4_unicode_ci \
	--network=SAE51 \
	-d mysql



echo "initialisation de la base de donnée veuillez patienter."
sleep 120
echo "initialisation terminée"

#mysql -u dolibarr -p'dolibarr' -h 127.0.0.1 --port=3306 dolibarr 


# Création du conteneur dolibarr

docker run -p 80:80 \
	--name Dolibarr \
	--env DOLI_DB_HOST=Base_mysql \
	--env DOLI_DB_NAME=dolibarr \
	--env DOLI_MODULES=modSociete \
	--env DOLI_ADMIN_LOGIN=Doliuser \
	--env DOLI_ADMIN_PASSWORD=Doliuser \
	--network=SAE51 \
	-d \
	upshift/dolibarr



echo "initialisation du conteneur veuillez patienter."
sleep 180

echo "initialisation terminée"

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' Dolibarr

echo "Création et Initialisation du conteneur cron."

#Image et conteneur cron

docker build -t cron_img -f cron/Dockerfile .

docker run -d \
	--name cron_svg \
	-v dolibarr:/var/www/documents \
	--network=SAE51 \
	cron_img
