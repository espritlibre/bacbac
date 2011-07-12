#!/bin/bash
# v0.1 - Script de sauvegarde incremental

## Variables
CP=/bin/cp
RSYNC=/usr/bin/rsync
CONF=bacbac.conf

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
                echo $ligne
                ;;      
        esac    
    done < $CONF 
 
