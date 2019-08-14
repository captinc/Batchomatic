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
mkdir /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs

echo "Package: com.you.batchinstall" >> /tmp/batchomatic/create/DEBIAN/control
echo "Name: BatchInstall - Offline" >> /tmp/batchomatic/create/DEBIAN/control
echo "Version: $timestamp" >> /tmp/batchomatic/create/DEBIAN/control
echo "Author: You" >> /tmp/batchomatic/create/DEBIAN/control
echo "Maintainer: You" >> /tmp/batchomatic/create/DEBIAN/control
echo "Architecture: iphoneos-arm" >> /tmp/batchomatic/create/DEBIAN/control
echo "Section: Tweaks" >> /tmp/batchomatic/create/DEBIAN/control
echo "Description: Batch-install the .debs of your tweaks, offline! Created using Batchomatic v$versionNumber" >> /tmp/batchomatic/create/DEBIAN/control

cp -R `ls -d /var/mobile/Library/Preferences/* | grep -v 'com.apple'` /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences
rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/.Global*
rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.google*
rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/group.com.apple*
rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/com.saurik.Cydia.plist
rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/nfcd.plist
rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/TVRemoteConnectionService.plist
rm /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences/UITextInputContextIdentifiers.plist
find /tmp/batchomatic/create/var/mobile/BatchInstall/Preferences -maxdepth 1 -name "*groups.com.apple*" -delete

batchomaticd 1
batchomaticd 2

dpkg -l | awk '/^[hi]i/{print $2}' > /tmp/batchomatic/alltweaks.txt
awk 'NR==FNR{a[$0];next} !($0 in a)' /Library/batchomatic/ignoredtweaks.txt /tmp/batchomatic/alltweaks.txt > /tmp/batchomatic/thinnedtweaks.txt
sed '/^gsc./ d' /tmp/batchomatic/thinnedtweaks.txt > /tmp/batchomatic/tweaksWithNewline.txt
printf %s "$(< /tmp/batchomatic/tweaksWithNewline.txt)" > /tmp/batchomatic/tweaks.txt

mkdir /tmp/batchomatic/builddeb

echo $timestamp >> /tmp/batchomatic/timestampWithNewline.txt
printf %s "$(< /tmp/batchomatic/timestampWithNewline.txt)" > /tmp/batchomatic/timestamp.txt
