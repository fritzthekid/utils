#!/bin/bash

rename_files() {
    local directory=$1
    for file_path in "$directory"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
        if [[ -f "$file_path" ]]; then
            date_taken=$(exiftool -DateTimeOriginal -d "%Y%m%d_%H%M%S" "$file_path" | awk -F': ' '{print $2}')
            camera_model=$(exiftool -Model "$file_path" | awk -F': ' '{print $2}' | tr ' ' '_')
            
            if [[ -n "$date_taken" && -n "$camera_model" ]]; then
                new_filename="${date_taken}_${camera_model}.jpg"
                new_file_path="$directory/$new_filename"
                
                mv "$file_path" "$new_file_path"
                echo "Renamed $(basename "$file_path") to $new_filename"
            fi
        fi
    done
}

read -p "Enter the directory path: " directory
rename_files "$directory"
