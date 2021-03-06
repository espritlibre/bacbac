#!/bin/bash
# v0.1 - Script de sauvegarde incremental

## Variables
DATES=$(date +%d%m%Y --date='10 days ago')
RACINE=/home/backup/
CONF=bacbac.conf
LOG=bacbac.log
LOGF=bacbac_full.log
AMAIL=kaulian
# Variables exec
CP=/bin/cp
MKDIR=/bin/mkdir
RSYNC=/usr/bin/rsync
CUT=/bin/cut
RM=/bin/rm
MAIL=/usr/bin/mail
DATE=$(date +%d%m%Y)
DATE1=$(date +%d%m%Y --date='1 days ago')
DATES=$(date +%d%m%Y --date='10 days ago')

## Fonctions
# Decoupage des lignes de la conf
decoup () {
	XDECOUPE=$(echo $1 | $CUT -d: -f$2)
}


ch_frequence () {
	if [ $1 = "h" ];then
		# Synchro toutes les heures
		echo heure
	elif [ $1 = "j" ]; then
		# Synchro tous les jours 
		echo jour
	elif [ $1 = "m" ]; then
		# Synchro tous les mois
		echo mois
	else
		# Erreur dans le champs frequence
		echo "La valeur de la frequence est mauvaise pour la ligne : $ligne"
		exit 1 
	fi
}

ch_type () {
	if [ $1 = "d" ];then
		# Synchro dossier
		echo dossier
	elif [ $1 = "s" ]; then
		# Synchro script 
		echo script
	elif [ $1 = "g" ]; then
		# Synchro git
		echo git
	else
		# Erreur dans le champs type 
		echo "La valeur de le champs type est mauvaise pour la ligne : $ligne"
		exit 1 
	fi

}

ch_lodi() {
	if [ $1 = "l" ];then
		# Machine Locale
		echo local
	elif [ $1 = "d" ];then
		# Machine distante
		echo distante
	else
		# Erreur dans le champs lodi 
		echo "La valeur de le champs lodi est mauvaise pour la ligne : $ligne"
		exit 1 
	fi
	LODI=$1
}

initialisation () {
	if [ ! -d $RACINE\jour ]; then
		$MKDIR $RACINE\jour
	fi	
}

synchro () {
	# Création des repertoires intermediaires si besoin
	if [ ! -d $RACINE\jour/$1/$2 ];then
		$MKDIR -p $RACINE\jour/$1/$2
	fi
	if [ $LODI = "l" ];then
		$RSYNC -az $2 $RACINE\jour/$1/$2 2>>$LOGF
		RETVAL=$?
				if [ $RETVAL = 0 ];then
					echo "$1 :OK" >>$LOG
				else
					echo "$1 : ECHEC">>$LOG
					echo "1" > /tmp/bacbac_echec
				fi
	else
		$RSYNC -az -e "ssh -p $4" $2 $RACINE\jour/$1/$2 2>>$LOG
		RETVAL=$?
				if [ $RETVAL = 0 ];then
					echo "$1 :OK" >>$LOG
				else
					echo "$1 : ECHEC">>$LOG
					echo "1" > /tmp/bacbac_echec
				fi
		
	fi
}

suppression () {
	# Suppression de la plus vieille sauvegarde
	if [ -d $RACINE$DATES ]; then
		$RM -rf $RACINE$DATES
	else
		echo "--- Rien a supprimer ---"

	fi	

}


envoi_mail () {
	 # Envoi du rapport court si OK sinon du FULL
		if [ -f /tmp/bacbac_echec ]; then
			$MAIL -s "Sauvegarde du $DATE ! Echec !" $AMAIL < $LOGF
		else
			$MAIL -s "Sauvegarde du $DATE" $AMAIL < $LOG
		fi
}

## Script
echo "--- Lancement Backup ---"
echo $DATE > $LOG
echo $DATE > $LOGF
# Creation de jour si il nexiste pas lors de la premiere sauvegarde
echo "-- Initialisation --"
initialisation
# Rotation des logs
echo "-- Rotation des logs --"
	if [ ! -f /tmp/bacbac_rotation_$DATE ]; then
		echo " --- Rotation des dossiers --- "
		$CP -al $RACINE\jour $RACINE$DATE1
		echo 1 > /tmp/bacbac_rotation_$DATE
	fi
# Traitement du fichier de configuration ligne par ligne
while read ligne
	do
        chr=${ligne:0:1}
        case $chr in 
            "#" )  # Commentaires 
                ;;      
            *   )   
				# Gestion de la fréquence
                decoup $ligne 1
				ch_frequence $XDECOUPE
				# Gestion du type
				decoup $ligne 2							
				ch_type $XDECOUPE
				# Gestion local/distant
				decoup $ligne 3
				ch_lodi $XDECOUPE
				# Gestion du nom de la machine
				decoup $ligne 4
				NOMMACHINE=$XDECOUPE			    	
				# Gestion du repertoire a sauvegarder 
				decoup $ligne 5
				REPSRC=$XDECOUPE			    	
				# Gestion du repertoire de backup
				decoup $ligne 6 
				REPDST=$XDECOUPE			    	
				# Gestion du port SSH
				decoup $ligne 7
				PSSH=$XDECOUPE			    	
				### Lancement du backup
				echo "Synchro de $NOMMACHINE - $REPSRC"
				echo "--- $NOMMACHINE ---" >> $LOGF
				synchro $NOMMACHINE $REPSRC $REPDST $PSSH
				;;      
        esac    
    done < $CONF 
# Suppression de la plus vieille sauvegarde
suppression
# Envoi du mail
envoi_mail
