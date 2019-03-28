#!/bin/bash
# Auteur : Simon LENA

################################################
################ FONCTIONS

#Format du fichier Icinga

#set -x

CONF_NAGIOS()
{
echo -e "object Host \"$2 - $3 - $5\" {"
echo -e "vars.lieu = \"Externe\""
echo -e "check_command = \"check_httpnew\""
echo -e "vars.fqdn = \"$4\""
echo -e "}"
echo -e ""
}

## Gestion des prérequis ##
function preRequis {
	for arg in $@; do
		if ! which $arg >/dev/null; then
			echo "La commande $arg n'est pas installée !!!"
			exit 1
		fi
	done
}

###################
## Configuration ##
###################

CHEMIN_HOSTS="/DockerData/icinga2/config_icinga2/conf.d/hosts_externe.conf" #Chemin de création de l'host
preRequis jq ;

################################################
################ PROGRAM

# Demarrage du service nagios
#SERVICE_NAGIOS=nagios
#if P=$(pgrep $SERVICE_NAGIOS); then
#    echo "Redémarrage du service $SERVICE_NAGIOS"
#    pkill -f nagios
#    exit
#else
#    echo "Initialisation de la configuration NAGIOS"
#fi

#Recuperation de la listes des operations au format JSON

#Suppression du fichier temporaire utilisé par cURL
if [ -f $CHEMIN_HOSTS ]; then
  rm $CHEMIN_HOSTS
fi

############
## Page 1 ##
############

LISTE_OPERATIONS="$(curl -sS -H "Content-Type: application/json" "https://redmine.voxatool.com/projects/voxaly-prod/issues.json?key=160bef63823f4c08cfe005593652858e7ed523cd&status_id=19&category_id=324|325&limit=100&page=1")"

#Recuperation du nombre total des operations
NB_OPERATIONS="100"

#Recuperation du nombre total des operations
#NB_OPERATIONS=$(echo $LISTE_OPERATIONS | jq -r '.total_count')

#PATCH 1 : En cas de depassement de 100 car la limit de l'API est a 100 avec JSON
#if [ $NB_OPERATIONS > 100 ]; then
#  NB_OPERATIONS=100
#fi

#Compteur = 1
OPERATION=1

#Boucle pour chaque operation dans la liste d'operation
while [ $OPERATION -lt $NB_OPERATIONS ]
do
    #Recuperation de toutes les donnees lie a cette operation (TOUT LES CHAMPS REDMINE)
    DATA_OPERATION="$(echo $LISTE_OPERATIONS| jq -r '.issues['$OPERATION']')"

    #Recuperation du nom de l'operation
    NOM_OPERATION="$(echo $DATA_OPERATION | jq -r '.subject')"

      #Recuperation du numero de VM
      VM_OPERATION="$(echo $DATA_OPERATION | jq '.custom_fields[2].value' | sed 's/"//' | sed 's/"//')"

      #Recuperation du type de VM (SLA)
      VM_TYPE_OPERATION="$(echo $DATA_OPERATION | jq '.custom_fields[27].value' | sed 's/"//' | sed 's/"//')"

      #Recuperation de l'URL
      # sed 's/^ *//g' -> Suppression des espaces
      URL_OPERATION="$(echo $DATA_OPERATION | jq '.custom_fields[18].value' | sed 's/"//' | sed 's/https\?:\/\///' | sed 's/http\?:\/\///' | sed 's/\/"//' | sed 's/"//' | tr -d " " )"
      echo $URL_OPERATION;
      PAGE_SURVEILLANCE_EXIST="$(curl -o -I -L -s -w "%{http_code}\n" $URL_OPERATION/pages/surveillance)"

      if [ "$PAGE_SURVEILLANCE_EXIST" != "404" ] ; then
          TYPE_URL="VM-New"
      else
          TYPE_URL="VM-Old"
      fi

      #logs
      echo "Information recupérée : " $TYPE_URL "$VM_OPERATION" "$NOM_OPERATION" "$URL_OPERATION"

      echo "Opération" $OPERATION "NB_operations" $NB_OPERATIONS

      #Suppression du fichier temporaire utilisé par cURL
      if [ -f ./-I ]; then
        rm ./-I
      fi

      # Export de la conf au format nagios.conf
      CONF_NAGIOS $TYPE_URL "$VM_OPERATION" "$NOM_OPERATION" "$URL_OPERATION" "VM_TYPE_OPERATION" >> $CHEMIN_HOSTS

    # Compteur +1
    OPERATION=$(( ++OPERATION ))
