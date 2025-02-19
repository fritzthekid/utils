#!/bin/bash

REPLACEMENT="_"  # Ersetzungszeichen für Leerzeichen

# find-Befehl mit UTF-8 Unterstützung
find . -depth -name "* *" | while IFS= read -r file; do
    # Konvertiere den Dateinamen in eine sichere UTF-8 Zeichenkette
    new_name=$(echo "$file" | sed -e "s/ /$REPLACEMENT/g")

    # Falls der Name sich geändert hat, umbenennen
    if [[ "$file" != "$new_name" ]]; then
        mv -- "$file" "$new_name"
        echo "Umbenannt: $file -> $new_name"
    fi
done
