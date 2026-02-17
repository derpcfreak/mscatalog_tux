#!/bin/bash
#
# Microsoft Windows Driver Downloader for Linux
# ===========================================
# Automatically detects Ethernet (02:00) and Mass Storage (01:*) PCI devices,
# searches Microsoft Update Catalog for matching CAB driver packages using
# progressive device ID matching (full → trimmed → minimal), downloads unique
# CAB files to current directory, extracts them into versioned folders, and
# deletes the original CABs after successful extraction.
#
# Requires: curl/wget, cabextract
# External functions (from ./functions.include):
#   - get_pci_by_class <class> <subclass>  # Returns PCI device lines by class
#   - updates_page1 <device_id>           # Searches MS catalog, returns update IDs
#   - get_update_details <update_id>      # Gets detailed info for update ID
#   - get_update_link <update_id>         # Extracts download URL from update details
#

# are we root?
if [ $(id -u) -ne 0 ]; then
  echo "Please run this script as root or using sudo!"
  echo "running without sudo is possible if you remove the relevant 'dmidecode' commands"
  echo "and specify DOWNLOAD_DIR by yourself."
  exit
fi
# Remainder of script goes below this line


# List of required commands
required_cmds=(curl wget cabextract dmidecode)

missing=()

# Check for missing required commands
for cmd in "${required_cmds[@]}"; do
 if ! command -v "$cmd" &>/dev/null; then
  missing+=("$cmd")
 fi
done

if [ ! ${#missing[@]} -eq 0 ]; then
 echo "Missing tools: ${missing[*]}"
 echo "Please install them before running this script."
 exit 1
fi

# Directory for temporary CAB file downloads (files deleted after extraction)
#DOWNLOAD_DIR='.'
# Check if $1 exists (non-empty)
if [[ -n "$1" ]]; then
    DOWNLOAD_DIR="$1"
else
# next line requires sudo or root privileges
    DOWNLOAD_DIR=$(echo "$(dmidecode -s system-manufacturer)"_"$(dmidecode -s system-product-name)"_"$(dmidecode -s system-version)" | sed -E 's/[[:space:]]+/_/g' | sed 's@[`´,;ß:?-\<\>\.#+°()!\"§\$\%\&\/\=-]@_@g' | awk '{ print toupper($0) }' | sed 's@Ä@AE@g' | sed 's@Ö@OE@g' | sed 's@Ü@UE@g')
fi

echo "DOWNLOAD_DIR: $DOWNLOAD_DIR"


# Source helper functions
source ./functions.include

# Arrays to store devices, update IDs, and details
declare -a devices
devices=()
declare -a all_update_ids
all_update_ids=()
#declare -a update_details
#update_details=()
# Collect unique PCI devices: Ethernet (class 02:00) and Mass Storage (class 01:*)
while IFS= read -r deviceline; do
    echo "deviceline: $deviceline"
    devices+=("$deviceline")
done < <( { get_pci_by_class 02 '*' 1; get_pci_by_class 01 '*' 1; get_pci_by_class 0c '*' 1; } | awk '!seen[$0]++' )
declare -p devices # show content of array
#####################################################################
# Search Microsoft Update Catalog for matching drivers (first page only)
#####################################################################
for array_id in "${!devices[@]}"; do
 deviceclassline=${devices[$array_id]}
 echo "# Working on devices[$array_id]: $deviceclassline"
 
 # Strategy 1: Try full device ID
 echo "# → 1. Full device ID: $deviceclassline"
 update_ids=$(updates_page1 "$deviceclassline")
 if [ $? -eq 0 ] && [ -n "$update_ids" ]; then
  echo "[  OK  ] → 1 Update ID(s) found for full device ID: $deviceclassline"
  while read -r line; do
   all_update_ids+=("$line")
  done < <(updates_page1 "$deviceclassline" | awk '!seen[$0]++')
  continue
 else
  echo "[INFO] → 1 No update ID found for full device ID: $deviceclassline"
 fi
 
 # Strategy 2: Remove last segment (e.g., &REV_XX)
 trimmed_last="${deviceclassline%&*}"
 echo "# → 2. Trimmed (no &REV): $trimmed_last"
 update_ids=$(updates_page1 "$trimmed_last")
 if [ $? -eq 0 ] && [ -n "$update_ids" ]; then
  echo "[  OK  ] → 2 Update ID(s) found for trimmed device ID: $trimmed_last"
  while read -r line; do
   all_update_ids+=("$line")
  done < <(updates_page1 "$trimmed_last" | awk '!seen[$0]++')
  continue
 else
  echo "[INFO] → 2 No update ID found for trimmed device ID: $trimmed_last"
 fi
 
 # Strategy 3: Remove all segments after DEV (just BUS\VEN_XXXX&DEV_XXXX)
 trimmed_last="${trimmed_last%&*}"
 echo "# → 3. Minimal (VEN+DEV only): $trimmed_last"
 update_ids=$(updates_page1 "$trimmed_last")
 if [ $? -eq 0 ] && [ -n "$update_ids" ]; then
  echo "[  OK  ] → 3 Update ID(s) found for minimal device ID: $trimmed_last"
  while read -r line; do
   all_update_ids+=("$line")
  done < <(updates_page1 "$trimmed_last" | awk '!seen[$0]++')
  continue
 else
  echo "[INFO] → 3 No update ID found for minimal device ID: $trimmed_last"
 fi
 echo "# ------------------------------------------------------"
done

# Get unique download links from best-matching update details
echo "PROCESSING FINAL LINK(S)"
unique_links=()
declare -A seen
for id in "${all_update_ids[@]}"; do
  first_line=$(get_update_details "$id" | head -n 1)
  update_id=$(echo "$first_line" | awk -F '|' '{print $1}')
  link=$(get_update_link "$update_id")
  # progress
  echo "  got link for $update_id: $link"
  # de-duplicate
  if [[ -n $link && -z ${seen["$link"]} ]]; then
    seen["$link"]=1
    unique_links+=("$link")
  fi
done

#####################################################################
# Download CAB files to temporary directory
#####################################################################
echo "DOWNLOADING FINAL LINK(S)"
for link in "${unique_links[@]}"; do
 echo "Downloading: $link"
 #wget -N -P "$DOWNLOAD_DIR" "$link" # with output
 wget -q -N -P "$DOWNLOAD_DIR" "$link" # quiet
done

#####################################################################
# Extract CAB files and clean up
#####################################################################
# Process all .cab files (handles spaces/newlines safely)
find "$DOWNLOAD_DIR" -type f \( -iname '*.cab' \) -print0 |
while IFS= read -r -d '' cab; do
 base="$(basename "$cab")"
 folder="${base%.[cC][aA][bB]}"  # Strip .cab/.CAB extension
 out_dir="$(dirname "$cab")/$folder"

 echo "➡️  Extracting: $base → $out_dir"
 mkdir -p -- "$out_dir"

 if cabextract -q -d "$out_dir" -- "$cab"; then
  echo "✓ Extracted successfully. Deleting: $cab"
  rm -f -- "$cab"
 else
  echo "✗ Extraction failed: $cab (kept for inspection)"
 fi
done
