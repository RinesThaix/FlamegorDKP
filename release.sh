#Removing .DS_Store
find . -name '.DS_Store' -type f -delete

#Setting var to releases directory
path=../FlamegorDKP_Releases

#Preparing (clearing and copypasting) releases directory
rm -rf "$path"
mkdir "$path" && mkdir "$path/FlamegorDKP"
cp -r . "$path/FlamegorDKP/"

#Removing technical files
rm -f "$path/FlamegorDKP/copy.sh"
rm -f "$path/FlamegorDKP/release.sh"

#Creating officers version
cd "$path" && zip -r "$path/FlamegorDKP.zip" FlamegorDKP && cd -

echo "Released"