#!/bin/bash

# PlayIntegrityFix script modified for Linux PCs
# Original script was for Android devices

# Save the starting directory before changing to temp directory
CURRENT_DIR=$(pwd)
TEMPDIR=$(mktemp -d)
version="1.0"
FORCE_PREVIEW=1

echo "[+] PlayIntegrityFix $version"
echo "[+] $(basename "$0")"
printf "\n\n"

# We'll manually clean up instead of using trap to ensure file is copied first

download_fail() {
    dl_domain=$(echo "$1" | awk -F[/:] '{print $4}')
    echo "$1" | grep -q "\.zip$" && return

    # Clean up on download fail
    rm -rf "$TEMPDIR"

    if ! ping -c 1 -W 5 "$dl_domain" > /dev/null 2>&1; then
        echo "[!] Unable to connect to $dl_domain, please check your internet connection and try again"
        exit 1
    fi

    echo "[!] download failed!"
    echo "[x] bailing out!"
    exit 1
}

# Use the appropriate download tool based on availability
if command -v curl > /dev/null 2>&1; then
    download() {
        if ! curl --connect-timeout 10 -s "$1" > "$2"; then
            download_fail "$1"
        fi
    }
else
    # Fallback to wget if curl is not available
    download() {
        if ! wget -T 10 --no-check-certificate -qO - "$1" > "$2"; then
            download_fail "$1"
        fi
    }
fi

set_random_beta() {
    if [ "$(echo "$MODEL_LIST" | wc -l)" -ne "$(echo "$PRODUCT_LIST" | wc -l)" ]; then
        echo "Error: MODEL_LIST and PRODUCT_LIST have different lengths."
        exit 1
    fi
    count=$(echo "$MODEL_LIST" | wc -l)
    rand_index=$(( $$ % count ))
    MODEL=$(echo "$MODEL_LIST" | sed -n "$((rand_index + 1))p")
    PRODUCT=$(echo "$PRODUCT_LIST" | sed -n "$((rand_index + 1))p")
}

cd "$TEMPDIR"

# Get latest Pixel Beta information
echo "- Downloading Pixel version information..."
download https://developer.android.com/about/versions PIXEL_VERSIONS_HTML
BETA_URL=$(grep -o 'https://developer.android.com/about/versions/.*[0-9]"' PIXEL_VERSIONS_HTML | sort -ru | cut -d\" -f1 | head -n1)
download "$BETA_URL" PIXEL_LATEST_HTML

# Handle Developer Preview vs Beta
if grep -qE 'Developer Preview|tooltip>.*preview program' PIXEL_LATEST_HTML && [ "$FORCE_PREVIEW" = 0 ]; then
    # Use the second latest version for beta
    BETA_URL=$(grep -o 'https://developer.android.com/about/versions/.*[0-9]"' PIXEL_VERSIONS_HTML | sort -ru | cut -d\" -f1 | head -n2 | tail -n1)
    download "$BETA_URL" PIXEL_BETA_HTML
else
    mv -f PIXEL_LATEST_HTML PIXEL_BETA_HTML
fi

# Get OTA information
OTA_URL="https://developer.android.com$(grep -o 'href=".*download-ota.*"' PIXEL_BETA_HTML | cut -d\" -f2 | head -n1)"
download "$OTA_URL" PIXEL_OTA_HTML

# Extract device information
MODEL_LIST="$(grep -A1 'tr id=' PIXEL_OTA_HTML | grep 'td' | sed 's;.*<td>\(.*\)</td>;\1;')"
PRODUCT_LIST="$(grep -o 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\/ -f2)"
OTA_LIST="$(grep 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\" -f2)"

# Select and configure device
echo "- Selecting Pixel Beta device ..."
[ -z "$PRODUCT" ] && set_random_beta
echo "$MODEL ($PRODUCT)"

# Get device fingerprint and security patch from OTA metadata
# Using a more compatible approach than ulimit for file size limitation
echo "- Downloading OTA metadata for $PRODUCT..."
download "$(echo "$OTA_LIST" | grep "$PRODUCT")" PIXEL_ZIP_METADATA

# Extract required information
FINGERPRINT="$(strings PIXEL_ZIP_METADATA 2>/dev/null | grep -am1 'post-build=' | cut -d= -f2)"
SECURITY_PATCH="$(strings PIXEL_ZIP_METADATA 2>/dev/null | grep -am1 'security-patch-level=' | cut -d= -f2)"

# Validate required fields to prevent empty pif.json
if [ -z "$FINGERPRINT" ] || [ -z "$SECURITY_PATCH" ]; then
    # Try installing strings if not found
    if ! command -v strings > /dev/null 2>&1; then
        echo "- 'strings' command not found, attempting to use hexdump..."
        FINGERPRINT="$(hexdump -C PIXEL_ZIP_METADATA | grep -a 'post-build=' | head -1 | sed 's/.*post-build=//' | cut -d ';' -f1)"
        SECURITY_PATCH="$(hexdump -C PIXEL_ZIP_METADATA | grep -a 'security-patch-level=' | head -1 | sed 's/.*security-patch-level=//' | cut -d ';' -f1)"
    fi

    # If still empty, fail
    if [ -z "$FINGERPRINT" ] || [ -z "$SECURITY_PATCH" ]; then
        echo "[!] Failed to extract required information from metadata"
        download_fail "https://dl.google.com"
    fi
fi

echo "- Dumping values to pif.json ..."
# Create pif.json directly in current directory
cat <<EOF > "$CURRENT_DIR/pif.json"
{
  "FINGERPRINT": "$FINGERPRINT",
  "MANUFACTURER": "Google",
  "MODEL": "$MODEL",
  "SECURITY_PATCH": "$SECURITY_PATCH"
}
EOF

# No need to copy since we're writing directly to destination
echo "- new pif.json saved to $CURRENT_DIR/pif.json"

# Verify file exists
if [ -f "$CURRENT_DIR/pif.json" ]; then
    echo "- File created successfully!"
    cat "$CURRENT_DIR/pif.json"
else
    echo "- ERROR: Failed to create pif.json file!"
fi

echo "- Cleaning up ..."
# No need to manually remove, the trap will handle it

echo "- Done!"
