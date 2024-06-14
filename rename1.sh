#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 [-d target_directory] [-a hash_algorithm] [-m mode] [-o operation] [-r recursion] [-t title_option] [-q quiet] [-v version] [-D use_date] [-T use_datetime] [files...]"
    echo "Options:"
    echo "  -d target_directory   Directory to copy/move the files into. If not provided, files are copied/moved into the current directory."
    echo "  -a hash_algorithm     Hash algorithm to use (md5, sha1, sha256). If not provided, no hash is appended."
    echo "  -m mode               Mode to use (auto or manual). Default is auto."
    echo "  -o operation          Operation to perform (copy or move). Default is copy."
    echo "  -r recursion          Recursion mode (1 to enable, 0 to disable). Default is 0."
    echo "  -t title_option       Title option: 'filename' (use original filename) or 'metadata' (use title from metadata). Default is 'filename'."
    echo "  -q quiet              Quiet mode (1 to suppress output, 0 to enable). Default is 0."
    echo "  -v version            Include version in filename (1 to include, 0 to exclude). Default is 1."
    echo "  -D use_date           Include date in filename (1 to include, 0 to exclude). Default is 1."
    echo "  -T use_datetime       Use full datetime in filename (1 to include, 0 to exclude). Default is 0."
    echo "  -h                    Display this help message."
}

# Default values
target_directory="."
hash_algorithm=""
mode="auto"
operation="copy"
recursive_mode=0
title_option="filename"
quiet_mode=0
use_version=1
use_date=1
use_datetime=0

# Parse options
while getopts "d:a:m:o:r:t:q:v:D:T:h" opt; do
    case $opt in
        d) target_directory="$OPTARG" ;;
        a) hash_algorithm="$OPTARG" ;;
        m) mode="$OPTARG" ;;
        o) operation="$OPTARG" ;;
        r) recursive_mode="$OPTARG" ;;
        t) title_option="$OPTARG" ;;
        q) quiet_mode="$OPTARG" ;;
        v) use_version="$OPTARG" ;;
        D) use_date="$OPTARG" ;;
        T) use_datetime="$OPTARG" ;;
        h) show_help; exit 0 ;;
        *) show_help; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

# Function to sanitize filenames
sanitize() {
    local input="$1"
    echo "$input" | tr ' ' '_' | sed 's/[^a-zA-Z0-9._-:]/Z/g'
}

# Function to get file metadata
get_metadata() {
    local file="$1"
    local metadata_title=$(exiftool -Title -s -s -s "$file" 2>/dev/null)
    local metadata_version=$(exiftool -Version -s -s -s "$file" 2>/dev/null)
    local metadata_date=$(exiftool -CreateDate -d "%Y-%m-%d" -s -s -s "$file" 2>/dev/null)
    echo -e "${metadata_title:-}\n${metadata_version:-0}\n${metadata_date:-$(stat -c %y "$file" | cut -d' ' -f1)}"
}

# Function to hash a file
generate_hash() {
    local file="$1"
    local algorithm="$2"
    case "$algorithm" in
        md5) hash=$(md5sum "$file" | awk '{print $1}') ;;
        sha1) hash=$(sha1sum "$file" | awk '{print $1}') ;;
        sha256) hash=$(sha256sum "$file" | awk '{print $1}') ;;
        *) hash="" ;;
    esac
    echo "${hash:0:5}${hash: -5}"
}

# Process files
process_file() {
    local file="$1"
    local target_subdirectory="$2"

    # Skip processing if it is a directory
    if [ -d "$file" ]; then
        return
    fi

    # Get file metadata
    IFS=$'\n' read -r metadata_title metadata_version metadata_date <<< "$(get_metadata "$file")"

    # Get base filename without extension
    local base_filename=$(basename "$file" | sed 's/\.[^.]*$//')
    local file_extension="${file##*.}"

    # Determine title
    local title=""
    if [ "$title_option" == "metadata" ] && [ -n "$metadata_title" ]; then
        title="$metadata_title"
    else
        title="$base_filename"
    fi
    title=$(sanitize "$title")

    # Determine version
    local version=""
    [ "$use_version" -eq 1 ] && version="-v${metadata_version:-0}"

    # Determine date
    local date=""
    if [ "$use_date" -eq 1 ]; then
        if [ "$use_datetime" -eq 1 ]; then
            date=$(stat -c %y "$file" | cut -d'.' -f1 | tr ' ' '-')
        else
            date="${metadata_date:-$(stat -c %y "$file" | cut -d' ' -f1)}"
        fi
    fi

    # Generate hash
    local hash=""
    [ -n "$hash_algorithm" ] && hash=$(generate_hash "$file" "$hash_algorithm")

    # Create new filename
    local new_filename="$title${version}${date:+-$date}${hash:+-$hash}.$file_extension"

    # Manual mode adjustments
    if [ "$mode" == "manual" ]; then
        read -p "Use title '$title'? (Press Enter to confirm or type a new title): " user_title
        [ -n "$user_title" ] && title=$(sanitize "$user_title")
        
        if [ "$use_version" -eq 1 ]; then
            read -p "Use version '${metadata_version:-0}'? (Press Enter to confirm or type a new version): " user_version
            [ -n "$user_version" ] && version="-v$(sanitize "$user_version")"
        fi

        if [ "$use_date" -eq 1 ]; then
            read -p "Use date '$date'? (Press Enter to confirm or type a new date): " user_date
            [ -n "$user_date" ] && date=$(sanitize "$user_date")
        fi
        
        new_filename="$title${version}${date:+-$date}${hash:+-$hash}.$file_extension"
    fi

    # Ensure the target subdirectory exists
    mkdir -p "$target_subdirectory"

    # Check if file already exists
    local target_path="$target_subdirectory/$new_filename"
    if [ -e "$target_path" ]; then
        read -p "File '$target_path' already exists. Overwrite? (Y/n): " overwrite
        [ "$overwrite" == "n" ] && return
    fi

    # Perform copy or move operation
    if [ "$operation" == "move" ]; then
        mv "$file" "$target_path"
        [ "$quiet_mode" -eq 0 ] && echo "Moved '$file' to '$target_path'"
    else
        cp "$file" "$target_path"
        [ "$quiet_mode" -eq 0 ] && echo "Copied '$file' to '$target_path'"
    fi
}

# Recursive function to process directories
process_directory() {
    local dir="$1"
    local target_subdirectory="$2"
    local files=("$dir"/*)
    for file in "${files[@]}"; do
        if [ -d "$file" ]; then
            [ "$recursive_mode" -eq 1 ] && process_directory "$file" "$target_subdirectory/$(basename "$file")"
        else
            process_file "$file" "$target_subdirectory"
        fi
    done
}

# Process each file/directory passed as argument
for path in "$@"; do
    if [ -d "$path" ] && [ "$recursive_mode" -eq 1 ]; then
        process_directory "$path" "$target_directory/$(basename "$path")"
    else
        process_file "$path" "$target_directory"
    fi
done

