#!/bin/bash

set -e

FLAG_FILE="/var/lib/libs_linked.flag"

create_flag_file() {
  touch "$FLAG_FILE"
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# Check if the flag file exists
if [[ -f "$FLAG_FILE" ]]; then
  echo "Error: Libraries have already been linked." >&2
  exit 0
fi

# Check if the path argument is provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 --path /path/to/system_libs" >&2
    exit 1
fi

# Parse the argument to get the path to system_libs
for i in "$@"; do
  case $i in
    --path)
    SYSTEM_LIBS_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    *)
    # unknown option
    ;;
  esac
done

# Ensure the path is not empty and exists
if [[ -z "$SYSTEM_LIBS_PATH" ]] || [[ ! -d "$SYSTEM_LIBS_PATH" ]]; then
    echo "Error: Invalid path ($SYSTEM_LIBS_PATH)." >&2
    exit 1
fi

# Convert to absolute path
SYSTEM_LIBS_PATH=$(realpath "$SYSTEM_LIBS_PATH")

# Create a backup directory if it doesn't exist
if [[ ! -d "/usr/lib/lib_bkp" ]]; then
  mkdir "/usr/lib/lib_bkp"
  chmod 755 "/usr/lib/lib_bkp"
fi

# Backup and Link all libraries in the provided path
for full_lib_path in "$SYSTEM_LIBS_PATH"/*; do
  if [[ ! -f "$full_lib_path" ]]; then
    echo "Skipping non-file $full_lib_path"
    continue
  fi

  lib=$(basename "$full_lib_path")
  
  # Check if the target library already exists
  if [[ -e "/usr/lib/$lib" ]]; then
    # Move the existing library to backup
    mv "/usr/lib/$lib" "/usr/lib/lib_bkp/$lib"
    echo "Found existing /usr/lib/$lib. Moved to /usr/lib/lib_bkp/$lib."
  fi
  
  # Create a symbolic link to the new library
  if ln -s "$full_lib_path" "/usr/lib/$lib"; then
    echo "Created symbolic link to $full_lib_path."
  else
    echo "Error creating symbolic link for $full_lib_path." >&2
  fi
done

echo "Libraries have been linked successfully."

create_flag_file