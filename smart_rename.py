#!/usr/bin/env /home/nobackup/eduard/venv/rename/bin/python3
"""
Einfaches OCR-basiertes Umbenennen ohne Docker
"""
import pytesseract
from pdf2image import convert_from_path
from PIL import Image
import sys
import re
from datetime import datetime
import os
import readline
import magic

umlaut_map = {
    'ä': 'ae', 'ö': 'oe', 'ü': 'ue',
    'Ä': 'Ae', 'Ö': 'Oe', 'Ü': 'Ue',
    'ß': 'ss'
}

def input_with_prefill(prompt, text=''):
    """Input mit vorausgefülltem Text, der editiert werden kann"""
    def hook():
        readline.insert_text(text)
        # readline.redisplay()  # <- Diese Zeile entfernen!
    readline.set_startup_hook(hook)
    try:
        result = input(prompt)
    finally:
        readline.set_startup_hook()
    return result

def smart_rename(filepath):
    for umlaut, replacement in umlaut_map.items():
        ftitle = filepath.replace(umlaut, replacement)
    # Dann alle Nicht-Wort-Zeichen (außer Leerzeichen und Bindestrich) entfernen
    ftitle, ext = os.path.splitext(ftitle)
    ftitle = re.sub(r'[^\w\s-]', '', ftitle)

    if magic.detect_from_filename(filepath).mime_type == "application/pdf":
        ext = ".pdf"

    # Mehrfache Leerzeichen durch einzelnen Bindestrich ersetzen
    ftitle = re.sub(r'\s+', '-', ftitle).strip('-')

    date_pattern=r'^(\d{2})(\d{2})(\d{2})'
    date_match=re.search(date_pattern,ftitle)
    if len(ftitle) > 6 and len(ext) > 0 and ftitle[6] in "-_" and date_match:
        year,month,day = date_match.groups()
        year = f"20{year}"
        date_str = f"{year}-{month}-{day}"
        fname = f"{date_str}-{ftitle[7:]}{ext.lower()}"
    else:
        fname = None

    # PDF → Bild
    if ext == '.pdf':
        images = convert_from_path(filepath, first_page=1, last_page=1, dpi=300)
        image = images[0]
    else:
        if magic.detect_from_filename(filepath).mime_type[:5] == "image":
            image = Image.open(filepath)

    if not (ext == '.pdf' or magic.detect_from_filename(filepath).mime_type[:5] == "image"):
        return None, fname
    
    # OCR
    text = pytesseract.image_to_string(image, lang='deu')
    
    # Datum finden

    date_pattern = r'(\d{2})[./](\d{2})[./](\d{4})'
    date_match = re.search(date_pattern, text)
    
    if date_match:
        day, month, year = date_match.groups()
        date_str = f"{year}-{month}-{day}"
    else:
        date_str = datetime.now().strftime("%Y-%m-%d")
    
    # Titel extrahieren (erste aussagekräftige Zeile)
    lines = [l.strip() for l in text.split('\n') if len(l.strip()) > 15]
    title = lines[0][:60] if lines else "Dokument"
    
    # Bereinigen
    for umlaut, replacement in umlaut_map.items():
        title = title.replace(umlaut, replacement)
    title = re.sub(r'[^\w\s-]', '', title)
    title = re.sub(r'\s+', '-', title).strip('-')
    
    # Neuer Dateiname
    ext = os.path.splitext(filepath)[1]
    if re.match("^[0-9][0-9][0-9][0-9][0-9][0-9]-",title):
        new_name = f"{title}{ext.lower()}"
    else:
        new_name = f"{date_str}-{title}{ext.lower()}"
    
    return new_name, fname

if __name__ == "__main__":
    new_name = None
    if len(sys.argv) < 2:
        print("Usage: ./smart_rename.py dokument.pdf")
        sys.exit(1)
    
    filepath = sys.argv[1]
    suggested_name, new_file_path = smart_rename(filepath)
    
    print(f"Alt: {filepath}")
    if suggested_name:
        print(f"Vorschlag 1: {suggested_name}")
    if new_file_path:
        print(f"Vorschlag 2: {new_file_path}")
    if suggested_name or new_file_path:
        action = input("(j/n/1/(2)):") 
        if action.lower() == '1':
            # Nutzer kann den vorgeschlagenen Namen editieren
            new_name = input_with_prefill("Neuer Name (editierbar): ", suggested_name)
        elif new_file_path and action.lower() == '2':
            new_name = input_with_prefill("Neuer Name (editierbar): ", new_file_path)
        elif action.lower() == 'j':
            new_name = suggested_name

    # Prüfen ob sich etwas geändert hat
    if new_name and new_name != filepath:
        try:
            os.rename(filepath, new_name)
            print("✓ Umbenannt!")
        except OSError as e:
            print(f"✗ Fehler beim Umbenennen: {e}")
    else:
        print(f"Keine Änderung vorgenommen (Filetype: {magic.detect_from_filename(filepath).mime_type}).")
