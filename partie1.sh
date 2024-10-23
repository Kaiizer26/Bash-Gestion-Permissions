#!/bin/bash

liste_utilisateurs="utilisateurs.txt"

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
#Lecture de la liste des utilisateurs ligne par ligne et appel de la fonction
while IFS=":" read -r utilisateur groupe shell repertoire
#IFS=":" permet de séparer les informations la ligne quand il y a ":", on aura quatre parties du coup : nom d'utilisateur, groupe, shell et repertoire
#Les 4 variables permettent de prendre l'information chaque partie séparée
#ex : john_pork:RH:/bin/bash:/home/john_pork
# => utilisateur= john_pork
# etc etc
# -r empêche que les antislash soient interprétés comme des caractères d'échappement
do
	ajouter_modifier_utilisateur "$utilisateur" "$groupe" "$shell" "$repertoire"
done < "$liste_utilisateurs"

# landy@VictusLandy:~/unix$ id -a jordy
# uid=1007(jordy) gid=1008(Marketing) groups=1008(Marketing)
# landy@VictusLandy:~/unix$ groups jordy
# jordy : Marketing