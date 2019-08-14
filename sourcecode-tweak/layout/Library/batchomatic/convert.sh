#!/bin/bash

timestamp="`date +"%Y.%m.%d-%H.%M.%S"`"
versionNumber=`dpkg-query --showformat='${Version}\n' --show com.captinc.batchomatic`
rm -r /tmp/batchomatic
mkdir /tmp/batchomatic

mkdir /tmp/batchomatic/create
mkdir /tmp/batchomatic/create/DEBIAN
cp /Library/batchomatic/directions /tmp/batchomatic/create/DEBIAN/postinst
mkdir /tmp/batchomatic/create/var
mkdir /tmp/batchomatic/create/var/mobile
mkdir /tmp/batchomatic/create/var/mobile/BatchInstall
mkdir /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences
mkdir /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs

echo "Package: com.you.batchinstall" >> /tmp/batchomatic/create/DEBIAN/control
echo "Name: BatchInstall" >> /tmp/batchomatic/create/DEBIAN/control
echo "Version: $timestamp" >> /tmp/batchomatic/create/DEBIAN/control
echo "Author: You" >> /tmp/batchomatic/create/DEBIAN/control
echo "Maintainer: You" >> /tmp/batchomatic/create/DEBIAN/control
echo "Architecture: iphoneos-arm" >> /tmp/batchomatic/create/DEBIAN/control
echo "Section: Tweaks" >> /tmp/batchomatic/create/DEBIAN/control
echo "Description: Batch-install all of your tweaks for your setup! Created using Batchomatic v$versionNumber" >> /tmp/batchomatic/create/DEBIAN/control

apt-cache depends com.you.batchinstall | awk -F "Depends: " '/Depends: /{print $2}' > /tmp/batchomatic/alltweaks.txt
awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/ignoredtweaks.txt /tmp/batchomatic/alltweaks.txt > /tmp/batchomatic/tweaksUnformatted.txt
sed -i 's|[<>,]||g' /tmp/batchomatic/tweaksUnformatted.txt
printf %s "$(< /tmp/batchomatic/tweaksUnformatted.txt)" > /tmp/batchomatic/create/var/mobile/BatchInstall/tweaks.txt

cat /etc/apt/sources.list.d/cydia.list >> /tmp/batchomatic/reposRaw.txt || true
cat /etc/apt/cydiasources.d/cydia.list >> /tmp/batchomatic/reposRaw.txt || true
cat "/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list" >> /tmp/batchomatic/reposRaw.txt || true
cat /etc/apt/sources.list.d/*.sources >> /tmp/batchomatic/reposRaw.txt || true
ls "/var/mobile/Library/Application Support/Installer/SourcesFiles" | sed 's:_:/:g' | sed 's:\(.*\)-Packages:\1:' >> /tmp/batchomatic/reposFormatted.txt || true
egrep -o 'https?://[^ ]+' /tmp/batchomatic/reposRaw.txt >> /tmp/batchomatic/reposExtracted.txt
while read aLine; do
        case "$aLine" in
        */)
        echo $aLine >> /tmp/batchomatic/reposFormatted.txt
        ;;
        *)
        echo "$aLine/" >> /tmp/batchomatic/reposFormatted.txt
        ;;
    esac
done < /tmp/batchomatic/reposExtracted.txt
sed 's#https://repounclutter.coolstar.org/#http://apt.thebigboss.org/repofiles/cydia/#g' /tmp/batchomatic/reposFormatted.txt > /tmp/batchomatic/reposRepoUnclutterConverted.txt
sort -u /tmp/batchomatic/reposRepoUnclutterConverted.txt >> /tmp/batchomatic/reposSorted.txt
awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/ignoredrepos.txt /tmp/batchomatic/reposSorted.txt > /tmp/batchomatic/reposWithoutIgnores.txt
sort -u /tmp/batchomatic/reposWithoutIgnores.txt >> /tmp/batchomatic/reposReSorted.txt
printf %s "$(< /tmp/batchomatic/reposReSorted.txt)" > /tmp/batchomatic/create/var/mobile/BatchInstall/repos.txt

find /var/mobile/BatchInstall -type f -exec chmod 777 {} \;
find /var/mobile/BatchInstall -type d -exec chmod 777 {} \;
hostsFile=/var/mobile/BatchInstall/hosts
if test -f "$hostsFile"; then
    cp -r /var/mobile/BatchInstall/TweakPreferences/* /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences
    cp /var/mobile/BatchInstall/hosts /tmp/batchomatic/create/var/mobile/BatchInstall
    batchomaticd 2
else
    cp -r /var/mobile/BatchInstall/* /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences
    batchomaticd 1
    batchomaticd 2
fi

cp /var/mobile/BatchomaticDebs/UserSavedDebs/* /tmp/batchomatic/create/var/mobile/BatchInstall/SavedDebs

dpkg-deb -b /tmp/batchomatic/create /var/mobile/BatchomaticDebs/batchinstall-$timestamp.deb
rm -r /tmp/batchomatic
