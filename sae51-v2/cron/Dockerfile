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

#Exécute le service cron avec l'option -f (foreground), ce qui signifie qu'il s'exécute en mode avant-plan et ne se détache pas du terminal. Cela garantit que cron s'exécute en mode avant-plan, permettant au conteneur de rester actif et de maintenir l'exécution des tâches planifiées.
