#!/bin/bash


docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

docker network prune -f
docker volume rm $(docker volume ls -q)

docker rmi cron_img


echo "tout les conteneurs et leur volumes ont bien été supprimer"

