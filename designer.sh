#!/bin/bash

# Enable error handling
set -e

# Check for required dependencies
missing_deps=""

check_dependency() {
  if ! command -v "$1" &> /dev/null; then
    missing_deps+="$1 "
  fi
}

# Check dependencies
check_dependency "wine"
check_dependency "winetricks"
check_dependency "wget"
check_dependency "curl"
check_dependency "7z"
check_dependency "jq"
check_dependency "unzip"

if [ -n "$missing_deps" ]; then
  echo "The following dependencies are missing: $missing_deps"
  echo "Please install them and rerun the script."
  exit 1
fi

echo "All dependencies are installed!"
sleep 2

directory="$HOME/.AffinityLinux"
repo="Twig6943/ElementalWarrior-Wine-binaries" # Owner/Repo
filename="ElementalWarriorWine.zip" # Filename

# Kill wine processes
wineserver -k || echo "Wine server not running"

# Create install directory
mkdir -p "$directory"

# Fetch the latest release information from GitHub
release_info=$(curl -s "https://api.github.com/repos/$repo/releases/latest")
download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$filename\") | .browser_download_url")
[ -z "$download_url" ] && { echo "File not found in the latest release"; exit 1; }

# Check if the download URL is valid
if ! curl --head --silent --fail "$download_url" > /dev/null; then
  echo "Download URL is not valid: $download_url"
  exit 1
fi

# Download the specific release asset
wget -q "$download_url" -O "$directory/$filename" || { echo "Failed to download $filename"; exit 1; }

# Check downloaded filesize matches repo
github_size=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$filename\") | .size")
local_size=$(wc -c < "$directory/$filename")

if [ "$github_size" -eq "$local_size" ]; then
    echo "File sizes match: $local_size bytes"
else
    echo "File sizes do not match: GitHub size: $github_size bytes, Local size: $local_size bytes"
    echo "Download $filename manually from $download_url and press any key to continue"
    read -n 1
fi

# Download Affinity Designer icon
if ! curl --head --silent --fail "https://upload.wikimedia.org/wikipedia/commons/3/3c/Affinity_Designer_2-logo.svg" > /dev/null; then
  echo "Affinity Designer icon URL is not valid."
  exit 1
fi
wget https://upload.wikimedia.org/wikipedia/commons/3/3c/Affinity_Designer_2-logo.svg -O "/home/$USER/.local/share/icons/AffinityDesigner.svg" || { echo "Failed to download Affinity Designer icon"; exit 1; }

# Download WinMetadata.zip
if ! curl --head --silent --fail "https://archive.org/download/win-metadata/WinMetadata.zip" > /dev/null; then
  echo "WinMetadata.zip URL is not valid."
  exit 1
fi
wget https://archive.org/download/win-metadata/WinMetadata.zip -O "$directory/Winmetadata.zip" || { echo "Failed to download WinMetadata.zip"; exit 1; }

# Extract wine binary
unzip "$directory/$filename" -d "$directory" || { echo "Failed to unzip $filename"; exit 1; }

# Remove the zip file after extraction
rm "$directory/$filename"

# WINETRICKS setup
WINEPREFIX="$directory" winetricks --unattended dotnet35 dotnet48 corefonts vcrun2022 allfonts || { echo "Winetricks setup failed"; exit 1; }
WINEPREFIX="$directory" winetricks renderer=vulkan || { echo "Failed to install Vulkan renderer"; exit 1; }

# Extract WinMetadata
mkdir -p "$directory/drive_c/windows/system32"
7z x "$directory/Winmetadata.zip" -o"$directory/drive_c/windows/system32" || { echo "Failed to extract WinMetadata.zip"; exit 1; }
rm "$directory/Winmetadata.zip"

# Prompt user to download Affinity Designer .exe
echo "Download the Affinity Designer .exe from https://store.serif.com/account/licences/"
echo "Once downloaded, place the .exe in $directory and press any key when ready."
read -n 1

# Set Windows version to 11
WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/winecfg" -v win11 || { echo "Failed to set Windows version to 11"; exit 1; }

# Run Affinity Designer setup
WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/wine" "$directory"/*.exe || { echo "Failed to run Affinity Designer setup"; exit 1; }
rm "$directory/affinity*.exe" || echo "No Affinity Designer setup executable found to remove."

# Apply wine dark theme
wget https://raw.githubusercontent.com/Twig6943/AffinityOnLinux/main/wine-dark-theme.reg -O "$directory/wine-dark-theme.reg" || { echo "Failed to download wine-dark-theme.reg"; exit 1; }
WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/regedit" "$directory/wine-dark-theme.reg" || { echo "Failed to apply wine dark theme"; exit 1; }
rm "$directory/wine-dark-theme.reg"

# Remove Desktop entry created by wine
rm "/home/$USER/.local/share/applications/wine/Programs/Affinity Designer 2.desktop" || echo "No existing Wine desktop entry to remove"

# Create custom Desktop Entry for Affinity Designer
echo "[Desktop Entry]" > ~/.local/share/applications/AffinityDesigner.desktop
echo "Name=Affinity Designer" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "Comment=Affinity Designer is a graphic design and UX solution." >> ~/.local/share/applications/AffinityDesigner.desktop
echo "Icon=/home/$USER/.local/share/icons/AffinityDesigner.svg" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "Path=$directory" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "Exec=env WINEPREFIX=$directory $directory/ElementalWarriorWine/bin/wine \"$directory/drive_c/Program Files/Affinity/Designer 2/Designer.exe\"" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "Terminal=false" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "NoDisplay=false" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "StartupWMClass=designer.exe" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "Type=Application" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "Categories=Graphics;" >> ~/.local/share/applications/AffinityDesigner.desktop
echo "StartupNotify=true" >> ~/.local/share/applications/AffinityDesigner.desktop

# Copy desktop entry to user Desktop
cp "$HOME/.local/share/applications/AffinityDesigner.desktop" "$HOME/Desktop/AffinityDesigner.desktop"

# Special Thanks section
echo "******************************"
echo "    Special Thanks"
echo "******************************"
echo "Ardishco (github.com/raidenovich)"
echo "Deviaze"
echo "Kemal"
echo "Jacazimbo <3"
echo "Kharoon"
echo "Jediclank134"
read -n 1
