#!/bin/bash

while IFS=";" read -r line; do
    # Ignorer la première ligne (en-tête)
    if [ "$line" != "nom;name_alias;ref_ext;code_client;" ]; then
        # Découper la ligne en champs en utilisant le délimiteur ';'
        IFS=";" read -r nom name_alias ref_ext code_client _ <<< "$line"
        

        mysql -u dolibarr -p'dolibarr' -h 127.0.0.1 --port=3306 dolibarr << EOF
        INSERT INTO llx_societe (nom, name_alias, ref_ext, code_client)
        VALUES ('$nom', '$name_alias', '$ref_ext', '$code_client');
EOF
    fi
done < "CSV/donnees.csv"

