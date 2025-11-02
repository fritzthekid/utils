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

def xxx_input_with_prefill(prompt, text=''):
    """Input mit vorausgefülltem Text, der editiert werden kann"""
    def hook():
        readline.insert_text(text)
        readline.redisplay()
    readline.set_startup_hook(hook)
    try:
        result = input(prompt)
    finally:
        readline.set_startup_hook()
    return result

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
    # PDF → Bild
    if filepath.lower().endswith('.pdf'):
        images = convert_from_path(filepath, first_page=1, last_page=1, dpi=300)
        image = images[0]
    else:
        image = Image.open(filepath)
    
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
    title = re.sub(r'[^\w\säöüÄÖÜß-]', '', title)
    title = re.sub(r'\s+', '-', title).strip('-')
    
    # Neuer Dateiname
    ext = os.path.splitext(filepath)[1]
    if re.match("^[0-9][0-9][0-9][0-9][0-9][0-9]-",title):
        new_name = f"{title}{ext}"
    else:
        new_name = f"{date_str}-{title}{ext}"
    
    return new_name

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./smart_rename.py dokument.pdf")
        sys.exit(1)
    
    filepath = sys.argv[1]
    suggested_name = smart_rename(filepath)
    
    print(f"Alt: {filepath}")
    print(f"Vorschlag: {suggested_name}")
    action = input("(j/n/e):") # print()

    if action.lower() == 'e':
        # Nutzer kann den vorgeschlagenen Namen editieren
        new_name = input_with_prefill("Neuer Name (editierbar): ", suggested_name)
    elif action.lower() == 'j':
        new_name = suggested_name
    elif action.lower() == 'n':
        new_name = None

    # Prüfen ob sich etwas geändert hat
    if new_name and new_name != filepath:
        try:
            os.rename(filepath, new_name)
            print("✓ Umbenannt!")
        except OSError as e:
            print(f"✗ Fehler beim Umbenennen: {e}")
    else:
        print("Keine Änderung vorgenommen.")