done

############
## Page 2 ##
############

LISTE_OPERATIONS="$(curl -sS -H "Content-Type: application/json" "https://redmine.voxatool.com/projects/voxaly-prod/issues.json?key=160bef63823f4c08cfe005593652858e7ed523cd&status_id=19&category_id=324|325&limit=100&page=2")"

#Recuperation du nombre total des operations
NB_OPERATIONS=$(echo $LISTE_OPERATIONS | jq -r '.total_count')

#Compteur = 1
OPERATION=1

#Boucle pour chaque operation dans la liste d'operation
while [ $OPERATION -lt $NB_OPERATIONS ]
do
    #Recuperation de toutes les donnees lie a cette operation (TOUT LES CHAMPS REDMINE)
    DATA_OPERATION="$(echo $LISTE_OPERATIONS| jq -r '.issues['$OPERATION']')"

    #Recuperation du nom de l'operation
    NOM_OPERATION="$(echo $DATA_OPERATION | jq -r '.subject')"

    if [ -z "$NOM_OPERATION" ]; then

      #Recuperation du numero de VM
      VM_OPERATION="$(echo $DATA_OPERATION | jq '.custom_fields[2].value' | sed 's/"//' | sed 's/"//')"

      #Recuperation du type de VM (SLA)
      VM_TYPE_OPERATION="$(echo $DATA_OPERATION | jq '.custom_fields[27].value' | sed 's/"//' | sed 's/"//')"

      #Recuperation de l'URL
      URL_OPERATION="$(echo $DATA_OPERATION | jq '.custom_fields[18].value' | sed 's/"//' | sed 's/https\?:\/\///' | sed 's/http\?:\/\///' | sed 's/\/"//' | sed 's/"//' | tr -d " " )"
      echo URL_OPERATION;
      PAGE_SURVEILLANCE_EXIST="$(curl -o -I -L -s -w "%{http_code}\n" $URL_OPERATION/pages/surveillance)"

      if [ "$PAGE_SURVEILLANCE_EXIST" != "404" ] ; then
          TYPE_URL="VM-New"
      else
          TYPE_URL="VM-Old"
      fi

      #logs
      echo "Information recupérée : " $TYPE_URL "$VM_OPERATION" "$NOM_OPERATION" "$URL_OPERATION"

      echo "Opération" $OPERATION "NB_operations" $NB_OPERATIONS

      #Suppression du fichier temporaire utilisé par cURL
      #if [ -f ./-I ]; then
      #  rm ./-I
      #fi

      # Export de la conf au format nagios.conf
      CONF_NAGIOS $TYPE_URL "$VM_OPERATION" "$NOM_OPERATION" "$URL_OPERATION" "VM_TYPE_OPERATION" >> $CHEMIN_HOSTS
    fi

    # Compteur +1
    OPERATION=$(( ++OPERATION ))
done


#####################################
## Opération a faire sur le docker ##
#####################################

#Vérification de l'installation de ssh ( Pour les check_ssh )
#if ! which $arg >/dev/null; then echo "La commande $arg n'est pas installée !!!" fi


#bc -> Pour imprimante

#Relaod de icinga2
docker exec icinga2_icinga2_1 service icinga2 reload

# Deplacement des fichiers de configurations
#cp ./hosts.cfg /opt/nagios/etc/objects/hosts.cfg
#cp /Config/objects/manuel-hosts.cfg /opt/nagios/etc/objects/manuel-hosts.cfg

#   Lancement du processus cron
#SERVICE_CRON=cron
#if P=$(pgrep $SERVICE_CRON); then
#    echo "le service $SERVICE_CRON est déjà lancé"
#else
#    echo "Demarrage du service $SERVICE_CRON"
#    cron -f &
#fi


# Restitution des droits pour nagios (au cas ou)
#chown -R nagios:nagios /opt/nagios/

# Demarrage du service nagios
#echo "Demarrage du service Nagios"
#bash /usr/local/bin/start_nagios


