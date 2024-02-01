#!/bin/bash

mysqldump -u dolibarr -p'dolibarr' -h Base_mysql --port=3306 dolibarr > /var/www/documents/save.sql

# Obtenir la date et l'heure actuelles au format YYYYMMDD_HHMMSS
timestamp=$(date +"%Y%m%d_%H%M%S")

# Construire le nom du fichier de sauvegarde
filename="/var/www/documents/BACKUP/save_${timestamp}.sql"

# Exécuter la commande mysqldump avec le nom de fichier généré
mysqldump -u dolibarr -p'dolibarr' -h Base_mysql --port=3306 dolibarr > "$filename"




#mysqldump: C'est une commande qui permet de créer des sauvegardes de bases de données MySQL.
