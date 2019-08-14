#!/bin/bash

eachTweak=$1
mkdir /tmp/batchomatic/builddeb/DEBIAN

dpkg-query -s $eachTweak | grep -v Status >> /tmp/batchomatic/builddeb/DEBIAN/control

debianScripts=`ls /Library/dpkg/info | grep $eachTweak | grep -v ".list" | grep -v ".md5sums"`
for eachScript in $debianScripts
do
cp -p /Library/dpkg/info/$eachScript /tmp/batchomatic/builddeb/DEBIAN
normalNameOfScript=`ls /tmp/batchomatic/builddeb/DEBIAN | grep $eachScript | awk '{print $NF}' FS=.`
mv /tmp/batchomatic/builddeb/DEBIAN/$eachScript /tmp/batchomatic/builddeb/DEBIAN/$normalNameOfScript
done

firstLineOfOutput=`dpkg-query -L $eachTweak | head -n 1`
if [ $firstLineOfOutput == "/." ]
then
filesToCopy=`dpkg-query -L $eachTweak | tail -n +2`
else
filesToCopy=`dpkg-query -L $eachTweak`
fi

for aFile in $filesToCopy
do
if [ -d "$aFile" ]
then
mkdir -p "/tmp/batchomatic/builddeb$aFile"
elif [ -f "$aFile" ]
then
cp -p $aFile "/tmp/batchomatic/builddeb$aFile"
fi
done

dpkg-deb -b /tmp/batchomatic/builddeb /tmp/batchomatic/create/var/mobile/BatchInstall/OfflineDebs
rm -r /tmp/batchomatic/builddeb/*
