# Image de base
FROM jordan/icinga2:latest

##############################
## Config standard ##
##############################

# Installation de SSH pour monitoring et speedtest pour module
RUN apt-get update
RUN apt-get install -y ssh 

#Pour le check speedtest
RUN apt-get install -y speedtest-cli

#Pour le check des imprimantes
RUN apt-get install -y bc

#Pour la modif de fichier quand exec sur la machine
RUN apt-get install -y nano

#Pour le check Proxmox - PVE
RUN apt-get install -y python-enum34 python-requests

#Ajout des nouveaux plugins
COPY dkrfile_plugin/* /usr/lib/nagios/plugins/
RUN chmod 755 /usr/lib/nagios/plugins/check_vox_dpkg
RUN chmod 755 /usr/lib/nagios/plugins/check_snmp_printer

##############################
## Ajout des connexions SSH ##
##############################

#Copie les fichiers pour la connexion SSH
#RUN mkdir /root/.ssh
#COPY dkr_file_root/.ssh/id_rsa /root/.ssh/id_rsa
#COPY dkr_file_root/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub
#COPY dkr_file_root/.ssh/known_hosts /root/.ssh/known_hosts

#Copie les droits pour l'utilisation du monitoring plugins par SSH
#RUN cp -R /root/.ssh /var/lib/nagios
#RUN chown -R nagios: /var/lib/nagios/.ssh

####################
## Partie grafana ##
####################

#Ajout de grafana
RUN mkdir -p /usr/local/share/icingaweb2/modules/grafana/ \
&& wget -q --no-cookies -O - "https://github.com/Mikesch-mp/icingaweb2-module-grafana/archive/master.tar.gz" \
| tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/grafana --exclude=.gitignore -f -

############################
## A faire manuelllement  ##
############################

## Grafana ##

#Activation du perfdata
#RUN icinga2 feature enable perfdata

#Activation du InfluxDB
#RUN icinga2 feature enable influxdb

##SSH ##

#Copie les fichiers pour la connexion SSH
#RUN mkdir /root/.ssh
#COPY dkr_file_root/.ssh/id_rsa /root/.ssh/id_rsa
#COPY dkr_file_root/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub
#COPY dkr_file_root/.ssh/known_hosts /root/.ssh/known_hosts

#Copie les droits pour l'utilisation du monitoring plugins par SSH
#RUN cp -R /root/.ssh /var/lib/nagios
#RUN chown -R nagios: /var/lib/nagios/.ssh
