#!/bin/bash
# v0.1 - Script de sauvegarde incremental

## Variables
CP=/bin/cp
MKDIR=/bin/mkdir
RSYNC=/usr/bin/rsync
CUT=/bin/cut
CONF=bacbac.conf
RACINE=/home/backup/
DATE=$(date +%d%m%Y)
DATE2=$(date +%d%m%Y --date='2 days ago')


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

synchro () {
	# Création des repertoires intermediaires si besoin
	if [ ! -d $RACINE\jour/$1/$2 ];then
		$MKDIR -p $RACINE\jour/$1/$2
	fi
	if [ $LODI = "l" ];then
		$RSYNC -avz $2 $RACINE\jour/$1/$2
	else
		$RSYNC -avz -e "ssh -p $4" $2 $RACINE\jour/$1/$2
		
	fi
}

## Script
echo "--- Lancement Backup ---"
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
				echo $NOMMACHINE
				# Gestion du repertoire a sauvegarder 
				decoup $ligne 5
				REPSRC=$XDECOUPE			    	
				echo $REPSRC
				# Gestion du repertoire de backup
				decoup $ligne 6 
				REPDST=$XDECOUPE			    	
				echo $REPDST
				# Gestion du port SSH
				decoup $ligne 7
				PSSH=$XDECOUPE			    	
				echo $PSSH
				### Lancement du backup
				# Creation de jour si il nexiste pas lors de la premiere sauvegarde
				if [ ! -d $RACINE\jour ]; then
				 	mkdir $RACINE\jour	
				fi
				### !!Il faut mettre ici un test pour ne pas faire la rotation pour rien.... a voir comment je vais gere cela.
				# Rotation de jour en jour-1 si celle-ci n'a pas deja été faites
				echo " --- Rotation des dossiers --- "
				if [ ! -f /tmp/bacbac_rotation_$DATE ]; then
					$CP -al $RACINE\jour $RACINE$DATE2
					echo 1 > /tmp/bacbac_rotation
				fi
				# Lancement du backups .....
				echo " --- Synchronisation du repertoire jour --- "
				synchro $NOMMACHINE $REPSRC $REPDST $PSSH
				;;      
        esac    
    done < $CONF 
