#!/usr/bin/env /home/nobackup/eduard/venv/rename/bin/python3
"""
Einfaches OCR-basiertes Umbenennen ohne Docker
"""
import pytesseract
from pdf2image import convert_from_path
from PIL import Image
from PyPDF3 import PdfFileReader # pip install pypdf3
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

def get_info(path):
    with open(path, 'rb') as f:
        pdf = PdfFileReader(f)
        info = pdf.getDocumentInfo()
    return info

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
    date_str = os.path.getmtime(filepath)
    dokument_title = os.path.basename(os.path.splitext(filepath)[0])
    ftitle = dokument_title
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
        fdate_str = f"{year}-{month}-{day}"
        fname = f"{fdate_str}-{ftitle[7:]}{ext.lower()}"
    else:
        fname = None

    # PDF → Bild
    if ext == '.pdf':
        try:
            date_string = get_info(filepath)["/CreationDate"]
            year, month, day = re.search(r'D:(\d{4})(\d{2})(\d{2})', date_string).groups()
            date_str = f"{year}-{month}-{day}"
        except:
            pass
        images = convert_from_path(filepath, first_page=1, last_page=1, dpi=300)
        image = images[0]
    else:
        if magic.detect_from_filename(filepath).mime_type[:5] == "image":
            image = Image.open(filepath)
            info = image._getexif()
            if 36868 in info:
                date_str = re.sub(":","-",info[36868][:10])
                document_title = re.sub(":","",info[36868][11:])
            # exif_date = image._getexif()[36868]
            # if re.match("^[0-9][0-9][0-9][0-9]:[0-9][0-9]:[0-9][0-9]...",exif_date):
            #     date_str = re.sub(":","-",image._getexif()[36868][:10])

    if not (ext == '.pdf' or magic.detect_from_filename(filepath).mime_type[:5] == "image"):
        return None, fname, ext
    
    # OCR
    text = pytesseract.image_to_string(image, lang='deu')
    
    # Datum finden

    date_pattern = r'(\d{2})[./](\d{2})[./](\d{4})'
    date_match = re.search(date_pattern, text)
    
    if date_match:
        day, month, year = date_match.groups()
        date_str = f"{year}-{month}-{day}"
    
    # Titel extrahieren (erste aussagekräftige Zeile)
    lines = [l.strip() for l in text.split('\n') if len(l.strip()) > 15]
    title = lines[0][:60] if lines else document_title
    
    # Bereinigen
    for umlaut, replacement in umlaut_map.items():
        title = title.replace(umlaut, replacement)
    title = re.sub(r'[^\w\s-]', '', title)
    title = re.sub(r'\s+', '-', title).strip('-')
    
    new_name = f"{date_str}-{title}{ext.lower()}"
    
    return new_name, fname, ext


def main(argv):
    new_name = None

    if len(argv) < 2:
        print("Usage: ./smart_rename.py dokument.pdf")
        sys.exit(1)

    filepath = argv[1]
    if not os.path.isfile(filepath):
        print(f"File not found: {filepath}")
        sys.exit(1)

    suggested_name, new_file_path, ext = smart_rename(filepath)
    
    print(f"Alt: {filepath}")
    action_type = "n"
    # if suggested_name:
    #     print(f"Vorschlag 1: {suggested_name}")
    # if new_file_path:
    #     print(f"Vorschlag 2: {new_file_path}")
    if suggested_name and new_file_path:
        print(f"Vorschlag 1: {suggested_name}")
        print(f"Vorschlag 2: {new_file_path}")
        action = input("(1/2/n):") 
        action_type = action
    elif suggested_name and not new_file_path:
        print(f"Vorschlag: {suggested_name}")
        action = input("(n/j):")
        if action == "j":
            action_type = "1"
    elif not suggested_name and new_file_path:
        print(f"Vorschlag: {new_file_path}")
        action = input("(n/j)")
        if action == "j":
            action_type = "2"
                        
    if "1" in action_type:
        new_name = input_with_prefill("Neuer Name: ", f"{os.path.dirname(filepath)}/{suggested_name}")
    elif "2" in action_type:
        new_name = input_with_prefill("Neuer Name: ", f"{os.path.dirname(filepath)}/{new_file_path}")

    # Prüfen ob sich etwas geändert hat
    if new_name and new_name != filepath:
        try:
            if os.path.isfile(f"{new_name}"):
                action = input(f"file already exists: {new_name}, rename anyway? (j/n): ")
                if action != "j":
                    print("Abbruch")
                    sys.exit(1)
            os.rename(filepath, f"{new_name}")
            print("✓ Umbenannt!")
        except OSError as e:
            print(f"✗ Fehler beim Umbenennen: {e}")
    else:
        print(f"Keine Änderung vorgenommen (Filetype: {magic.detect_from_filename(filepath).mime_type}).")

if __name__ == "__main__":
    main(sys.argv)
