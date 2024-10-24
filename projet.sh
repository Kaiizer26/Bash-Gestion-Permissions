#!/bin/bash

# Variables
liste_utilisateur="utilisateurs.txt"

# Partie 1.
# Fonction d'ajout ou modification d'utilisateur

ajouter_modifier_utilisateur(){
    local utilisateur=$1
    local groupe=$2
    local shell=$3
    local repertoire=$4

    if id "$utilisateur" &>/dev/null; then
        echo "L'utilisateur $utilisateur existe déjà. Modification des informations."
        sudo usermod -g "$groupe" -s "$shell" -d "$repertoire" "$utilisateur" &>/dev/null;
        if [ $? -eq 0 ]; then
            echo "Les informations de l'utilisateur $utilisateur ont bien été modifiées."
        else
            echo "Une erreur est survenue lors de la modification des informations de l'utilisateur $utilisateur."
        fi
    else
        echo "Ajout de l'utilisateur $utilisateur."
        sudo useradd -g "$groupe" -s "$shell" -d "$repertoire" -m "$utilisateur"
        if [ $? -eq 0 ]; then
            echo "L'utilisateur $utilisateur a été ajouté avec succès."
        else
            echo "Echec de l'ajout de l'utilisateur $utilisateur."
        fi

        mot_de_passe=$(openssl rand -base64 12)
        echo "Nom d'utilisateur : $utilisateur | Mot de passe : $mot_de_passe"
        echo "$utilisateur:$mot_de_passe" | sudo chpasswd
        sudo chage -d 0 "$utilisateur"
        echo "L'utilisateur $utilisateur devra définir un nouveau mot de passe lors de sa prochaine connexion."
    fi

}

# Partie 2
backup_home_directory() {
    user=$1
    if [ ! -d "/backup" ]; then
        sudo mkdir /backup
        echo "Répertoire de sauvegarde /backup créé."
    fi
    if [ -d "/home/$user" ]; then
        echo "Sauvegarde du répertoire personnel de l'utilisateur $user..."
        tar -czf "/backup/$user-home-$(date +%Y%m%d).tar.gz" "/home/$user"
        echo "Sauvegarde terminée : /backup/$user-home-$(date +%Y%m%d).tar.gz"
    else
        echo "Répertoire personnel de l'utilisateur $user introuvable."
    fi
}
# Fonction de gestion des utilisateurs inactifs
gestion_user_inactif(){
    inactive_users=$(lastlog | grep "Never logged in" | awk '{print $1}')
    for user in $inactive_users; do
        echo "L'utilisateur $user ne s'est jamais connecté."
    echo "ALERTE : L'utilisateur $user est inactif."
        # Proposer des options à l'administrateur
        echo "Que souhaitez-vous faire avec le compte de $user ?"
        echo "1) Verrouiller le compte"
        echo "2) Supprimer le compte"
        echo "3) Ne rien faire"
        read -p "Entrez votre choix (1, 2, 3) : " choice

        case $choice in
            1)
                # Verrouiller le compte
                sudo usermod -L $user
                echo "Le compte de l'utilisateur $user a été verrouillé."
                ;;
            2)
                # Sauvegarder le répertoire personnel avant suppression
                backup_home_directory $user

                # Supprimer le compte
                sudo userdel $user
                echo "Le compte de l'utilisateur $user a été supprimé."
                ;;
            3)
                echo "Aucune action n'a été effectuée pour $user."
                ;;
            *)
                echo "Choix invalide. Aucune action n'a été effectuée pour $user."
                ;;
        esac
    done
}

# Partie 3.
# Fonctions de gestion des groupes
creer_groupe() {
    # Demander à l'utilisateur d'entrer un nom de groupe
    echo "Entrez le nom du groupe à créer :"
    read groupe

    # Vérifier si le groupe existe déjà
    if getent group "$groupe" &>/dev/null; then
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
    if getent group "$groupe" &>/dev/null; then
        gid=$(getent group "$groupe" | cut -d: -f3)  # Récupérer le GID du groupe
        # Vérifie si aucun user n'a ce gid en tant qu'id de groupe dans passwd et si c'est le cas :
        if [ -z "$(getent passwd | awk -F: -v gid="$gid" '$4 == gid')" ]; then
            sudo groupdel "$groupe"
            echo "Le groupe $groupe a été supprimé car il est vide."
        else
            echo "Le groupe $groupe contient encore des utilisateurs."
        fi
    else
        echo "Le groupe $groupe n'existe pas."
    fi
}

# Partie 4.
# Fonction pour gérer les ACL sur des répertoires partagés
gerer_acl() {
    echo "Entrez le répertoire pour lequel vous souhaitez configurer les ACL :"
    read repertoire

    # Vérifier si le répertoire existe
    # -d vérifie si le chemin est un répertoire
    if [ -d "$repertoire" ]; then
        echo "1. Ajouter une ACL pour un utilisateur ou un groupe"
        echo "2. Supprimer une ACL pour un utilisateur ou un groupe"
        echo "3. Afficher les ACL actuelles"
        read -p "Choisissez une option (1-3) : " choix_acl
        # Access control list : donner des perm avancées
        # chmod en plus poussé
        case $choix_acl in
            1)
                echo "Voulez-vous ajouter une ACL pour un utilisateur ou un groupe ? (u/g)"
                read type_entite
                echo "Entrez le nom de l'utilisateur ou du groupe :"
                read entite
                echo "Entrez les permissions (r pour lecture, w pour écriture, x pour exécution) :"
                read permissions

                if [[ "$type_entite" == "u" ]]; then
                    # setfacl : permet de définir les permissions, -m permet de modifier
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
                    # -x : pour supprimer
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
                # getfacl : voir les perm d'un repertoire
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
            # -d -m: modifier les acl par défaut des prochains fichiers
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

# Menu principal
echo "Gestion des utilisateurs et des groupes"
echo "1. Ajouter ou modifier un utilisateur"
echo "2. Gérer les utilisateurs inactifs et faire une sauvegarde"
echo "3. Créer un groupe"
echo "4. Ajouter un utilisateur à un groupe"
echo "5. Retirer un utilisateur d'un groupe"
echo "6. Supprimer un groupe"
echo "7. Configurer les ACL sur un répertoire"
echo "8. Appliquer des ACL par défaut pour les nouveaux fichiers"
echo "9. Quitter"
read -p "Choisissez une option (1-9) : " choix

case $choix in
    1)
        while IFS=":" read -r utilisateur groupe shell repertoire; do
            ajouter_modifier_utilisateur "$utilisateur" "$groupe" "$shell" "$repertoire"
        done < "$liste_utilisateur"
        ;;
    2)
        gestion_user_inactif
        ;;
    3)
        creer_groupe
        ;;
    4)
        ajouter_utilisateur_groupe
        ;;
    5)
        retirer_utilisateur_groupe
        ;;
    6)
        supprimer_groupe
        ;;
        
    7)
        gerer_acl
        ;;
    8)
        appliquer_acl_defaut
        ;;
    9)
        echo "Quitter..."
        exit 0
        ;;
    *)
        echo "Option non valide"
        ;;
esac


