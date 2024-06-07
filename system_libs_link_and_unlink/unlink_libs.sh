#!/bin/bash

set -e

FLAG_FILE="/var/lib/libs_linked.flag"

delete_flag_file() {
  rm "$FLAG_FILE"
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# Check if the flag file exists
if [[ ! -f "$FLAG_FILE" ]]; then
  echo "Error: Libraries are not linked." >&2
  exit 1
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

# Restore original libraries from backup
for full_lib_path in "$SYSTEM_LIBS_PATH"/*; do
  lib=$(basename "$full_lib_path")
  
  # Remove the symbolic link from /usr/lib
  if [[ -L "/usr/lib/$lib" ]]; then
    if rm "/usr/lib/$lib"; then
      echo "Removed symbolic link /usr/lib/$lib."
    else
      echo "Failed to remove /usr/lib/$lib." >&2
    fi
  fi

  # Check if the backup exists
  if [[ -e "/usr/lib/lib_bkp/$lib" || -L "/usr/lib/lib_bkp/$lib" ]]; then
    # Move the backup back to its original location
    if mv "/usr/lib/lib_bkp/$lib" "/usr/lib/$lib"; then
      echo "Restored /usr/lib/$lib from backup."
    else
      echo "Failed to restore /usr/lib/$lib from backup." >&2
    fi
  else
    echo "No backup found for /usr/lib/$lib."
  fi
done

echo "Libraries have been restored to their original versions."

delete_flag_file