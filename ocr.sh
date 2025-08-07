#!/bin/bash

# --- Default-Werte ---
lang="deu"

# --- Optionen parsen ---
while [[ "$1" == -* ]]; do
    case "$1" in
        -l) lang="$2"; shift 2 ;;
        *) echo "Unbekannte Option: $1"; exit 1 ;;
    esac
done

# --- Argumente prüfen ---
if [[ $# -ne 2 ]]; then
    echo "Verwendung: $(basename $0) [-l lang] <infile.pdf> <outfile.{pdf|txt}>"
    exit 1
fi

infile="$1"
outfile="$2"
ext="${outfile##*.}"

# --- Dateityp prüfen ---
if [[ ! -f "$infile" ]]; then
    echo "Eingabedatei '$infile' existiert nicht."
    exit 1
fi

# --- Verarbeitung starten ---
case "$ext" in
    pdf)
        echo "[Info] Erzeuge durchsuchbares PDF..."
        ocrmypdf -l "$lang" --optimize 1 --skip-text "$infile" "$outfile"
        ;;
    txt)
        echo "[Info] Erzeuge durchsuchbares PDF + Textausgabe..."
        tmp_pdf="$(mktemp --suffix=.pdf)"
        ocrmypdf -l "$lang" --optimize 1 --skip-text "$infile" "$tmp_pdf" \
            && pdftotext "$tmp_pdf" "$outfile" \
            && rm -f "$tmp_pdf"
        ;;
    *)
        echo "Unbekanntes Ausgabeformat: .$ext – nur .pdf oder .txt erlaubt."
        exit 1
        ;;
esac
