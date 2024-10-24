#!/bin/bash

#Pour chaque utilisateur inactif
jours_inactivite=1
for utilisateur in $(lastlog -b $(jours_inactivite) | awk '{if (NR>1 && $4=="**Never") print $1}'); do

    # Générer une alerte
    echo "ALERTE : L'utilisateur $utilisateur est inactif depuis plus de 90 jours."

    # Proposer à l'administrateur de verrouiller ou supprimer le compte
    read -p "Voulez-vous verrouiller (v) ou supprimer (s) le compte de $utilisateur ? " choix

    if [[ $choix == "v" ]]; then
        # Verrouiller le compte de l'utilisateur
        chage -E 0 $utilisateur
        echo "Le compte de l'utilisateur $utilisateur a été verrouillé."

    elif [[ $choix == "s" ]]; then
        # Sauvegarder le répertoire personnel de l'utilisateur avant la suppression
        tar -zcvf /backup/${utilisateur}_home_backup.tar.gz /home/$utilisateur
        echo "Le répertoire personnel de $utilisateur a été sauvegardé dans /backup."

        # Supprimer le compte de l'utilisateur
        userdel -r $utilisateur
        echo "Le compte de $utilisateur a été supprimé."

    else
        echo "Option non reconnue, aucune action prise pour $utilisateur."
    fi

done
