#!/bin/bash

rename_files() {
    local directory=$1
    for file_path in "$directory"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
        if [[ -f "$file_path" ]]; then
            date_taken=$(jhead "$file_path" | grep "Date/Time" | awk '{print $3"_"$4}' | sed 's/:/_/g')
            camera_model=$(jhead "$file_path" | grep "Camera model" | awk -F': ' '{print $2}' | tr ' ' '_')
            
            if [[ -z "$date_taken" ]]; then
                date_taken=$(stat -c %y "$file_path" | awk '{print $1"_"$2}' | sed 's/[-:]//g' | sed 's/\..*//')
            fi
            
            if [[ -n "$date_taken" ]]; then
                date_taken=$(date -d "${date_taken//_/ }" +"%y%m%d_%H%M%S" 2>/dev/null)
                if [[ -z "$date_taken" ]]; then
                    date_taken=$(stat -c %y "$file_path" | awk '{print $1"_"$2}' | sed 's/[-:]//g' | sed 's/\..*//')
                fi
                if [[ -z "$camera_model" ]]; then
                    camera_model="Unknown_Camera"
                fi
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
