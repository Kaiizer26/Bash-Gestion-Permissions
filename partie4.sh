#!/bin/bash

# Fonction pour gérer les ACL sur des répertoires partagés
gerer_acl() {
    echo "Entrez le répertoire pour lequel vous souhaitez configurer les ACL :"
    read repertoire

    # Vérifier si le répertoire existe
    if [ -d "$repertoire" ]; then
        echo "1. Ajouter une ACL pour un utilisateur ou un groupe"
        echo "2. Supprimer une ACL pour un utilisateur ou un groupe"
        echo "3. Afficher les ACL actuelles"
        read -p "Choisissez une option (1-3) : " choix_acl

        case $choix_acl in
            1)
                echo "Voulez-vous ajouter une ACL pour un utilisateur ou un groupe ? (u/g)"
                read type_entite
                echo "Entrez le nom de l'utilisateur ou du groupe :"
                read entite
                echo "Entrez les permissions (r pour lecture, w pour écriture, x pour exécution) :"
                read permissions

                if [[ "$type_entite" == "u" ]]; then
                    sudo setfacl -m u:$entite:$permissions "$repertoire"
                    echo "Les permissions ACL ont été appliquées à l'utilisateur $entite pour le répertoire $repertoire."
                elif [[ "$type_entite" == "g" ]]; then
                    sudo setfacl -m g:$entite:$permissions "$repertoire"
                    echo "Les permissions ACL ont été appliquées au groupe $entite pour le répertoire $repertoire."
                else
                    echo "Type d'entité non valide, veuillez choisir 'u' pour utilisateur ou 'g' pour groupe."
                fi
                ;;
            2)
                echo "Voulez-vous supprimer une ACL pour un utilisateur ou un groupe ? (u/g)"
                read type_entite
                echo "Entrez le nom de l'utilisateur ou du groupe :"
                read entite

                if [[ "$type_entite" == "u" ]]; then
                    sudo setfacl -x u:$entite "$repertoire"
                    echo "Les permissions ACL pour l'utilisateur $entite ont été supprimées."
                elif [[ "$type_entite" == "g" ]]; then
                    sudo setfacl -x g:$entite "$repertoire"
                    echo "Les permissions ACL pour le groupe $entite ont été supprimées."
                else
                    echo "Type d'entité non valide, veuillez choisir 'u' pour utilisateur ou 'g' pour groupe."
                fi
                ;;
            3)
                sudo getfacl "$repertoire"
                ;;
            *)
                echo "Option non valide."
                ;;
        esac
    else
        echo "Le répertoire spécifié n'existe pas."
    fi
}

# Fonction pour appliquer des ACL par défaut sur les fichiers créés dans un répertoire
appliquer_acl_defaut() {
    echo "Entrez le répertoire pour lequel vous souhaitez appliquer des ACL par défaut :"
    read repertoire

    if [ -d "$repertoire" ]; then
        echo "Voulez-vous appliquer des ACL par défaut pour un utilisateur ou un groupe ? (u/g)"
        read type_entite
        echo "Entrez le nom de l'utilisateur ou du groupe :"
        read entite
        echo "Entrez les permissions par défaut (r pour lecture, w pour écriture, x pour exécution) :"
        read permissions

        if [[ "$type_entite" == "u" ]]; then
            sudo setfacl -d -m u:$entite:$permissions "$repertoire"
            echo "Les ACL par défaut ont été appliquées à l'utilisateur $entite pour le répertoire $repertoire."
        elif [[ "$type_entite" == "g" ]]; then
            sudo setfacl -d -m g:$entite:$permissions "$repertoire"
            echo "Les ACL par défaut ont été appliquées au groupe $entite pour le répertoire $repertoire."
        else
            echo "Type d'entité non valide, veuillez choisir 'u' pour utilisateur ou 'g' pour groupe."
        fi
    else
        echo "Le répertoire spécifié n'existe pas."
    fi
}

# Menu pour gérer les ACL
echo "Gestion des ACL"
echo "1. Configurer les ACL sur un répertoire"
echo "2. Appliquer des ACL par défaut pour les nouveaux fichiers"
read -p "Choisissez une option (1-2) : " choix

case $choix in
    1)
        gerer_acl
        ;;
    2)
        appliquer_acl_defaut
        ;;
    *)
        echo "Option non valide."
        ;;
esac