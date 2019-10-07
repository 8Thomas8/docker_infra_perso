FROM debian:buster

#https://github.com/imixs/imixs-docker/blob/master/backup/Dockerfile

MAINTAINER Ralph Soika <ralph.soika@imixs.com>

# install packages: psql and slim down image
RUN apt-get update && apt-get install --no-install-recommends -y 

RUN apt install -y vim wget gnupg
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
RUN apt update
RUN apt install -y cron ssh mariadb-client postgresql-client-11 
RUN apt-get clean 
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_*

# disable default crontab
COPY crontab /etc/crontab
# add the backup scripts into root/home
ADD backup.sh /root/backup.sh
RUN chmod +x /root/backup.sh
ADD backup_init.sh /root/backup_init.sh
RUN chmod +x /root/backup_init.sh
ADD restore.sh /root/restore.sh
RUN chmod +x /root/restore.sh
ADD backup_get.sh /root/backup_get.sh
RUN chmod +x /root/backup_get.sh

RUN mkdir /root/backups
VOLUME /root/backups

CMD ["/root/backup_init.sh"]
