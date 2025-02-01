#!/bin/bash

# Check for required dependencies
missing_deps=""

check_dependency() {
  if ! command -v "$1" &> /dev/null; then
    missing_deps+="$1 "
  fi
}

check_dependency "wine"
check_dependency "winetricks"
check_dependency "wget"
check_dependency "curl"
check_dependency "7z" # Manjaro uses 7z instead of 7z
check_dependency "tar"

if [ -n "$missing_deps" ]; then
  echo "The following dependencies are missing: $missing_deps"
  echo "Please install them and rerun the script."
  exit 1
fi

echo "All dependencies are installed!"
sleep 2

directory="$HOME/.AffinityLinux"
repo="Twig6943/ElementalWarrior-Wine-binaries" #Owner/Repo
filename="ElementalWarriorWine.zip" #Filename

# Kill wine
wineserver -k

# Create install directory
mkdir -p "$directory"

# Fetch the latest release information from GitHub
release_info=$(curl -s "https://api.github.com/repos/$repo/releases/latest")
download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$filename\") | .browser_download_url")
[ -z "$download_url" ] && { echo "File not found in the latest release"; exit 1; }

# Download the specific release asset
wget -q "$download_url" -O "$directory/$filename" #Download wine binaries

# Check downloaded filesize matches repo
github_size=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$filename\") | .size")
local_size=$(wc -c < "$directory/$filename")

if [ "$github_size" -eq "$local_size" ]; then
    echo "File sizes match: $local_size bytes"
else
    echo "File sizes do not match: GitHub size: $github_size bytes, Local size: $local_size bytes"
    echo "Download $filename from $download_url, move it to $directory, and press any key to continue."
    read -n 1
fi

# Download necessary files
wget https://upload.wikimedia.org/wikipedia/commons/9/9c/Affinity_Publisher_V2_icon.svg -O "$HOME/.local/share/icons/AffinityPublisher.svg"
wget https://archive.org/download/win-metadata/WinMetadata.zip -O "$directory/WinMetadata.zip"

# Extract wine binary
unzip "$directory/$filename" -d "$directory"

# Remove the original downloaded file
rm "$directory/$filename"

# WINETRICKS setup
WINEPREFIX="$directory" winetricks --unattended dotnet35 dotnet48 corefonts vcrun2022 allfonts
WINEPREFIX="$directory" winetricks renderer=vulkan

# Extract & delete WinMetadata.zip
7z x "$directory/WinMetadata.zip" -o"$directory/drive_c/windows/system32"
rm "$directory/WinMetadata.zip"

# Prompt for user action
echo "Download the Affinity Publisher .exe from https://store.serif.com/account/licences/"
echo "Once downloaded, place the .exe in $directory and press any key when ready."
read -n 1

echo "Click No if you get any errors. Press any key to continue."
read -n 1

# Set Windows version to 11
WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/winecfg" -v win11
WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/wine" "$directory"/*.exe
rm "$directory"/affinity*.exe

# Apply Wine dark theme
wget https://raw.githubusercontent.com/Twig6943/AffinityOnLinux/main/wine-dark-theme.reg -O "$directory/wine-dark-theme.reg"
WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/regedit" "$directory/wine-dark-theme.reg"
rm "$directory/wine-dark-theme.reg"

# Remove Wine-generated desktop entry
rm -f "$HOME/.local/share/applications/wine/Programs/Affinity Publisher 2.desktop"

# Create Desktop Entry
cat << EOF > "$HOME/.local/share/applications/AffinityPublisher.desktop"
[Desktop Entry]
Name=Affinity Publisher
Comment=A professional desktop publishing software.
Icon=$HOME/.local/share/icons/AffinityPublisher.svg
Path=$directory
Exec=env WINEPREFIX=$directory $directory/ElementalWarriorWine/bin/wine "$directory/drive_c/Program Files/Affinity/Publisher 2/Publisher.exe"
Terminal=false
NoDisplay=false
StartupWMClass=publisher.exe
Type=Application
Categories=Graphics;
StartupNotify=true
EOF

# Copy shortcut to Desktop
cp "$HOME/.local/share/applications/AffinityPublisher.desktop" "$HOME/Desktop/AffinityPublisher.desktop"

# Set executable permissions for normal user
chmod +x "$HOME/.local/share/applications/AffinityPublisher.desktop"
chmod +x "$HOME/Desktop/AffinityPublisher.desktop"
chmod -R u+rw "$directory"

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

