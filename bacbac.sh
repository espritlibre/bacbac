#!/bin/bash
# v0.1 - Script de sauvegarde incremental

## Variables
CP=/bin/cp
RSYNC=/usr/bin/rsync
CUT=/bin/cut
CONF=bacbac.conf

## Fonctions
# Decoupage des lignes de la conf
decoup () {
	XDECOUPE=$(echo $1 | $CUT -d: -f$2)
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
				# ON traite la frequence
                decoup $ligne 1
				if [ $XDECOUPE = "h" ];then
					# Synchro toutes les heures
						echo heure
				elif [ $XDECOUPE = "j" ]; then
					# Synchro tous les jours 
						echo jour
				elif [ $XDECOUPE = "m" ]; then
					# Synchro tous les mois
						echo mois
				else
					# Erreur dans la variable de frequence
					echo "La valeur de la frequence est mauvaise pour la ligne : $ligne"
					exit 1 
				fi
                ;;      
        esac    
    done < $CONF 
 
