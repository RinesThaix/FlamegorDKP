#Removing .DS_Store
find . -name '.DS_Store' -type f -delete

#Setting var to WoW directory
path=/Applications/World\ of\ Warcraft/_classic_/Interface/AddOns

#Removing WoW Addon directory
rm -rf "$path/FlamegorDKP"

#Creating and copying WoW Addon directory
mkdir "$path/FlamegorDKP"
cp -rf . "$path/FlamegorDKP/"

#Removing technical files
rm -rf "$path/FlamegorDKP/.git"
rm -f "$path/FlamegorDKP/copy.sh"

echo "Copied"