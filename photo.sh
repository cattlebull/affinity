#!/bin/bash

# Function to check dependencies and install missing ones
check_dependency() {
  if ! pacman -Q "$1" &>/dev/null; then
    missing_deps+="$1 "
  fi
}

# Check for required dependencies
missing_deps=""

check_dependency "wine"
check_dependency "winetricks"
check_dependency "wget"
check_dependency "curl"
check_dependency "p7zip"
check_dependency "unzip"
check_dependency "jq"

if [ -n "$missing_deps" ]; then
  echo "The following dependencies are missing: $missing_deps"
  echo "Installing missing dependencies..."
  sudo pacman -S --needed $missing_deps
fi

echo "All dependencies are installed!"
sleep 2

directory="$HOME/.AffinityLinux"
repo="Twig6943/ElementalWarrior-Wine-binaries" # GitHub Owner/Repo
filename="ElementalWarriorWine.zip" # Release Asset Filename

# Kill any running Wine processes
wineserver -k

# Create installation directory
mkdir -p "$directory"

# Fetch the latest release information from GitHub
release_info=$(curl -s "https://api.github.com/repos/$repo/releases/latest")
download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$filename\") | .browser_download_url")

if [ -z "$download_url" ]; then
  echo "Error: Could not find the specified file ($filename) in the latest release."
  exit 1
fi

# Download Wine binaries
wget -q "$download_url" -O "$directory/$filename"

# Verify the downloaded file size
github_size=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$filename\") | .size")
local_size=$(wc -c < "$directory/$filename")

if [ "$github_size" -eq "$local_size" ]; then
    echo "File sizes match: $local_size bytes"
else
    echo "File size mismatch: GitHub: $github_size bytes, Local: $local_size bytes"
    echo "Manually download the file from $download_url, place it in $directory, and press any key to continue."
    read -n 1
fi

# Download icons and metadata
wget -q https://upload.wikimedia.org/wikipedia/commons/f/f5/Affinity_Photo_V2_icon.svg -O "$HOME/.local/share/icons/AffinityPhoto.svg"
wget -q https://archive.org/download/win-metadata/WinMetadata.zip -O "$directory/WinMetadata.zip"

# Extract Wine binary
unzip "$directory/$filename" -d "$directory"
rm "$directory/$filename"

# Set up Wine
export WINEPREFIX="$directory"
winetricks --unattended dotnet35 dotnet48 corefonts vcrun2022 allfonts
winetricks renderer=vulkan

# Extract & delete WinMetadata
7z x "$directory/WinMetadata.zip" -o"$directory/drive_c/windows/system32"
rm "$directory/WinMetadata.zip"

# Prompt user to download Affinity Photo installer
echo "Download Affinity Photo .exe from https://store.serif.com/account/licences/"
echo "Place the .exe in $directory and press any key when ready."
read -n 1

echo "If any errors appear, click 'No'. Press any key to continue."
read -n 1

# Set Windows version to 11
"$directory/ElementalWarriorWine/bin/winecfg" -v win11

# Run Affinity Photo installer
"$directory/ElementalWarriorWine/bin/wine" "$directory"/*.exe
rm "$directory"/affinity*.exe

# Apply Wine dark theme
wget -q https://raw.githubusercontent.com/Twig6943/AffinityOnLinux/main/wine-dark-theme.reg -O "$directory/wine-dark-theme.reg"
"$directory/ElementalWarriorWine/bin/regedit" "$directory/wine-dark-theme.reg"
rm "$directory/wine-dark-theme.reg"

# Remove unwanted Wine desktop entry
rm -f "$HOME/.local/share/applications/wine/Programs/Affinity Photo 2.desktop"

# Create a proper GNOME desktop entry
desktop_file="$HOME/.local/share/applications/AffinityPhoto.desktop"
echo "[Desktop Entry]" > "$desktop_file"
echo "Name=Affinity Photo" >> "$desktop_file"
echo "Comment=A powerful image editing software." >> "$desktop_file"
echo "Icon=$HOME/.local/share/icons/AffinityPhoto.svg" >> "$desktop_file"
echo "Path=$directory" >> "$desktop_file"
echo "Exec=env WINEPREFIX=$directory $directory/ElementalWarriorWine/bin/wine \"$directory/drive_c/Program Files/Affinity/Photo 2/Photo.exe\"" >> "$desktop_file"
echo "Terminal=false" >> "$desktop_file"
echo "NoDisplay=false" >> "$desktop_file"
echo "StartupWMClass=photo.exe" >> "$desktop_file"
echo "Type=Application" >> "$desktop_file"
echo "Categories=Graphics;" >> "$desktop_file"
echo "StartupNotify=true" >> "$desktop_file"

# Copy shortcut to desktop (Manjaro GNOME might require permissions change)
cp "$desktop_file" "$HOME/Desktop/AffinityPhoto.desktop"
chmod +x "$HOME/Desktop/AffinityPhoto.desktop"

# Display Special Thanks
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
