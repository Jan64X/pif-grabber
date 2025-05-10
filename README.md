# pif-grabber

Automatically fetches valid Play Integrity Fingerprints using Google Pixel Beta/Developer Preview device information and outputs it as a JSON file in the local directory.

## Overview

pif-grabber is a Linux tool that retrieves valid device fingerprints that can be used with Play Integrity spoofing solutions. It works by fetching metadata from Google's official Pixel Beta/Developer Preview OTA updates, extracting the device fingerprint and security patch information, and formatting it into a compatible JSON structure.

This is a modified version of the PlayIntegrityFix action.sh script, adapted to work on any Linux PC instead of running as a Magisk module.

## Features

- Works on any Linux distribution
- Automatically selects a random Google Pixel device
- Retrieves the latest fingerprint information from Google's servers
- Creates a properly formatted pif.json file
- No Android device or root access required

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Jan64X/pif-grabber.git
   cd pif-grabber
   ```

2. Make the script executable:
   ```bash
   chmod +x pif_get.sh
   ```

## Usage

Simply run the script:

```bash
./pif_get.sh
```

The script will:
1. Download the latest Pixel device information from Google's developer website
2. Select a random Pixel device if none is specified
3. Extract the device fingerprint and security patch level
4. Create a pif.json file in the current directory

Example output:
```json
{
  "FINGERPRINT": "google/oriole_beta/oriole:16/BP22.250325.007/13352765:user/release-keys",
  "MANUFACTURER": "Google",
  "MODEL": "Pixel 6",
  "SECURITY_PATCH": "2025-04-05"
}
```

## Requirements

- bash
- curl or wget
- Basic Linux utilities (grep, sed, etc.)
- Internet connection

## How It Works

The script works by:
1. Scraping Google's Android developer site for the latest Pixel Beta or Developer Preview information
2. Finding the OTA update links for Pixel devices
3. Downloading and extracting metadata from these OTA updates
4. Parsing the metadata to get the fingerprint and security patch information
5. Generating a pif.json file with the necessary information

## Use Cases

- For placing into your ROM's fingerprint spoof menu, crDroid should have a menu in Misc that allows you to put in a fingerprint file manually starting from android 15.
- For placing into a ROM at build time to spoof a device after installation.

## Credits

This tool is based on the [PlayIntegrityFix](https://github.com/chiteroman/PlayIntegrityFix) by chiteroman. Special thanks to them for the original action.sh script that made this tool possible.

## License

This project is licensed under the GPL-3.0 License - see the LICENSE file for details.

## Disclaimer

This tool is provided for educational and research purposes only. Using device fingerprints for spoofing may violate terms of service of some applications. Use responsibly and at your own risk.
