# SAE51 - Projet 2
## Installation d’un ERP/CRM

Ce projet vise à mettre en place un ERP/CRM avec un focus particulier sur la gestion de la base de données, l'importation des données CSV, et la sauvegarde automatisée des données via crontab.

## I. Base de données et Dolibarr

### Configuration de la base de données
* Assurez-vous d'avoir Docker installé sur votre système.
* Exécutez le script Bash suivant pour créer les volumes des conteneurs, le réseau, et démarrer les conteneurs MySQL et Dolibarr :

```bash
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
    --env MYSQL_DATABASE=dolibarr \
    --env character_set_client=utf8 \
    --env character-set-serveur=utf8mb4 \
    --env collation-serveur=utf8mb4_unicode_ci \
    --network=SAE51 \
    -d mysql

# peut être ajouter pour créer la base lors de la création du conteneur


echo "initialisation de la base de donnée veuillez patienter."
sleep 120
echo "initialisation terminée"

#mysql -u dolibarr -p'dolibarr' -h 127.0.0.1 --port=3306 dolibarr < SQL/createdoli.sql

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
```

## II. Importation des données CSV

### Préparation des données CSV
* Assurez-vous que vos fichiers CSV respectent le format spécifié dans la documentation.
* Placez les fichiers CSV dans le répertoire dédié (`CSV/`).

### Utilisation du script d'importation
* Exécutez le script Bash suivant pour importer les données depuis votre fichier CSV dans la base de données Dolibarr :

```bash
#!/bin/bash

while IFS=";" read -r line; do
    
    if [ "$line" != "nom;name_alias;ref_ext;code_client;" ]; then
        # Découper la ligne en champs en utilisant le délimiteur ';'
        IFS=";" read -r nom name_alias ref_ext code_client _ <<< "$line"
        
        
        mysql -u dolibarr -p'dolibarr' -h 127.0.0.1 --port=3306 dolibarr << EOF
        INSERT INTO llx_societe (nom, name_alias, ref_ext, code_client)
        VALUES ('$nom', '$name_alias', '$ref_ext', '$code_client');
EOF
    fi
done < "CSV/donnees.csv"
```

## III. Sauvegarde des données via crontab

### Configuration de la sauvegarde automatique
Réaliser après que  vos conteneurs Docker soient en cours d'exécution et que l'importation des données CSV a été effectuée avec succès.

1. Exécutez le script Bash suivant pour configurer la sauvegarde automatique des données via crontab :

    ```bash
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
        --env MYSQL_DATABASE=dolibarr \
        --env character_set_client=utf8 \
        --env character-set-serveur=utf8mb4 \
        --env collation-serveur=utf8mb4_unicode_ci \
        --network=SAE51 \
        -d mysql

    echo "initialisation de la base de donnée veuillez patienter."
    sleep 120
    echo "initialisation terminée"

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

    # Création et Initialisation du conteneur cron.
    echo "Création et Initialisation du conteneur cron."

    # Image et conteneur cron
    docker build -t cron_img -f cron/Dockerfile .

    docker run -d \
        --name cron_svg \
        -v dolibarr:/var/www/documents \
        --network=SAE51 \
        cron_img
    ```

2. Ajoutez les scripts suivants pour effectuer la sauvegarde automatique des données :

    #### `svg_hebdo.sh`

    ```bash
    #!/bin/bash

    mysqldump -u dolibarr -p'dolibarr' -h Base_mysql --port=3306 dolibarr > /var/www/documents/save.sql

    # Obtenir la date et l'heure actuelles au format YYYYMMDD_HHMMSS
    timestamp=$(date +"%Y%m%d_%H%M%S")

    # Construire le nom du fichier de sauvegarde
    filename="/var/www/documents/BACKUP/save_${timestamp}.sql"

    # Exécuter la commande mysqldump avec le nom de fichier généré
    mysqldump -u dolibarr -p'dolibarr' -h Base_mysql --port=3306 dolibarr > "$filename"
    ```

    #### `Dockerfile` dans le répertoire `cron`

    ```Dockerfile
    FROM ubuntu:22.04

    RUN apt-get update && apt-get upgrade -y
    RUN apt-get install mysql-client -y
    RUN apt-get install nano -y

    RUN apt-get install cron -y

    COPY cron/crontabs /crontabs

    RUN crontab /crontabs

    COPY cron/svg_hebdo.sh /svg_hebdo.sh

    RUN mkdir -p /var/www/documents/BACKUP

    CMD ["cron", "-f"]
    ```

    #### `crontabs`

    ```
    0 23 * * 0 /svg_hebdo.sh
    */5 * * * * /svg_hebdo.sh
    ```

3. Les sauvegardes seront effectuées automatiquement selon la planification définie dans le fichier `crontabs`,c'est-à-dire le dimanche à 23h, mais également une sauvegarde toute les 5 minutes. Vous pouvez également exécuter manuellement le script `svg_hebdo.sh` pour effectuer une sauvegarde à tout moment.
    ## IV. Nettoyage et Purge des Conteneurs

### Fichier `purge.sh`

Pour nettoyer et purger les conteneurs, les volumes, et les images Docker, utilisez le script Bash suivant :

#### `purge.sh`

```bash
#!/bin/bash

docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

docker network prune -f
docker volume rm $(docker volume ls -q)

docker rmi cron_img

echo "Tous les conteneurs et leurs volumes ont bien été supprimés."

