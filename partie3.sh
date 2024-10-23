#!/bin/bash

# Fonction pour créer un groupe
creer_groupe() {
    # Demander à l'utilisateur d'entrer un nom de groupe
    echo "Entrez le nom du groupe à créer :"
    read groupe

    # Vérifier si le groupe existe déjà
    if getent group "$groupe" > /dev/null 2>&1; then
        echo "Le groupe $groupe existe déjà."
    else
        sudo groupadd "$groupe"
        if [ $? -eq 0 ]; then
            echo "Le groupe $groupe a été créé avec succès."
        else
            echo "Erreur lors de la création du groupe $groupe."
        fi
    fi
}

# Fonction pour ajouter un utilisateur à un groupe
ajouter_utilisateur_groupe() {
    # Demander le nom de l'utilisateur et du groupe
    echo "Entrez le nom de l'utilisateur à ajouter :"
    read utilisateur
    echo "Entrez le nom du groupe auquel l'ajouter :"
    read groupe

    # Vérifier si l'utilisateur existe, puis l'ajouter au groupe
    if id "$utilisateur" &>/dev/null; then
        sudo usermod -a -G "$groupe" "$utilisateur"
        echo "L'utilisateur $utilisateur a été ajouté au groupe $groupe."
    else
        echo "L'utilisateur $utilisateur n'existe pas."
    fi
}

# Fonction pour retirer un utilisateur d'un groupe
retirer_utilisateur_groupe() {
    # Demander le nom de l'utilisateur et du groupe
    echo "Entrez le nom de l'utilisateur à retirer :"
    read utilisateur
    echo "Entrez le nom du groupe duquel le retirer :"
    read groupe

    # Vérifier si l'utilisateur existe, puis le retirer du groupe
    if id "$utilisateur" &>/dev/null; then
        sudo gpasswd -d "$utilisateur" "$groupe"
        echo "L'utilisateur $utilisateur a été retiré du groupe $groupe."
    else
        echo "L'utilisateur $utilisateur n'existe pas."
    fi
}

# Fonction pour supprimer un groupe vide
supprimer_groupe() {
    # Demander le nom du groupe à supprimer
    echo "Entrez le nom du groupe à supprimer :"
    read groupe

    # Vérifier si le groupe existe et s'il est vide, puis le supprimer
    if getent group "$groupe" > /dev/null 2>&1; then
        if [ -z "$(getent passwd | grep ":$groupe")" ]; then
            sudo groupdel "$groupe"
            echo "Le groupe $groupe a été supprimé car il est vide."
        else
            echo "Le groupe $groupe contient encore des utilisateurs."
        fi
    else
        echo "Le groupe $groupe n'existe pas."
    fi
}

# Menu principal pour gérer les groupes
echo "Gestion des Groupes - Automatisation"
echo "1. Créer un groupe"
echo "2. Ajouter un utilisateur à un groupe"
echo "3. Retirer un utilisateur d'un groupe"
echo "4. Supprimer un groupe vide"
echo "5. Quitter"
read -p "Choisissez une option (1-5) : " choix

# Gestion des options
case $choix in
    1)
        creer_groupe
        ;;
    2)
        ajouter_utilisateur_groupe
        ;;
    3)
        retirer_utilisateur_groupe
        ;;
    4)
        supprimer_groupe
        ;;
    5)
        echo "Quitter..."
        exit 0
        ;;
    *)
        echo "Option non valide"
        ;;
esac

