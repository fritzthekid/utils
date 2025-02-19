#!/bin/bash

# Ersetzungszeichen für problematische Zeichen
REPLACEMENT="_"

# Funktion zum sicheren Umbenennen von Dateien
sanitize_filename() {
    echo "$1" | sed -e "s/ /$REPLACEMENT/g" \
                    -e "s/(/$REPLACEMENT/g" \
                    -e "s/)/$REPLACEMENT/g" \
                    -e "s/\[/$REPLACEMENT/g" \
                    -e "s/\]/$REPLACEMENT/g" \
                    -e "s/{/$REPLACEMENT/g" \
                    -e "s/}/$REPLACEMENT/g" \
                    -e "s/,/$REPLACEMENT/g" \
                    -e "s/;/$REPLACEMENT/g" \
                    -e "s/:/$REPLACEMENT/g" \
                    -e "s/\?/$REPLACEMENT/g" \
                    -e "s/\*/star/g" \
                    -e "s/+/$REPLACEMENT/g" \
                    -e "s/=/$REPLACEMENT/g" \
                    -e "s/</$REPLACEMENT/g" \
                    -e "s/>/$REPLACEMENT/g" \
                    -e "s/|/$REPLACEMENT/g" \
                    -e "s/!/$REPLACEMENT/g" #\
                    }
#                     -e "s/'/-/g" \
#                     -e "s/\"/-/g" \
#                     -e "s/@/-/g" \
#                     -e "s/&/and/g" \
#                     -e "s/\$/dollar/g" \
#                     -e "s/%/percent/g" # \
# }
#                    -e "s/#/number/g" \
#                     -e "s/\\/$REPLACEMENT/g"
# }

# find-Befehl mit UTF-8 Unterstützung
find . -depth | while IFS= read -r file; do
    # Konvertiere den Dateinamen in eine sichere UTF-8 Zeichenkette
    new_name=$(sanitize_filename "$file")

    # Falls der Name sich geändert hat, umbenennen
    if [[ "$file" != "$new_name" ]]; then
        if [ -e "$new_name" ]; then
            echo "Zielname existiert bereits: $new_name"
        else
            mv -- "$file" "$new_name"
            echo "Umbenannt: $file -> $new_name"
        fi
    fi
done
